import Foundation

public extension Transaction
{
    public var transactionTimeEpochObjC:NSNumber?
    {
        if let transactionTimeEpoch = self.transactionTimeEpoch
        {
            return NSNumber(value:Int64(transactionTimeEpoch))
        }
        
        return nil
    }
}

public class ResultCollectionObjC : NSObject
{
    public typealias ResultCollectionHandler = (_ result:ResultCollectionObjC?, _ error:NSError?) -> Void
    
    public var rawCollection:AnyObject?
    
    @objc open var limit:Int = 0
    @objc open var offset:Int = 0
    @objc open var totalResults:Int = 0
    @objc open var results:[AnyObject]?
    
    
    public var nextAvailable:Bool
    {
        if let creditCardsCollection = self.creditCardsCollection
        {
            return creditCardsCollection.nextAvailable
        }
        else if let devicesCollection = self.devicesCollection
        {
            return devicesCollection.nextAvailable
        }
        else if let transactionsCollection = self.transactionsCollection
        {
            return transactionsCollection.nextAvailable
        }
        
        return false
    }
    
    public var lastAvailable:Bool
    {
        if let creditCardsCollection = self.creditCardsCollection
        {
            return creditCardsCollection.lastAvailable
        }
        else if let devicesCollection = self.devicesCollection
        {
            return devicesCollection.lastAvailable
        }
        else if let transactionsCollection = self.transactionsCollection
        {
            return transactionsCollection.lastAvailable
        }

        return false
    }
    
    public var previousAvailable:Bool
    {
        return self.commitsCollection?.previousAvailable ?? false
    }

    private var creditCardsCollection:ResultCollection<CreditCard>?
    {
        return self.rawCollection as? ResultCollection<CreditCard>
    }
    
    private var devicesCollection:ResultCollection<Device>?
    {
        return self.rawCollection as? ResultCollection<Device>
    }
    
    private var transactionsCollection:ResultCollection<Transaction>?
    {
        return self.rawCollection as? ResultCollection<Transaction>
    }
    
    private var commitsCollection:ResultCollection<Commit>?
    {
        return self.rawCollection as? ResultCollection<Commit>
    }
    
    @objc public func next(completion:@escaping ResultCollectionObjC.ResultCollectionHandler)
    {
        if let creditCardsCollection = self.creditCardsCollection
        {
            creditCardsCollection.next
            {
                (result:ResultCollection<CreditCard>?, error:Error?) in
                completion(CreateCompatibleResultColletion(resultCollection: result), error as NSError?)
            }
        }
        else if let devicesCollection = self.devicesCollection
        {
            devicesCollection.next
            {
                (result:ResultCollection<Device>?, error:Error?) in
                completion(CreateCompatibleResultColletion(resultCollection: result), error as NSError?)
            }
        }
        else if let transactionsCollection = self.transactionsCollection
        {
            transactionsCollection.next
            {
                (result:ResultCollection<Transaction>?, error:Error?) in
                completion(CreateCompatibleResultColletion(resultCollection: result), error as NSError?)
            }
        }
    }
    
    @objc public func last(completion:@escaping ResultCollectionObjC.ResultCollectionHandler)
    {
        if let creditCardsCollection = self.creditCardsCollection
        {
            creditCardsCollection.last
            {
                (result:ResultCollection<CreditCard>?, error:Error?) in
                completion(CreateCompatibleResultColletion(resultCollection: result), error as NSError?)
            }
        }
        else if let devicesCollection = self.devicesCollection
        {
            devicesCollection.last
            {
                (result:ResultCollection<Device>?, error:Error?) in
                completion(CreateCompatibleResultColletion(resultCollection: result), error as NSError?)
            }
        }
        else if let transactionsCollection = self.transactionsCollection
        {
            transactionsCollection.last
            {
                (result:ResultCollection<Transaction>?, error:Error?) in
                completion(CreateCompatibleResultColletion(resultCollection: result), error as NSError?)
            }
        }
    }
    
    @objc public func previous(completion:@escaping ResultCollectionObjC.ResultCollectionHandler)
    {
        if let commitsCollection = self.commitsCollection
        {
            commitsCollection.previous
            {
                (result:ResultCollection<Commit>?, error:Error?) in
                completion(CreateCompatibleResultColletion(resultCollection: result), error as NSError?)
            }
        }
    }
    
    public typealias CollectAllAvailableCompletionObjC = (_ results: [AnyObject]?, _ error: NSError?) -> Void
    
    @objc public func collectAllAvailable(completion: @escaping ResultCollectionObjC.CollectAllAvailableCompletionObjC)
    {
        if let creditCardsCollection = self.creditCardsCollection
        {
            creditCardsCollection.collectAllAvailable
            {
                (results, error) in
                completion(results, error as NSError? )
            }
        }
    }
}

public extension User
{
    @objc public var lastModifiedEpochObjC:NSNumber?
    {
        if let lastModifiedEpoch = self.lastModifiedEpoch
        {
            return NSNumber(value: Int64(lastModifiedEpoch))
        }
        
        return nil
    }
    
    @objc public func listCreditCardsObjC(excludeState:[String], limit:Int, offset:Int, completion:@escaping ResultCollectionObjC.ResultCollectionHandler)
    {
        self.getCreditCards(excludeState: excludeState, limit: limit, offset: offset)
        {
            (result:ResultCollection<CreditCard>?, error:NSError?) in
            
            completion(CreateCompatibleResultColletion(resultCollection: result), error)
        }
    }
    
    @objc public func listDevicesObjC(limit:Int, offset:Int, completion:@escaping ResultCollectionObjC.ResultCollectionHandler)
    {
        self.getDevices(limit: limit, offset: offset)
        {
            (result:ResultCollection<Device>?, error:NSError?) in
            completion(CreateCompatibleResultColletion(resultCollection: result), error)
        }
    }
}

internal func CreateCompatibleResultColletion<T>(resultCollection:ResultCollection<T>?) -> ResultCollectionObjC?
{
    if let resultCollection = resultCollection
    {
        let compResultCollection = ResultCollectionObjC()
        
        compResultCollection.rawCollection = resultCollection
        compResultCollection.limit = resultCollection.limit ?? 0
        compResultCollection.offset = resultCollection.offset ?? 0
        compResultCollection.totalResults = resultCollection.totalResults ?? 0
        
        if let results = resultCollection.results
        {
            var compResults = [AnyObject]()
            
            for item in results
            {
                let item = item as AnyObject
                compResults.append(item)
            }
            
            compResultCollection.results = compResults
        }
        
        return compResultCollection
    }
    
    return nil
}

public extension Commit
{
    @objc public static var CommitType_CREDITCARD_CREATED:String
    {
        return CommitType.creditCardCreated.rawValue
    }
    
    @objc public static var CommitType_CREDITCARD_DEACTIVATED:String
    {
        return CommitType.creditCardDeactivated.rawValue
    }
    
    @objc public static var CommitType_CREDITCARD_ACTIVATED:String
    {
        return CommitType.creditCardActivated.rawValue
    }
        
    @objc public static var CommitType_CREDITCARD_REACTIVATED:String
    {
        return CommitType.creditCardReactivated.rawValue
    }
    
    @objc public static var CommitType_CREDITCARD_DELETED:String
    {
        return CommitType.creditCardDeleted.rawValue
    }
    
    @objc public static var CommitType_RESET_DEFAULT_CREDITCARD:String
    {
        return CommitType.resetDefaultCreditCard.rawValue
    }
    
    @objc public static var CommitType_SET_DEFAULT_CREDITCARD:String
    {
        return CommitType.setDefaultCreditCard.rawValue
    }
    
    @objc public static var CommitType_APDU_PACKAGE:String
    {
        return CommitType.apduPackage.rawValue
    }
    
    @objc public var commitTypeObjC:String?
    {
        return commitType?.rawValue
    }
}

public extension ApduPackage
{
    @objc public static var APDUPackageResponseState_PROCESSED:String
    {
        return APDUPackageResponseState.processed.rawValue
    }
    
    @objc public static var APDUPackageResponseState_FAILED:String
    {
        return APDUPackageResponseState.failed.rawValue
    }
    
    @objc public static var APDUPackageResponseState_ERROR:String
    {
        return APDUPackageResponseState.error.rawValue
    }
    
    @objc public static var APDUPackageResponseState_EXPIRED:String
    {
        return APDUPackageResponseState.expired.rawValue
    }
    
    public var stateObjC:String?
    {
        return self.state?.rawValue
    }
    
    public var executedEpochObjC:NSNumber?
    {
        if let executedEpoch = self.executedEpoch
        {
            return NSNumber(value: Int64(executedEpoch))
        }
        
        return nil
    }
    
    public var validUntilEpochObjC:NSNumber?
    {
        if let validUntilEpoch = self.validUntilEpoch
        {
            return NSNumber(value: validUntilEpoch.timeIntervalSince1970)
        }
        
        return nil
    }
}

public extension Device
{
    public var createdEpochObjC:NSNumber?
    {
        if let createdEpoch = self.createdEpoch
        {
            return NSNumber(value: Int64(createdEpoch))
        }
        
        return nil
    }
    
    @objc public func listCommitsObjC(commitsAfter:String?, limit:Int, offset:Int, completion:@escaping ResultCollectionObjC.ResultCollectionHandler)
    {
        self.listCommits(commitsAfter: commitsAfter, limit: limit, offset: offset)
        {
            (result:ResultCollection<Commit>?, error) in
            completion(CreateCompatibleResultColletion(resultCollection: result), error)
        }
    }
}

public extension VerificationMethod
{
    /// VerificationMethodType
    
    @objc public static var VerificationMethodType_TEXT_TO_CARDHOLDER_NUMBER:String
    {
        return VerificationMethodType.textToCardholderNumber.rawValue
    }
    
    @objc public static var VerificationMethodType_EMAIL_TO_CARDHOLDER_ADDRESS:String
    {
        return VerificationMethodType.emailToCardholderAddress.rawValue
    }
    
    @objc public static var VerificationMethodType_CARDHOLDER_TO_CALL_AUTOMATED_NUMBER:String
    {
        return VerificationMethodType.cardholderToCallAutomatedNumber.rawValue
    }
    
    @objc public static var VerificationMethodType_CARDHOLDER_TO_CALL_MANNED_NUMBER:String
    {
        return VerificationMethodType.cardholderToCallMannedNumber.rawValue
    }
        
    @objc public static var VerificationMethodType_CARDHOLDER_TO_VISIT_WEBSITE:String
    {
        return VerificationMethodType.cardholderToVisitWebsite.rawValue
    }
    
    @objc public static var VerificationMethodType_CARDHOLDER_TO_USE_MOBILE_APP:String
    {
        return VerificationMethodType.cardholderToUseMobileApp.rawValue
    }
    
    @objc public static var VerificationMethodType_ISSUER_TO_CALL_CARDHOLDER_NUMBER:String
    {
        return VerificationMethodType.issuerToCallCardholderNumber.rawValue
    }
    
    /// VerificationState
    
    @objc public static var VerificationState_AVAILABLE_FOR_SELECTION:String
    {
        return VerificationState.availableForSelection.rawValue
    }
    
    @objc public static var VerificationState_AWAITING_VERIFICATION:String
    {
        return VerificationState.awaitingVerification.rawValue
    }
    
    @objc public static var VerificationState_EXPIRED:String
    {
        return VerificationState.expired.rawValue
    }
    
    @objc public static var VerificationState_VERIFIED:String
    {
        return VerificationState.verified.rawValue
    }
    
    /// VerificationResult
    
    @objc public static var Verification_Result_SUCCESS:String
    {
        return VerificationResult.success.rawValue
    }
    
    @objc public static var Verification_Result_INCORRECT_CODE:String
    {
        return VerificationResult.incorrectCode.rawValue
    }
    
    @objc public static var Verification_Result_INCORRECT_CODE_RETRIES_EXCEEDED:String
    {
        return VerificationResult.incorrectCodeRetriesExceeded.rawValue
    }
      
    @objc public static var Verification_Result_EXPIRED_CODE:String
    {
        return VerificationResult.expiredCode.rawValue
    }
    
    @objc public static var Verification_Result_INCORRECT_TAV:String
    {
        return VerificationResult.incorrectTAV.rawValue
    }
    
    @objc public static var Verification_Result_EXPIRED_SESSION:String
    {
        return VerificationResult.expiredSession.rawValue
    }
    
    public var stateObjC:String?
    {
        return self.state?.rawValue
    }
    
    public var methodTypeObjC:String?
    {
        return self.methodType?.rawValue
    }
    
    public var verificationResultObjC:String?
    {
        return self.verificationResult?.rawValue
    }

    public var createdEpochObjC:NSNumber?
    {
        if let createdEpoch = self.createdEpoch
        {
            return NSNumber(value: Int64(createdEpoch))
        }
        
        return nil
    }
}

public extension CreditCard
{
    @objc public static var TokenizationState_NEW:String
    {
        return TokenizationState.new.rawValue
    }
    
    @objc public static var TokenizationState_NOT_ELIGIBLE:String
    {
        return TokenizationState.notEligible.rawValue
    }
    
    @objc public static var TokenizationState_ELIGIBLE:String
    {
        return TokenizationState.eligible.rawValue
    }
    
    @objc public static var TokenizationState_DECLINED_TERMS_AND_CONDITIONS:String
    {
        return TokenizationState.declinedTermsAndConditions.rawValue
    }
    
    @objc public static var TokenizationState_PENDING_ACTIVE:String
    {
        return TokenizationState.pendingActive.rawValue
    }
    
    @objc public static var TokenizationState_PENDING_VERIFICATION:String
    {
        return TokenizationState.pendingVerification.rawValue
    }
    
    @objc public static var TokenizationState_DELETED:String
    {
        return TokenizationState.deleted.rawValue
    }
    
    @objc public static var TokenizationState_ACTIVE:String
    {
        return TokenizationState.active.rawValue
    }
    
    @objc public static var TokenizationState_DEACTIVATED:String
    {
        return TokenizationState.deactivated.rawValue
    }
    
    @objc public static var TokenizationState_ERROR:String
    {
        return TokenizationState.error.rawValue
    }
    
    @objc public static var TokenizationState_DECLINED:String
    {
        return TokenizationState.declined.rawValue
    }
    
    @objc public static var CreditCardInitiator_CARDHOLDER:String
    {
        return CreditCardInitiator.cardholder.rawValue
    }
    
    @objc public static var CreditCardInitiator_ISSUER:String
    {
        return CreditCardInitiator.issuer.rawValue
    }
    
    public var stateObjC:String?
    {
        return self.state?.rawValue
    }
    
    public var createdEpochObjC:NSNumber?
    {
        if let createdEpoch = self.createdEpoch
        {
            return NSNumber(value: Int64(createdEpoch))
        }
        
        return nil
    }
    
    @objc public func deactivate(causedBy:String, reason:String, completion:@escaping RestClient.CreditCardTransitionHandler)
    {
        self.deactivate(causedBy: CreditCardInitiator(rawValue:causedBy)!, reason: reason, completion: completion)
    }
    
    @objc public func reactivate(causedBy:String, reason:String, completion:@escaping RestClient.CreditCardTransitionHandler)
    {
        self.reactivate(causedBy: CreditCardInitiator(rawValue:causedBy)!, reason: reason, completion: completion)
    }
    
    @objc public func listTransactionsObjC(limit:Int, offset:Int, completion:@escaping ResultCollectionObjC.ResultCollectionHandler)
    {
        self.listTransactions(limit:limit, offset: offset)
        {
            (result:ResultCollection<Transaction>?, error:NSError?) in
            completion(CreateCompatibleResultColletion(resultCollection: result), error)
        }
    }
}

public extension EncryptionKey
{
    public var createdEpochObjC:NSNumber?
    {
        if let createdEpoch = self.createdEpoch
        {
            return NSNumber(value: Int64(createdEpoch))
        }
        
        return nil
    }

}

public extension FitpayEvent
{
    public var eventIdObjC : NSNumber? {
        return self.eventId.eventId() as NSNumber
    }
}

public extension PaymentDevice
{
    public func connectObjC() {
        self.connect()
    }
    
    public func connectObjC(timeout:Int) {
        self.connect(timeout)
    }
}
