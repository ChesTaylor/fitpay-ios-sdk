import Foundation
import WebKit

/// Main Object for interacting with Fitpay Web app
@objc open class FitpayWeb: NSObject {
    
    /// Use this singleton
    @objc public static let shared = FitpayWeb()

    /// Set the rtmDelegate to receive authorization and other messages from the webview
    ///
    /// Needed for capturing a back button press
    @objc weak open var rtmDelegate: RTMDelegate? {
        didSet {
            wvConfig.rtmDelegate = rtmDelegate
        }
    }
    
    /// Set the a2aVerificationDelegate to handle step up methods using the issuer app
    @objc weak open var a2aVerificationDelegate: FitpayA2AVerificationDelegate? {
        didSet {
            wvConfig.a2aVerificationDelegate = a2aVerificationDelegate
        }
    }
    
    /// Set the cardScannerDataSource to handle step up methods using the issuer app
    @objc weak open var cardScannerDataSource: FitpayCardScannerDataSource? {
        didSet {
            wvConfig.cardScannerDataSource = cardScannerDataSource
        }
    }
    
    /// Set the cardScannerPresenterDelegate to handle step up methods using the issuer app
    @objc weak open var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate? {
        didSet {
            wvConfig.cardScannerPresenterDelegate = cardScannerPresenterDelegate
        }
    }
    
    private var wkWebView: WKWebView!
    private var wvConfig: WvConfig!
    
    // MARK: - Functions
    
    /// Setup a Fitpay WKWebview for use
    ///
    /// You must use WKWebview returned by this function
    ///
    /// This must be called before any other methods
    ///
    /// - Parameters:
    ///   - userEmail: user email - defaults to nil
    ///   - userHasFitpayAccount: user has fitpayAccount - defaults to false
    ///   - accessToken: skips the pin screen if valid
    ///   - paymentDevice: figuring out
    ///   - paymentDeviceConnector: figuring out
    ///   - frame: needed for initializing the wkWebView
    /// - Returns: WKWebview with correct configuration and frame
    @objc open func setupWebView(userEmail: String? = nil,
                                 userHasFitpayAccount: Bool = false,
                                 accessToken: String? = nil,
                                 paymentDevice: PaymentDevice,
                                 paymentDeviceConnector: PaymentDeviceConnectable,
                                 frame: CGRect,
                                 script: WKUserScript? = nil,
                                 language: String? = nil) -> WKWebView {

        _ = paymentDevice.changeDeviceInterface(paymentDeviceConnector)

        let rtmConfig = RtmConfig(userEmail: userEmail, deviceInfo: paymentDeviceConnector.deviceInfo())
        rtmConfig.hasAccount = userHasFitpayAccount
        rtmConfig.language = language
        rtmConfig.accessToken = accessToken
        
        wvConfig = WvConfig(paymentDevice: paymentDevice, rtmConfig: rtmConfig)

        let config = wvConfig!.getConfig()
        if let script = script {
            config.userContentController.addUserScript(script)
        }
        wkWebView = WKWebView(frame: frame, configuration: config)
        
        wvConfig!.setWebView(wkWebView)
        
        wkWebView!.navigationDelegate = self
        
        return wkWebView!
    }

    /// Loads the main page on Fitpay based on user variables
    @objc open func load() {
        wkWebView.load(wvConfig.getRequest())
    }
    
    /// Loads a specific page on Fitpay based on user variables
    ///
    /// Currently works with `/addCard`, `/privacyPolicy`, and `/terms`
    @objc open func load(relativePath: String) {
        guard let (url, encodedConfig) = wvConfig.getURLAndConfig() else { return }
        
        let configuredUrl = "\(url)\(relativePath)?config=\(encodedConfig)"
        
        log.verbose(configuredUrl)
        
        let requestUrl = URL(string: configuredUrl)
        let request = URLRequest(url: requestUrl!)
        
        wkWebView.load(request)
    }
    
    /// Loads any valid url - use with discretion
    ///
    /// Can construct URL from `FitpayConfig.WebUrl` and config
    @objc open func load(absolutePath: String) {
        let requestUrl = URL(string: absolutePath)
        let request = URLRequest(url: requestUrl!)
        
        wkWebView.load(request)
    }
    
    /// Get the config to construct a url on your own if needed
    @objc open func getConfig() -> String? {
        return wvConfig.getURLAndConfig()?.encodedConfig
    }
    
    /// Should be called once the webview is loaded
    ///
    /// This is called automatically unless you become the navigationDelegate in which case you must set it manually
    ///
    /// You can use `WKNavigationDelegate.webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)` for managing page state
    @objc open func webViewPageLoaded() {
         wvConfig.webViewPageLoaded()
    }
 
    open func respondToA2AWith(success: Bool, error: A2AVerificationError?) {
        wvConfig.rtmMessaging.messageHandler?.appToAppVerificationResponse(success: success, reason: error)
    }
    
}


extension FitpayWeb: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewPageLoaded()
    }
    
}
