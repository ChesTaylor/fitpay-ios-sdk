import Foundation

public enum A2AStepupResult: String, Serializable {
    case approved
    case declined
    case failure
}

public class A2AIssuerRequest: NSObject, Codable {
    private var response: A2AStepupResult?
    private var authCode: String?

    public init(response: A2AStepupResult, authCode: String?) {
        self.response = response
        self.authCode = authCode
        super.init()
    }

    public func toString() -> String? {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(self) else { return nil }
        return String(data: jsonData, encoding: .utf8)!
    }

    public func getEncodedString() -> String? {
        guard let string = toString() else { return nil }
        return Data(string.utf8).base64URLencoded()
    }
}
