import Foundation

@objcMembers open class Link: NSObject, Serializable {
    open var href: String
    open var templated: Bool?
    
    open func setTemplated(_templated: Bool) {
        templated = _templated
    }
    
    open var getTemplated: Bool {
        if templated == true {
            return true
        }
        return false
    }
}
