//
//  SerializableExtension.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 4/11/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//

public protocol Serializable: Codable {
      func toJSON() -> [String: Any]?
      func toJSONString() -> String?
      init(_ any: Any?) throws
}

extension Serializable {
    public func toJSONString() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        return String(data: jsonData, encoding: .utf8)!
    }

    public func toJSON() -> [String: Any]? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options : .allowFragments) as! [String: Any]
        return jsonDictionary
    }

    public init(_ any: Any?) throws {
        var data =  Data()
        
        if let stringJson = any as? String, let stringData = stringJson.data(using: .utf8) {
            let jsonArray = try JSONSerialization.jsonObject(with: stringData, options : .allowFragments) as! [String: Any]
            data = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
        } else if let jSONObject = any {
            let jSONObjectData = try JSONSerialization.data(withJSONObject: jSONObject, options: .prettyPrinted)
            data = jSONObjectData
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

public protocol DecodingContainerTransformer {
    associatedtype Input
    associatedtype Output
    func transform(_ decoded: Input?) -> Output?
}

public protocol EncodingContainerTransformer {
    associatedtype Input
    associatedtype Output
    func transform(_ encoded: Output?) -> Input?
}

public typealias CodingContainerTransformer = DecodingContainerTransformer & EncodingContainerTransformer
