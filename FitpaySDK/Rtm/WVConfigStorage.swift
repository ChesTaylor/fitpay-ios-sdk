import Foundation

@objc open class WvConfigStorage: NSObject {
    @objc open var paymentDevice: PaymentDevice?
    @objc open var user: User?
    @objc open var device: Device?
    @objc open var a2aReturnLocation: String?
    @objc open var rtmConfig: RtmConfigProtocol?
}
