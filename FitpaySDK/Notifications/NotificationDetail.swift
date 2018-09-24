import Foundation

import Alamofire

/// Notification model parsed from push notification
///
/// Equivalent to SyncInfo in Android
open class NotificationDetail: Serializable, ClientModel {
    
    open var type: String?
    open var syncId: String?
    open var deviceId: String?
    open var userId: String?
    open var clientId: String?
    open var creditCardId: String?
    
    weak var client: RestClient?
    var links: [ResourceLink]?
    
    private let creditCardResourceKey = "creditCard"
    private let deviceResourceKey = "device"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case type
        case id
        case syncId
        case deviceId
        case userId
        case clientId
        case creditCardId
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        type = try? container.decode(.type)
        
        syncId = try? container.decode(.syncId)
        if (syncId == nil) { // for old notifications syncId comes through as id
            syncId = try? container.decode(.id)
        }
        
        deviceId = try? container.decode(.deviceId)
        userId = try? container.decode(.userId)
        clientId = try? container.decode(.clientId)
        creditCardId = try? container.decode(.creditCardId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(type, forKey: .type)
        try? container.encode(syncId, forKey: .syncId)
        try? container.encode(deviceId, forKey: .deviceId)
        try? container.encode(userId, forKey: .userId)
        try? container.encode(clientId, forKey: .clientId)
        try? container.encode(creditCardId, forKey: .creditCardId)
    }
    
    // MARK: - Public Functions

    open func sendAckSync() {
        guard let ackSyncUrl = self.links?.url("ackSync") else {
            log.error("SYNC_ACKNOWLEDGMENT: trying to send ackSync without URL.")
            return
        }

        guard let client = self.client else {
            log.error("SYNC_ACKNOWLEDGMENT: trying to send ackSync without rest client.")
            return
        }
        
        client.acknowledge(ackSyncUrl) { error in
            if let error = error {
                log.error("SYNC_ACKNOWLEDGMENT: ackSync failed to send. Error: \(error)")
                
            } else if let syncId = self.syncId {
                log.debug("SYNC_ACKNOWLEDGMENT: ackSync has been sent successfully. syncId: \(syncId)")
            }
        }
    }
    
    open func getCreditCard(completion: @escaping RestClient.CreditCardHandler) {
        guard let creditCardUrl = self.links?.url(creditCardResourceKey) else {
            log.error("GET_CREDIT_CARD: trying to get credit card without URL.")
            return
        }
        
        guard let client = self.client else {
            log.error("GET_CREDIT_CARD: trying to get credit card without rest client.")
            return
        }

        client.getCreditCard(creditCardUrl, completion: completion)
    }
    
    open func getDevice(completion: @escaping RestClient.DeviceHandler) {
        guard let deviceUrl = self.links?.url(deviceResourceKey) else {
            log.error("GET_DEVICE: trying to get device without URL.")
            return
        }
        
        guard let client = self.client else {
            log.error("GET_DEVICE: trying to get device without rest client.")
            return
        }
        
        client.getDevice(deviceUrl, completion: completion)
    }

}
