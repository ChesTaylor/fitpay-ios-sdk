
import Foundation

extension NSData
{
    var UTF8String:String?
    {
        return self.stringWithEncoding(NSUTF8StringEncoding)
    }

    @inline(__always) func stringWithEncoding(encoding:NSStringEncoding) -> String?
    {
        return String(data: self, encoding: encoding)
    }

    var dictionary:Dictionary<String, AnyObject>?
    {
        guard let dictionary:[String : AnyObject] = try? NSJSONSerialization.JSONObjectWithData(self, options:.MutableContainers) as! [String : AnyObject] else
        {
            return nil
        }

        return dictionary
    }

    var errorMessages:[String]
    {
        var messages = [String]()
        if let dict:[String : AnyObject] = self.dictionary
        {
            if let errors = dict["errors"] as? [[String : String]]
            {
                for error in errors
                {
                    if let message = error["message"]
                    {
                        messages.append(message)
                    }
                }
            }
        }
        
        return messages
    }
}
