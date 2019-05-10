import Foundation

@objcMembers open class ResourceLink: NSObject {
    open var target: String?
    open var href: String?
    
    override open var description: String {
        return "\(ResourceLink.self)(\(target ?? "target nil"):\(href ?? "href nil"))"
    }
}

//extension ResourceLink: Equatable {
//    public static func == (lhs: ResourceLink, rhs: ResourceLink) -> Bool {
//        return lhs.target == rhs.target && lhs.href == rhs.href
//    }
//
//}
