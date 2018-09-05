@objc public protocol RtmConfigProtocol {
    var redirectUri: String? { get }
    var deviceInfo: Device? { get set }
    var accessToken: String? { get set }
    var hasAccount: Bool { get }

    func jsonDict() -> [String: Any]
}

@objc open class RtmConfig: NSObject, Serializable, RtmConfigProtocol {
    @objc open var redirectUri: String?
    @objc open var deviceInfo: Device?
    @objc open var hasAccount: Bool = false
    @objc open var accessToken: String?
    
    @objc open var language: String?
    
    @objc open var clientId: String?
    @objc open var userEmail: String?
    @objc open var version: String?
    @objc open var demoMode = false
    @objc open var customCSSUrl: String?
    @objc open var demoCardGroup: String?
    @objc open var baseLanguageUrl: String?
    @objc open var useWebCardScanner = true
    
    @objc open var customs: [String: Any] = [:]
    
    @objc public init(userEmail: String?, deviceInfo: Device?, hasAccount: Bool = false) {
        super.init()

        self.clientId = FitpayConfig.clientId
        self.redirectUri = FitpayConfig.redirectURL
        self.demoMode = FitpayConfig.Web.demoMode
        self.demoCardGroup = FitpayConfig.Web.demoCardGroup
        self.customCSSUrl = FitpayConfig.Web.cssURL
        self.useWebCardScanner = !FitpayConfig.Web.supportCardScanner
        self.baseLanguageUrl = FitpayConfig.Web.baseLanguageURL
        
        self.userEmail = userEmail
        self.deviceInfo = deviceInfo
        self.hasAccount = hasAccount
    }

    private enum CodingKeys: String, CodingKey {
        case clientId
        case redirectUri
        case userEmail
        case deviceInfo = "paymentDevice"
        case hasAccount = "account"
        case version
        case demoMode
        case customCSSUrl = "themeOverrideCssUrl"
        case demoCardGroup
        case accessToken
        case language
        case baseLanguageUrl = "baseLangUrl"
        case useWebCardScanner 
    }
    
    public func jsonDict() -> [String: Any] {
        var dict = self.toJSON()!
        dict += customs
        return dict
    }

}
