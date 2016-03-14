import XCTest
@testable import FitpaySDK
@testable import RTMClientApp

class RtmSessionTests: XCTestCase
{
    let clientId = "pagare"
    let redirectUri = "http://demo.pagare.me"
    let username = "testableuser@something.com"
    let password = "1029"
    
    var session:RtmSession!
    var restSession:RestSession!
    var restClient:RestClient!
    
    override func setUp()
    {
        super.setUp()
        
        self.session = RtmSession(authorizationURL: NSURL(string: RTM_AUTHORIZATION_URL)!)
        self.restSession = RestSession(clientId:self.clientId, redirectUri:self.redirectUri)
        self.restClient = RestClient(session: self.restSession!)
    }
    
    override func tearDown()
    {
        self.restClient = nil
        self.session = nil
        self.restSession = nil
        
        
        super.tearDown()
    }
    
    func connect()
    {
        self.restSession.login(username: self.username, password: self.password)
        {
            [unowned self](error) -> Void in
            XCTAssertNil(error)
            XCTAssertTrue(self.restSession.isAuthorized)
            
            if !self.restSession.isAuthorized
            {
                return
            }
            
            self.restClient.devices(userId: self.restSession.userId!, limit: 10, offset: 0, completion:
            {
                (devices, error) -> Void in
                
                for deviceInfo in devices!.results! {
                    if (deviceInfo.secureElementId != nil) {
                        self.session?.connectAndWaitForParticipants(deviceInfo)
                        break
                    }
                }
            })
        }
    }
    
    func testRtmConnectionCheck()
    {
        let expectation = super.expectationWithDescription("connection check")
        self.session.onConnect =
        {
            (url, error) -> Void in
            
            XCTAssertNil(error)
            XCTAssertNotNil(url)
            
            expectation.fulfill()
        }
        
        self.connect()
        
        super.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testUserLogin()
    {
        let expectation = super.expectationWithDescription("connection check")
        self.session.onConnect =
        {
            (url, error) -> Void in
            
            XCTAssertNil(error)
            XCTAssertNotNil(url)
            
            if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate, let window = delegate.window {
                let webview = UIWebView(frame: UIScreen.mainScreen().bounds)
                window.addSubview(webview)
                webview.loadRequest(NSURLRequest(URL: url!))
            }
        }
        
        self.session.onUserLogin =
        {
            (sessionData) -> Void in
            
            XCTAssertNotNil(sessionData)
            XCTAssertNotNil(sessionData.userId)
            XCTAssertNotNil(sessionData.deviceId)
            XCTAssertNotNil(sessionData.token)
            
            expectation.fulfill()
        }
        
        self.connect()
        
        super.waitForExpectationsWithTimeout(1000, handler: nil)
    }
}