
import ObjectMapper

public class ResultCollection<T: Mappable> : ClientModel, Mappable, SecretApplyable
{
    public var limit:Int?
    public var offset:Int?
    public var totalResults:Int?
    public var results:[T]?
    internal var links:[ResourceLink]?
    private let lastResourse = "last"
    private let nextResourse = "next"
    private let previousResource = "previous"
    
    public var hasNext:Bool
    {
        return self.links?.url(self.nextResourse) != nil
    }
    
    public var hasLast:Bool
    {
        return self.links?.url(self.lastResourse) != nil
    }
    
    public var hasPrevious:Bool
    {
        return self.links?.url(self.previousResource) != nil
    }
    
    internal var client:RestClient?
    {
        get
        {
            if let results = self.results
            {
                for result in results
                {
                    if var result = result as? ClientModel
                    {
                        return result.client
                    }
                }
            }
            
            return nil
        }
        
        set
        {
            if let results = self.results
            {
                for result in results
                {
                    if var result = result as? ClientModel
                    {
                        result.client = newValue
                    }
                    else
                    {
                        print("Failed to convert \(result) to ClientModel")
                    }
                }
            }
        }
    }
    
    public required init?(_ map: Map)
    {
        
    }
    
    public func mapping(map: Map)
    {
        links <- (map["_links"], ResourceLinkTransformType())
        limit <- map["limit"]
        offset <- map["offset"]
        totalResults <- map["totalResults"]
        
        if let objectsArray = map["results"].currentValue as? [AnyObject] {
            results = [T]()
            for objectMap in objectsArray {
                if let modelObject = Mapper<T>().map(objectMap) {
                    results!.append(modelObject)
                }
            }
        }
    }
    
    internal func applySecret(secret:NSData, expectedKeyId:String?)
    {
        if let results = self.results {
            for modelObject in results {
                if let objectWithEncryptedData = modelObject as? SecretApplyable {
                    objectWithEncryptedData.applySecret(secret, expectedKeyId: expectedKeyId)
                }
            }
        }
    }
    
    public func next(completion:RestClient.CreditCardsHandler)
    {
        let resource = self.nextResourse
        let url = self.links?.url(resource)
        if  let url = url, client = self.client
        {
            client.creditCards(url, parameters: nil, completion: completion)
        }
        else
        {
            let error = NSError.clientUrlError(domain:ResultCollection.self, code:0, client: client, url: url, resource: resource)
            completion(result: nil, error: error)
        }
    }
    
    public func last(completion:RestClient.CreditCardsHandler)
    {
        let resource = self.lastResourse
        let url = self.links?.url(resource)
        if  let url = url, client = self.client
        {
            client.creditCards(url, parameters: nil, completion: completion)
        }
        else
        {
            let error = NSError.clientUrlError(domain:ResultCollection.self, code:0, client: client, url: url, resource: resource)
            completion(result: nil, error: error)
        }
    }
    
    public func next(completion:RestClient.DevicesHandler)
    {
        let resource = self.nextResourse
        let url = self.links?.url(resource)
        if  let url = url, client = self.client
        {
            client.devices(url, parameters: nil, completion: completion)
        }
        else
        {
            let error = NSError.clientUrlError(domain:ResultCollection.self, code:0, client: client, url: url, resource: resource)
            completion(result: nil, error: error)
        }
    }
    
    public func last(completion:RestClient.DevicesHandler)
    {
        let resource = self.lastResourse
        let url = self.links?.url(resource)
        if  let url = url, client = self.client
        {
            client.devices(url, parameters: nil, completion: completion)
        }
        else
        {
            let error = NSError.clientUrlError(domain:ResultCollection.self, code:0, client: client, url: url, resource: resource)
            completion(result: nil, error: error)
        }
    }
    
    public func next(completion:RestClient.TransactionsHandler)
    {
        let resource = self.nextResourse
        let url = self.links?.url(resource)
        if  let url = url, client = self.client
        {
            client.transactions(url, parameters: nil, completion: completion)
        }
        else
        {
            let error = NSError.clientUrlError(domain:ResultCollection.self, code:0, client: client, url: url, resource: resource)
            completion(result: nil, error: error)
        }
    }
    
    public func last(completion:RestClient.TransactionsHandler)
    {
        let resource = self.lastResourse
        let url = self.links?.url(resource)
        if  let url = url, client = self.client
        {
            client.transactions(url, parameters: nil, completion: completion)
        }
        else
        {
            let error = NSError.clientUrlError(domain:ResultCollection.self, code:0, client: client, url: url, resource: resource)
            completion(result: nil, error: error)
        }
    }
    
    public func previous(completion:RestClient.CommitsHandler)
    {
        let resource = self.previousResource
        let url = self.links?.url(resource)
        if  let url = url, client = self.client
        {
            client.commits(url, parameters: nil, completion: completion)
        }
        else
        {
            let error = NSError.clientUrlError(domain:ResultCollection.self, code:0, client: client, url: url, resource: resource)
            completion(result: nil, error: error)
        }
    }
}
