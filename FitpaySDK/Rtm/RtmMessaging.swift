//
//  RtmMessaging.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 18.07.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import Foundation
import ObjectMapper

protocol RtmOutputDelegate: class {
    func send(rtmMessage: RtmMessageResponse, retries: Int)
    func show(status: WVDeviceStatuses, message: String?, error: Error?)
}

class RtmMessaging {
    weak var outputDelagate: RtmOutputDelegate?
    weak var rtmDelegate: WvRTMDelegate?
    weak var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate?
    weak var cardScannerDataSource: FitpayCardScannerDataSource?
    
    private(set) var messageHandler: RtmMessageHandler?

    lazy var handlersMapping: [RtmProtocolVersion: RtmMessageHandler?] = {
        return [RtmProtocolVersion.ver1: nil,
                RtmProtocolVersion.ver2: RtmMessageHandlerV2(wvConfigStorage: self.wvConfigStorage),
                RtmProtocolVersion.ver3: RtmMessageHandlerV3(wvConfigStorage: self.wvConfigStorage),
                RtmProtocolVersion.ver4: RtmMessageHandlerV4(wvConfigStorage: self.wvConfigStorage)]
    }()
    
    init(wvConfigStorage: WvConfigStorage) {
        self.wvConfigStorage = wvConfigStorage
        self.preVersionBuffer = []
    }
    
    typealias RtmRawMessage = [String: Any]
    typealias RtmRawMessageCompletion = ((_ success:Bool)->Void)
    
    func received(message: RtmRawMessage, completion: RtmRawMessageCompletion? = nil) {
        let jsonData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
        
        guard let rtmMessage = Mapper<RtmMessage>().map(JSONString: String(data: jsonData!, encoding: .utf8)!) else {
            log.error("WV_DATA: Can't create RtmMessage.")
            completion?(false)
            return
        }
        
        defer {
            if let delegate = self.rtmDelegate {
                delegate.onWvMessageReceived?(message: rtmMessage)
            }
        }
        
        guard self.messageHandler == nil else {
            self.messageHandler?.handle(message: message)
            completion?(true)
            return
        }
        
        switch rtmMessage.type ?? "" {
        case "version":
            guard let versionDictionary = rtmMessage.data as? [String:Int], let versionInt = versionDictionary["version"] else {
                log.error("WV_DATA: Can't get version of rtm protocol. Data: \(String(describing: rtmMessage.data)).")
                completion?(false)
                return
            }
            
            guard let version = RtmProtocolVersion(rawValue: versionInt) else {
                log.error("WV_DATA: Unknown rtm version - \(versionInt).")
                completion?(false)
                return
            }
            
            log.debug("WV_DATA: received \(version) rtm version.")
            
            guard handlersMapping.index(forKey: version) != nil, var handler = handlersMapping[version]! else {
                log.error("There is no message handler for version: \(version).")
                completion?(false)
                return
            }
            
            handler.wvRtmDelegate = self.rtmDelegate
            handler.outputDelegate = self.outputDelagate
            handler.cardScannerDataSource = self.cardScannerDataSource
            handler.cardScannerPresenterDelegate = self.cardScannerPresenterDelegate

            self.messageHandler = handler
            
            defer {
                for message in preVersionBuffer {
                    received(message: message.message, completion: message.completion)
                }
                preVersionBuffer = []
            }
            
            break
        default:
            log.debug("Adding message to the buffer. Will be used after we will receive rtm version.")
            preVersionBuffer.append(BufferedMessage(message: message, completion: completion))
            return
        }
        
        completion?(true)
    }
    
    fileprivate var wvConfigStorage: WvConfigStorage
    
    fileprivate struct BufferedMessage {
        var message: RtmRawMessage
        var completion: RtmRawMessageCompletion?
    }
    
    fileprivate var preVersionBuffer: [BufferedMessage]
}
