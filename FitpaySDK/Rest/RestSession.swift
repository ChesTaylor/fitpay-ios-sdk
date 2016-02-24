
import Foundation
import AlamofireObjectMapper
import Alamofire
import ObjectMapper
import JWTDecode

public enum AuthScope : String
{
    case userRead =  "user.read"
    case userWrite = "user.write"
    case tokenRead = "token.read"
    case tokenWrite = "token.write"
}

internal class AuthorizationDetails : Mappable
{
    var tokenType:String?
    var accessToken:String?
    var expiresIn:String?
    var scope:String?
    var jti:String?

    required init?(_ map: Map)
    {
        
    }
    
    func mapping(map: Map)
    {
        tokenType <- map["token_type"]
        accessToken <- map["access_token"]
        expiresIn <- map["expires_in"]
        scope <- map["scope"]
        jti <- map["jti"]
    }
}

public class RestSession
{
    public enum Error : Int, ErrorType, RawIntValue
    {
        case DecodeFailure = 0
        case ParsingFailure
        case AccessTokenFailure
    }

    private var clientId:String
    private var redirectUri:String

    public var userId:String?

    public init(clientId:String, redirectUri:String)
    {
        self.clientId = clientId
        self.redirectUri = redirectUri
    }

    public typealias LoginHandler = (error:ErrorType?)->Void

    public func login(username username:String, password:String, completion:LoginHandler)
    {
        self.acquireAccessToken(clientId: self.clientId, redirectUri: self.redirectUri, username: username, password:password, completion:
        {
            (details:AuthorizationDetails?, error:ErrorType?)->Void in

            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            {
                () -> Void in

                if let error = error
                {
                    dispatch_async(dispatch_get_main_queue(),
                    {
                        () -> Void in

                        completion(error:error)
                    })
                }
                else
                {
                    if let accessToken = details?.accessToken
                    {
                        guard let jwt = try? decode(accessToken) else
                        {
                            dispatch_async(dispatch_get_main_queue(),
                            {
                                () -> Void in

                                completion(error:NSError.error(code:Error.DecodeFailure, domain:RestSession.self, message: "Failed to decode access token"))
                            })

                            return
                        }

                        if let userId = jwt.body["user_id"] as? String
                        {
                            dispatch_async(dispatch_get_main_queue(),
                            {
                                [unowned self] () -> Void in

                                self.userId = userId
                                completion(error:nil)
                            })
                        }
                        else
                        {
                            dispatch_async(dispatch_get_main_queue(),
                            {
                                () -> Void in

                                completion(error:NSError.error(code:Error.ParsingFailure, domain:RestSession.self, message: "Failed to parse user id"))
                            })
                        }
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(),
                        {
                            () -> Void in

                            completion(error:NSError.error(code:Error.AccessTokenFailure, domain:RestSession.self, message: "Failed to retrieve access token"))
                        })
                    }
                }
            })
        })
    }

    internal typealias AcquireAccessTokenHandler = (AuthorizationDetails?, ErrorType?)->Void

    internal func acquireAccessToken(clientId clientId:String, redirectUri:String, username:String, password:String, completion:AcquireAccessTokenHandler)
    {
        let headers = ["Accept" : "application/json"]
        let parameters = [
                "response_type" : "token",
                "client_id" : clientId,
                "redirect_uri" : redirectUri,
                "credentials" : ["username" : username, "password" : password].JSONString!
        ]

        let request = Manager.sharedInstance.request(.POST, AUTHORIZE_URL, parameters: parameters, encoding:.URL, headers: headers)
    
        request.responseObject(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        {
            (response: Response<AuthorizationDetails, NSError>) -> Void in

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(response.result.value, response.result.error)
            })
        }
    }
}
