import Foundation

@objc open class UserInfo: NSObject, Serializable {
    @objc open var username: String?
    @objc open var firstName: String?
    @objc open var lastName: String?
    @objc open var birthDate: String?
    @objc open var email: String?
}
