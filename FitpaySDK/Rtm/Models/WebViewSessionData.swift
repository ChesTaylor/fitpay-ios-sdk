
import ObjectMapper

/// This data can be used to set or verify a user device relationship, retrieve commit changes for the device, etc...
open class SessionData : NSObject, Mappable
{
    open var userId:String?
    open var deviceId:String?
    open var token:String?
    
    internal var encryptedData:String?
    
    public init(token: String, userId: String, deviceId: String) {
        self.userId = userId
        self.deviceId = deviceId
        self.token = token
    }
    
    public required init?(map: Map)
    {
        
    }
    
    open func mapping(map: Map)
    {
        encryptedData <- map["encryptedData"]
        userId <- map["userId"]
        deviceId <- map["deviceId"]
        token <- map["token"]
    }
    
    internal func applySecret(_ secret:Data, expectedKeyId:String?)
    {
        if let tmpSession : SessionData = JWEObject.decrypt(encryptedData, expectedKeyId: expectedKeyId, secret: secret) {
            self.userId = tmpSession.userId
            self.deviceId = tmpSession.deviceId
            self.token = tmpSession.token
        }
    }
}
