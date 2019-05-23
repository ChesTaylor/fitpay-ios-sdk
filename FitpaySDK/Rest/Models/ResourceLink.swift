import Foundation

@objcMembers open class ResourceLink: NSObject {
    open var target: String?
    open var href: String?
    
    override open var description: String {
        return "\(ResourceLink.self)(\(target ?? "target nil"):\(href ?? "href nil"))"
    }
    
    // MARK: - Lifecycle
    
    init(target: String, href: String?) {
        self.target = target
        self.href = href
    }
    
}
