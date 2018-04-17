//
//  Issuers.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 15.06.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import Foundation

open class Issuers: Serializable, ClientModel {
    internal var links:[ResourceLink]?
    
    weak var client: RestClient?
    
    public var countries: [String:Country]?

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case countries = "countries"
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        countries = try container.decode(.countries)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(links, forKey: .links)
        try container.encode(countries, forKey: .countries)
    }
    
    public struct Country: Serializable {
        public var cardNetworks: [String: CardNetwork]?

    }
    
    public struct CardNetwork: Serializable {
        public var issuers: [String]?
    }
}
