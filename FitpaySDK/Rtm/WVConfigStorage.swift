import Foundation

@objcMembers open class WvConfigStorage: NSObject {
    private let defaults = UserDefaults.standard

    open var paymentDevice: PaymentDevice?
    open var user: User?
    open var device: Device?
    open var rtmConfig: RtmConfigProtocol?
    
    open var a2aReturnLocation: String? {
        get {
            return defaults.string(forKey: "a2aReturnLocation")
        }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: "a2aReturnLocation")
            } else {
                defaults.removeObject(forKey: "a2aReturnLocation")
            }
        }
    }
}
