import Foundation

@objcMembers open class Link: NSObject, Serializable {
    open var href: String
    open var templated: Bool?
}
