import Foundation

class RtmMessageHandlerV5: RtmMessageHandlerV4 {
    enum RtmMessageTypeVer5: String, RtmMessageTypeWithHandler {
        case rtmVersion            = "version"
        case sync                  = "sync"
        case deviceStatus          = "deviceStatus"
        case userData              = "userData"
        case logout                = "logout"
        case resolve               = "resolve"
        case scanRequest           = "scanRequest"
        case cardScanned           = "cardScanned"
        case sdkVersionRequest     = "sdkVersionRequest"
        case sdkVersion            = "sdkVersion"
        case idVerificationRequest = "idVerificationRequest"
        case idVerification        = "idVerification"
        case supportsIssuerAppVerification = "supportsIssuerAppVerification"
        case appToAppVerification = "appToAppVerification"
        
        func msgHandlerFor(handlerObject: RtmMessageHandler) -> MessageTypeHandler? {
            guard let handlerObject = handlerObject as? RtmMessageHandlerV5 else {
                return nil
            }
            
            switch self {
            case .userData:
                return handlerObject.handleSessionData
            case .sync:
                return handlerObject.handleSync
            case .scanRequest:
                return handlerObject.handleScanRequest
            case .sdkVersionRequest:
                return handlerObject.handleSdkVersion
            case .idVerificationRequest:
                return handlerObject.handleIdVerificationRequest
            case .supportsIssuerAppVerification:
                return handlerObject.issuerAppVerificationRequest
            case .appToAppVerification:
                return handlerObject.handleAppToAppVerificationRequest
            case .deviceStatus,
                 .logout,
                 .resolve,
                 .rtmVersion,
                 .cardScanned,
                 .sdkVersion,
                 .idVerification:
                return nil
            }
        }
    }
    
    override func handlerFor(rtmMessage: String) -> MessageTypeHandler? {
        guard let messageAction = RtmMessageTypeVer5(rawValue: rtmMessage) else {
            log.debug("WV_DATA: RtmMessage. Action is missing or unknown: \(rtmMessage)")
            return nil
        }
        
        return messageAction.msgHandlerFor(handlerObject: self)
    }
    
    func handleIdVerificationRequest(_ message: RtmMessage) {
        wvConfigStorage.paymentDevice?.handleIdVerificationRequest() { [weak self] (response) in
            if let delegate = self?.outputDelegate {
                delegate.send(rtmMessage: RtmMessageResponse(data: response.toJSON(), type: RtmMessageTypeVer5.idVerification.rawValue, success: true), retries: 3)
            }
        }
    }
    
    func issuerAppVerificationRequest(_ message: RtmMessage) {
        guard let delegate = self.outputDelegate else { return }
        let data = [RtmMessageTypeVer5.supportsIssuerAppVerification.rawValue: FitpayConfig.supportApp2App]
        delegate.send(rtmMessage: RtmMessageResponse(callbackId: message.callBackId,
                                                     data: data,
                                                     type: RtmMessageTypeVer5.supportsIssuerAppVerification.rawValue,
                                                     success: true), retries: 3)
    }
    
    func handleAppToAppVerificationRequest(_ message: RtmMessage) {
        guard let delegate = self.outputDelegate else { return }
        
        func appToAppVerificationFailed(reason: A2AVerificationError) {
            guard let delegate = self.outputDelegate else { return }
            
            let data = ["reason": reason.rawValue]
            delegate.send(rtmMessage: RtmMessageResponse(callbackId: message.callBackId,
                                                         data: data,
                                                         type: RtmMessageTypeVer5.appToAppVerification.rawValue,
                                                         success: false), retries: 3)
        }
        
        if (FitpayConfig.supportApp2App) {
            guard let data = message.data as? [String: Any] else { return }
            guard let appToAppVerification = try? A2AVerificationRequest(data) else {
                appToAppVerificationFailed(reason: A2AVerificationError.CantProcess)
                return
            }
            
            let mastercard = "MASTERCARD"
            if appToAppVerification.cardType != mastercard {
                delegate.send(rtmMessage: RtmMessageResponse(callbackId: message.callBackId,
                                                             data: message.data,
                                                             type: RtmMessageTypeVer5.appToAppVerification.rawValue,
                                                             success: true), retries: 3)
                
                a2aVerificationDelegate?.verificationFinished(verificationInfo: appToAppVerification)
                self.wvConfigStorage.a2aReturnLocation = appToAppVerification.returnLocation
            } else {
                appToAppVerificationFailed(reason: A2AVerificationError.NotSupported)
            }
        } else {
            appToAppVerificationFailed(reason: A2AVerificationError.NotSupported)
        }
    }
}
