import Foundation
import CoreBluetooth

@objc open class HendricksPaymentDeviceConnector: NSObject {
    private var centralManager: CBCentralManager!
    private var wearablePeripheral: CBPeripheral?
    private var _deviceInfo: Device?
    private var paymentDevice: PaymentDevice?

    private let genericServiceId = CBUUID(string: "00001800-0000-1000-8000-00805f9b34fb")
    private let deviceServiceId = CBUUID(string: "7DB2E9EA-ADF6-4F18-A110-61055D64B287")
    
    // in generic service
    private let deviceNameCharacteristicId = CBUUID(string: "00002a00-0000-1000-8000-00805f9b34fb")
    private let appearanceCharacteristicId = CBUUID(string: "00002a01-0000-1000-8000-00805f9b34fb")
    private let preferredParametersCharacteristicId = CBUUID(string: "00002a04-0000-1000-8000-00805f9b34fb")
    private let centralAddressCharacteristicId = CBUUID(string: "00002aa6-0000-1000-8000-00805f9b34fb")
    
    // in device service
    private let statusCharacteristicId = CBUUID(string: "7DB2134A-ADF6-4F18-A110-61055D64B287")
    private let commandCharacteristicId = CBUUID(string: "7DB20256-ADF6-4F18-A110-61055D64B287")
    private let dataCharacteristicId = CBUUID(string: "7DB2E528-ADF6-4F18-A110-61055D64B287")
    private let eventCharacteristicId = CBUUID(string: "7DB2AE05-ADF6-4F18-A110-61055D64B287")
    
    private var expectedDataSize = 0
    private var returnedData: [UInt8] = []
    private var currentCommand: BLECommandPackage?
    private var commandQueue: [BLECommandPackage] = []
    
    private var apduCompletion: ((Error?) -> Void)?
    private var apduCommands: [APDUCommand]?
    
    private var timer: Timer?
    
    // MARK: - Lifecycle
    
    @objc public init(paymentDevice: PaymentDevice) {
        self.paymentDevice = paymentDevice
        super.init()
    }
    
    // MARK: - Public Functions
    
    public func addCommandtoQueue(_ bleCommand: BLECommandPackage) {
        commandQueue.enqueue(bleCommand)
        processNextCommand()
    }
    
    public func addCreditCard(_ creditCard: CreditCard) {
        
        processCreditCardImage(creditCard) { (cardArtData) in
            
            // data
            let lastFour = creditCard.info?.pan?.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            guard let lastFourData = lastFour?.data(using: .utf8)?.paddedTo(byteLength: 5) else { return }
            
            let exp = String(format: "%02d", creditCard.info!.expMonth!) + "/" + String(creditCard.info!.expYear!).dropFirst(2)
            guard let expData = exp.data(using: .utf8)?.paddedTo(byteLength: 6) else { return }
            
            guard let financialServiceData =  creditCard.cardType!.data(using: .utf8)?.paddedTo(byteLength: 21) else { return }
            guard let cardIdData = creditCard.creditCardId?.data(using: .utf8)?.paddedTo(byteLength: 37) else { return }
            
            var cardArtId = 0
            let cardArtIdData = Data(bytes: &cardArtId, count: 2)
            
            var towId = 0
            let towIdData = Data(bytes: &towId, count: 2)
            
            // card status
            let cardStatusData = UInt8(0x07).data // TODO: map correct card status
            
            let towApduData = creditCard.topOfWalletAPDUCommands != nil ? self.buildAPDUData(apdus: creditCard.topOfWalletAPDUCommands!) : Data()
            var towSize = towApduData.count
            let towSizeData = Data(bytes: &towSize, count: 4)
            
            var cardArtSize = cardArtData.count
            let cardArtSizeData = Data(bytes: &cardArtSize, count: 4)
            
            //split for compiler
            let dataFirstHalf = lastFourData + expData + financialServiceData + cardIdData + cardArtIdData
            let dataSecondHalf = cardArtSizeData + towIdData + towSizeData + cardStatusData + cardArtData + towApduData
            let data = dataFirstHalf + dataSecondHalf
            
            // command data
            var metaSize = 82
            let metaSizeData = Data(bytes: &metaSize, count: 4)
            
            let commandData = cardIdData + metaSizeData + cardArtSizeData + towSizeData
            
            let bleCommand = BLECommandPackage(.addCard, commandData: commandData, data: data)
            self.addCommandtoQueue(bleCommand)
            
        }
    }
    
    // MARK: - Private Functions
    
    private func addCommandtoFrontOfQueue(_ bleCommand: BLECommandPackage) {
        commandQueue.insert(bleCommand, at: 0)
        processNextCommand()
    }
    
    private func runCommand() {
        guard currentCommand == nil else {
            log.error("HENDRICKS: Cannot run command while one is already running")
            return
        }
        
        currentCommand = commandQueue.dequeue()
        
        guard let command = currentCommand else {
            log.debug("HENDRICKS: commandQueue is empty")
            return
        }
        
        guard let wearablePeripheral = wearablePeripheral else { return }
        guard let deviceService = wearablePeripheral.services?.first(where: { $0.uuid == deviceServiceId }) else { return }
        
        guard let statusCharacteristic = deviceService.characteristics?.first(where: { $0.uuid == statusCharacteristicId }) else { return }
        guard let commandCharacteristic = deviceService.characteristics?.first(where: { $0.uuid == commandCharacteristicId }) else { return }
        guard let dataCharacteristic = deviceService.characteristics?.first(where: { $0.uuid == dataCharacteristicId }) else { return }
        
        log.debug("HENDRICKS: Running command: \(command.command.rawValue)")
        
        if command.command == .factoryReset {
            wearablePeripheral.writeValue(StatusCommand.abort.rawValue.data, for: statusCharacteristic, type: .withResponse)
        }

        // start
        wearablePeripheral.writeValue(StatusCommand.start.rawValue.data, for: statusCharacteristic, type: .withResponse)
        
        // add data
        var fullCommandData = command.command.rawValue.data
        if let commandData = command.commandData {
            fullCommandData += commandData
        }
        
        log.debug("HENDRICKS: Running full command: \(fullCommandData.hex)")
        wearablePeripheral.writeValue(fullCommandData, for: commandCharacteristic, type: .withResponse)
        
        if let data = command.data {
            let maxLength = 182
            var startIndex = 0
            while startIndex < data.count {
                let end = min(startIndex + maxLength, data.count)
                let parsedData = data[startIndex ..< end]
                log.verbose("HENDRICKS: putting parsed data: \(parsedData.hex) + \(parsedData.count)")
                wearablePeripheral.writeValue(parsedData, for: dataCharacteristic, type: .withResponse)
                startIndex += maxLength
            }
        }
        
        // end
        wearablePeripheral.writeValue(StatusCommand.end.rawValue.data, for: statusCharacteristic, type: .withResponse)
        
        timer = Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(HendricksPaymentDeviceConnector.handleBleIssue), userInfo: nil, repeats: false)
        
    }
    
    @objc private func handleBleIssue() {
        log.warning("HENDRICKS: Reseting due to no response or invalid response status")
        
        resetVariableState()
        resetToDefaultState()
    }
    
    private func handlePingResponse() {
        var index = 0
        let device = deviceInfo() ?? Device()
        
        device.deviceName = "Hendricks"
        device.osName = "Hendricks OS"
        device.deviceType = "WATCH"
        device.manufacturerName = "Fitpay"

        while index < expectedDataSize {
            guard returnedData[index] == 0x24 else { return }
            guard let type = PingResponse(rawValue: returnedData[index + 1]) else { return }
            
            let length = Int(returnedData[index + 2])
            let nextIndex = index + 3 + length
            let hex = Data(bytes: Array(returnedData[index + 3 ..< nextIndex])).hex
            
            switch type {
            case .serial:
                device.serialNumber = hex
            case .version:
                var version = "v"
                for i in index + 3 ..< nextIndex {
                    version += String(returnedData[i]) + "."
                }
                device.firmwareRevision = String(version.dropLast())
            case .deviceMode:
                guard returnedData[index + 3 ..< nextIndex] == [0x02] else { return }
                
            case .bootVersion:
                device.hardwareRevision = hex
                
            case .bleMac:
                device.bdAddress = hex
                
            default:
                break
            }
            
            index = nextIndex
        }
        
        self._deviceInfo = device
        paymentDevice?.callCompletionForEvent(PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected)
    }
    
    private func handleAPDUResponse() {
        var index = 0
        while index < expectedDataSize {
            let groupId = returnedData[index]
            let sequence = returnedData[index + 1] + returnedData[index + 2] << 8 // shift second bit
            let length = Int(returnedData[index + 4])
            let apduBytes = returnedData[index + 5 ..< index + length + 5]
            index += 5 + length
            
            let packet = ApduResultMessage(responseData: Data(bytes: apduBytes))
            
            // update responseData on the appropriate apduCommand
            apduCommands?.first(where: { $0.groupId == groupId && $0.sequence == sequence })?.responseData = packet.responseData
        }
        
        apduCompletion?(nil)
        apduCompletion = nil
        apduCommands = nil
    }
    
    private func resetVariableState() {
        expectedDataSize = 0
        returnedData = []
        currentCommand = nil
        timer?.invalidate()
        timer = nil
        
        processNextCommand()
    }
    
    private func processNextCommand() {
        if currentCommand == nil {
            runCommand()
        }
    }
    
    private func buildAPDUData(apdus: [APDUCommand]) -> Data {
        var data = Data()
        
        for apdu in apdus {
            guard let command = apdu.command else { continue }
            guard let commandData = command.hexToData() else { continue }

            let continueInt: UInt8 = apdu.continueOnFailure ? 0x01 : 0x00
            
            let groupIdData = UInt8(apdu.groupId).data
            let sequenceData = UInt16(apdu.sequence).data
            let continueData = continueInt.data
            let lengthData = UInt8(command.count / 2).data
            
            let fullCommandData = groupIdData + sequenceData + continueData + lengthData + commandData

            data.append(fullCommandData)
        }
        
        return data
    }
    
    private func processCreditCardImage(_ creditCard: FitpaySDK.CreditCard, completion: @escaping (_ data: Data) -> Void) {
        let defaultCardWidth = 200
        let defaultCardHeight = 125
        let cardImage = creditCard.cardMetaData?.cardBackgroundCombined?.first
        
        cardImage?.retrieveAssetWith(options: [ImageAssetOption.width(defaultCardWidth), ImageAssetOption.height(defaultCardHeight)]) { (asset, _) in
            guard let image = asset?.image else {
                completion(Data())
                return
            }
            let pixelData = image.pixelData()!
            
            // determine if there is tranparency
            var transparency = false
            
            for i in stride(from: 0, to: pixelData.count, by: 4) {
                let a = pixelData[i + 3]
                if a < 255 {
                    transparency = true
                    break
                }
            }
            
            // create main data
            var previousColor: (color: UInt16, alpha: UInt16)?
            var mainData = Data()
            var pixelCounter: UInt16 = 0
            let maxPixelCount = transparency ? 15 : 255
            
            for i in stride(from: 0, to: pixelData.count, by: 4) {
                let r = UInt16(pixelData[i])
                let g = UInt16(pixelData[i + 1])
                let b = UInt16(pixelData[i + 2])
                let a = UInt16(pixelData[i + 3])
                
                let red =   ((31 * (r + 4)) / 255)
                let green = ((63 * (g + 2)) / 255)
                let blue =  ((31 * (b + 4)) / 255)
                let alpha = (((15 * (a + 8)) / 255) & 0x0F)
                
                var color: UInt16 = (red << 11) | (green << 5) | blue
                
                if i == 0 { // handle first case differently
                    previousColor = (color: color, alpha: alpha)
                } else {
                    pixelCounter += 1
                }
                
                if alpha == 0 { // if fully transparent wipe color
                    color = 0
                }
                
                let lastPixel = i + 4 == pixelData.count
                
                if (color: color, alpha: alpha) != previousColor! || pixelCounter >= maxPixelCount || lastPixel {
                    if !lastPixel {
                        pixelCounter -= 1
                    }
                    
                    if transparency {
                        let pixelPlusAlpha: UInt8 = (UInt8(pixelCounter) << 4) | (UInt8(previousColor!.alpha))
                        mainData += pixelPlusAlpha.data + previousColor!.color.data
                        
                    } else {
                        mainData += pixelCounter.data + previousColor!.color.data
                    }
                    
                    pixelCounter = 0
                }
                
                previousColor = (color: color, alpha: alpha)
                
            }
            
            // header
            let imageVersion: UInt8 = 0x41
            let imageMode: UInt8 = transparency ? 0x01 : 0x00
            var width = Int(image.size.width)
            let widthData = Data(bytes: &width, count: 2)
            var height = Int(image.size.height)
            let heightData = Data(bytes: &height, count: 2)
            
            var mainDataSize = mainData.count
            let mainDataSizeData = Data(bytes: &mainDataSize, count: 2)
            
            let imageHeader = imageVersion.data + imageMode.data + widthData + heightData + mainDataSizeData
            
            completion(imageHeader + mainData)
        }
    }
    
}

@objc extension HendricksPaymentDeviceConnector: PaymentDeviceConnectable {

    public func connect() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func isConnected() -> Bool {
        return wearablePeripheral?.state == CBPeripheralState.connected
    }
    
    public func validateConnection(completion: @escaping (Bool, NSError?) -> Void) {
        completion(isConnected(), nil)
    }
    
    public func executeAPDUPackage(_ apduPackage: ApduPackage, completion: @escaping (Error?) -> Void) {
        log.debug("HENDRICKS: executeAPDUPackage started")
        guard let apdus = apduPackage.apduCommands else { return }
        
        apduCompletion = completion
        apduCommands = apduPackage.apduCommands
        
        let data = buildAPDUData(apdus: apdus)
        
        var apdusCount = apdus.count
        var dataCount = data.count
        
        let apduCountData = Data(bytes: &apdusCount, count: 2)
        let apduLengthData = Data(bytes: &dataCount, count: 4)

        let commandData = apduCountData + apduLengthData

        let bleCommand = BLECommandPackage(.apduPackage, commandData: commandData, data: data)

        addCommandtoQueue(bleCommand)
    }
    
    public func executeAPDUCommand(_ apduCommand: APDUCommand) {
        log.error("HENDRICKS: Not implemented. using packages instead")
    }
    
    public func deviceInfo() -> Device? {
        return _deviceInfo
    }
    
    public func resetToDefaultState() {
        addCommandtoFrontOfQueue(BLECommandPackage(.factoryReset))
    }
    
}

@objc extension HendricksPaymentDeviceConnector: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            log.debug("HENDRICKS: central.state is .unknown")
        case .resetting:
            log.debug("HENDRICKS: central.state is .resetting")
        case .unsupported:
            log.debug("HENDRICKS: central.state is .unsupported")
        case .unauthorized:
            log.debug("HENDRICKS: central.state is .unauthorized")
        case .poweredOff:
            log.debug("HENDRICKS: central.state is .poweredOff")
        case .poweredOn:
            log.debug("HENDRICKS: central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [deviceServiceId], options: nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        log.verbose("HENDRICKS: didDiscover peripheral: \(peripheral)")
        
        wearablePeripheral = peripheral
        wearablePeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.debug("HENDRICKS: Connected")
        wearablePeripheral?.discoverServices([deviceServiceId])
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.warning("HENDRICKS: Failed to Connect")
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.debug("HENDRICKS: didDisconnect")
    }
}

@objc extension HendricksPaymentDeviceConnector: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        guard let deviceService = services.filter({ $0.uuid == deviceServiceId }).first else { return }
        
        peripheral.discoverCharacteristics(nil, for: deviceService)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let statusCharacteristic = service.characteristics?.filter({ $0.uuid == statusCharacteristicId }).first else { return }
        guard let dataCharacteristic = service.characteristics?.filter({ $0.uuid == dataCharacteristicId }).first else { return }

        wearablePeripheral?.writeValue(StatusCommand.abort.rawValue.data, for: statusCharacteristic, type: .withResponse)
        
        peripheral.setNotifyValue(true, for: statusCharacteristic)
        peripheral.setNotifyValue(true, for: dataCharacteristic)

        addCommandtoQueue(BLECommandPackage(.ping))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value: [UInt8] = characteristic.value!.bytesArray
        
        switch characteristic.uuid {
            
        case statusCharacteristicId:
            let status = Data(bytes: Array([value[0]]))
            guard status == BLEResponses.ok.rawValue.data else {
                log.error("HENDRICKS: BLE Response Status not OK")
                handleBleIssue()
                return
            }
            
            if value.count == 1 { //status
                log.debug("HENDRICKS: BLE Response OK with no length")
                resetVariableState()
                
            } else if value.count == 5 { //length
                log.debug("HENDRICKS: BLE Response OK with length")
                let lengthData = Data(bytes: Array(value[1...4])).hex
                expectedDataSize = Int(UInt32(lengthData, radix: 16)!.bigEndian)
                
            } else {
                
            }
            
        case dataCharacteristicId:
            returnedData.append(contentsOf: value)

            if returnedData.count == expectedDataSize {
                let hexData = Data(bytes: returnedData).hex
                log.verbose("HENDRICKS: all data received \(hexData)")
                
                if currentCommand?.command == .ping {
                   handlePingResponse()
                } else if currentCommand?.command == .apduPackage {
                    handleAPDUResponse()
                } else if currentCommand?.command == .addCard {
                    //handle add card response
                }
                
                resetVariableState()
            }

        default:
            log.warning("HENDRICKS: Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }

}

// MARK: - Nested Data

extension HendricksPaymentDeviceConnector {
    
    public enum Command: UInt8 {
        case ping           = 0x01
        case restart        = 0x02
        case bootLoader     = 0x03
        case setDeviceId    = 0x05
        case unsetDeviceId  = 0x06
        case factoryReset   = 0x07
        case sleep          = 0x08
        case lock           = 0x09
        case unlock         = 0x0A
        case heartbeat      = 0x0B

        case assignUser     = 0x10
        case unassignUser   = 0x11
        case getUser        = 0x12
        case addCard        = 0x13
        case addCardCont    = 0x14
        case deleteCard     = 0x15
        case activateCard   = 0x16
        case getCardInfo    = 0x17
        case deactivateCard = 0x18
        case reactivateCard = 0x19
        
        case apduPackage    = 0x20 // + 0xXX - apdu count
    }
    
    enum StatusCommand: UInt8 {
        case start  = 0x01
        case end    = 0x02
        case abort  = 0x03
    }
    
    enum PingResponse: UInt8 {
        case serial             = 0x00
        case version            = 0x01
        case deviceId           = 0x02
        case deviceMode         = 0x03
        case bootVersion        = 0x04
        
        case ack                = 0x06
        
        case bootloaderVersion  = 0x17
        case appVersion         = 0x18
        case d21BlVersion       = 0x19
        case hardwareVersion    = 0x1A
        case bleMac             = 0x1B
    }
    
    enum BLEResponses: UInt8 {
        case ok     = 0x01
        case error  = 0x02
    }
    
    public struct BLECommandPackage {
        var command: Command
        var commandData: Data?
        var data: Data?
        
        public init(_ command: Command, commandData: Data? = nil, data: Data? = nil) {
            self.command = command
            self.commandData = commandData
            self.data = data
        }
        
    }

}
