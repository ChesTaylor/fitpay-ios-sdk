import Foundation

class WvConfigStorage {
    var sdkConfiguration: FitpaySDKConfiguration?
    var paymentDevice: PaymentDevice?
    var user: User?
    var device: DeviceInfo?
    var supportsAppVerification = false
    var a2aReturnLocation: String? = nil
    
    var rtmConfig: RtmConfigProtocol?
}
