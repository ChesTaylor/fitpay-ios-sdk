import Foundation

@objcMembers open class ResetDeviceResult: NSObject, Serializable {
    
    open var resetId: String?
    open var status: DeviceResetStatus?
    open var seStatus: DeviceResetStatus?

    open var deviceResetUrl: String? {
        return links?[ResetDeviceResult.selfResourceKey]?.href
    }
    
    var links: [String: Link]?

    private static let selfResourceKey = "self"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case resetId
        case status
        case seStatus
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try? container.decode(.links)
        resetId = try? container.decode(.resetId)
        status = try? container.decode(.status)
        seStatus = try? container.decode(.seStatus)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encodeIfPresent(links, forKey: .links)
        try? container.encode(resetId, forKey: .resetId)
        try? container.encode(status, forKey: .status)
        try? container.encode(seStatus, forKey: .seStatus)
    }
}
