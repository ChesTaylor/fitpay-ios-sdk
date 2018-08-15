import Foundation

class JOSEHeader {

    var cty: String?
    var enc: JWSEncryption?
    var alg: JWSAlgorithm?
    var iv : Data?
    var tag: Data?
    var kid: String?
    
    var sender: String?
    var destination: String?
    
    // MARK: - Lifecycle
    
    init(encryption: JWSEncryption, algorithm: JWSAlgorithm) {
        enc = encryption
        alg = algorithm
    }
    
    init(headerPayload: String) {
        guard let headerData = headerPayload.base64URLdecoded() else { return }
        guard let json = try? JSONSerialization.jsonObject(with: headerData, options: .mutableContainers) else { return }
        guard let mappedJson = json as? [String: String] else { return }
        
        cty = mappedJson["cty"]
        kid = mappedJson["kid"]
        iv = mappedJson["iv"]?.base64URLdecoded() as Data?
        tag = mappedJson["tag"]?.base64URLdecoded() as Data?
        
        if let encStr = mappedJson["enc"] {
            enc = JWSEncryption(rawValue: encStr)
        }
        
        if let algStr = mappedJson["alg"] {
            alg = JWSAlgorithm(rawValue: algStr)
        }
    }
    
    // MARK: - Functions
    
    func serialize() throws -> String? {
        var paramsDict: [String: String]! = [String: String]()
    
        guard enc != nil else {
            throw JWTError.encryptionNotSpecified
        }
        
        guard alg != nil else {
            throw JWTError.algorithmNotSpecified
        }
        
        guard iv != nil else {
            throw JWTError.headersIVNotSpecified
        }
        
        guard tag != nil else {
            throw JWTError.headersTagNotSpecified
        }
        
        if (cty == nil) {
            cty = "application/json"
        }
        
        paramsDict["enc"] = enc?.rawValue
        paramsDict["alg"] = alg?.rawValue
        paramsDict["iv"]  = iv!.base64URLencoded()
        paramsDict["tag"] = tag!.base64URLencoded()
        
        if (kid != nil) {
            paramsDict["kid"] = kid!
        }
        
        if (sender != nil) {
            paramsDict["sender"] = sender!
        }
        
        if (destination != nil) {
            paramsDict["destination"] = destination!
        }
        
        // we will serialize cty separately, because NSJSONSerialization is adding escape for "/"
        var jsonData = try JSONSerialization.data(withJSONObject: paramsDict, options: JSONSerialization.WritingOptions(rawValue: 0))
        let ctyData = "{\"cty\":\"\(cty!)\",".data(using: String.Encoding.utf8)
        jsonData.replaceSubrange(jsonData.startIndex..<jsonData.startIndex+1, with: ctyData!)

        return jsonData.base64URLencoded()
    }
}
