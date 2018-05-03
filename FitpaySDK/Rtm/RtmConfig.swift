import ObjectMapper

internal enum RtmConfigDafaultMappingKey: String {
    case clientId = "clientId"
    case redirectUri = "redirectUri"
    case userEmail = "userEmail"
    case deviceInfo = "paymentDevice"
    case hasAccount = "account"
    case version = "version"
    case demoMode = "demoMode"
    case customCSSUrl = "themeOverrideCssUrl"
    case demoCardGroup = "demoCardGroup"
    case accessToken = "accessToken"
    case language = "language"
    case baseLanguageUrl = "baseLangUrl"
    case useWebCardScanner = "useWebCardScanner"
}

@objc public protocol RtmConfigProtocol {
    var redirectUri: String? { get }
    var deviceInfo: DeviceInfo? { get set }
    var accessToken: String? { get set }
    var hasAccount: Bool { get }

    func update(value: Any, forKey: String)

    func jsonDict() -> [String: Any]
}

open class RtmConfig: NSObject, Mappable, RtmConfigProtocol {
    open var clientId: String?
    open var redirectUri: String?
    open var userEmail: String?
    open var deviceInfo: DeviceInfo?
    open var hasAccount: Bool = false
    open var version: String?
    open var demoMode: Bool?
    open var customCSSUrl: String?
    open var demoCardGroup: String?
    open var accessToken: String?
    open var language: String?
    open var baseLanguageUrl: String?
    open var useWebCardScanner: Bool?
    
    open var customs: [String:Any]?
    
    public init(userEmail: String?, deviceInfo: DeviceInfo?, hasAccount: Bool = false) {
        self.clientId = FitpaySDKConfig.clientId
        self.redirectUri = FitpaySDKConfig.redirectURL
        self.userEmail = userEmail
        self.deviceInfo = deviceInfo
        self.hasAccount = hasAccount
    }
    
    public required init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        clientId        <- map[RtmConfigDafaultMappingKey.clientId.rawValue]
        redirectUri     <- map[RtmConfigDafaultMappingKey.redirectUri.rawValue]
        userEmail       <- map[RtmConfigDafaultMappingKey.userEmail.rawValue]
        deviceInfo      <- map[RtmConfigDafaultMappingKey.deviceInfo.rawValue]
        hasAccount      <- map[RtmConfigDafaultMappingKey.hasAccount.rawValue]
        version         <- map[RtmConfigDafaultMappingKey.version.rawValue]
        demoMode        <- map[RtmConfigDafaultMappingKey.demoMode.rawValue]
        customCSSUrl    <- map[RtmConfigDafaultMappingKey.customCSSUrl.rawValue]
        demoCardGroup   <- map[RtmConfigDafaultMappingKey.demoCardGroup.rawValue]
        accessToken     <- map[RtmConfigDafaultMappingKey.accessToken.rawValue]
        language        <- map[RtmConfigDafaultMappingKey.language.rawValue]
        baseLanguageUrl <- map[RtmConfigDafaultMappingKey.baseLanguageUrl.rawValue]
        useWebCardScanner <- map[RtmConfigDafaultMappingKey.useWebCardScanner.rawValue]
    }
    
    public func update(value: Any, forKey key: String) {
        if let mappingKey = RtmConfigDafaultMappingKey(rawValue: key) {
            switch mappingKey {
            case .accessToken:
                accessToken = value as? String
                break
            case .clientId:
                clientId = value as? String
                break
            case .redirectUri:
                redirectUri = value as? String
                break
            case .userEmail:
                userEmail = value as? String
                break
            case .deviceInfo:
                deviceInfo = value as? DeviceInfo
                break
            case .hasAccount:
                hasAccount = value as? Bool ?? false
                break
            case .version:
                version = value as? String
                break
            case .demoMode:
                demoMode = value as? Bool
                break
            case .customCSSUrl:
                customCSSUrl = value as? String
                break
            case .demoCardGroup:
                demoCardGroup = value as? String
                break
            case .language:
                language = value as? String
                break
            case .baseLanguageUrl:
                baseLanguageUrl = value as? String
                break
            case .useWebCardScanner:
                useWebCardScanner = value as? Bool
            }
        } else {
            if customs == nil {
                customs = [:]
            }
            
            customs!.updateValue(value, forKey: key)
        }
    }
    
    public func jsonDict() -> [String: Any] {
        var dict = self.toJSON()
        if let customs = self.customs {
            dict += customs
        }
        return dict
    }

}
