//
//  Conversation.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/24/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import CoreData
import UIKit

public class Conversation : NSManagedObject, Identifiable{
    @NSManaged public var activeParticipants   : Set<Person>
    @NSManaged public var myDescription        : String
    @NSManaged public var id                   : Int
    @NSManaged public var messages             : Set<Message>
    @NSManaged public var latestMessage        : Message
    @NSManaged public var color                : UIColor

    static func getAllConversations() -> NSFetchRequest<Conversation> {
        let request : NSFetchRequest<Conversation> = Conversation.fetchRequest() as! NSFetchRequest<Conversation>
        request.sortDescriptors = [NSSortDescriptor(key: "latestMessage.timeStamp", ascending: false)]
        return request
    }
}


///// A value transformer which transforms `UIColor` instances into data using `NSSecureCoding`.
//@objc(UIColorValueTransformer)
//public final class UIColorValueTransformer: ValueTransformer {
//    override public func transformedValue(_ value: Any?) -> Any? {
//            guard let color = value as? UIColor else { return nil }
//
//            do {
//                let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
//                return data
//            } catch {
//                assertionFailure("Failed to transform `UIColor` to `Data`")
//                return nil
//            }
//        }
//
//        override public func reverseTransformedValue(_ value: Any?) -> Any? {
//            guard let data = value as? NSData else { return nil }
//
//            do {
//                let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data as Data)
//                return color
//            } catch {
//                assertionFailure("Failed to transform `Data` to `UIColor`")
//                return nil
//            }
//        }
//
//    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
//        static let name = NSValueTransformerName(rawValue: String(describing: UIColorValueTransformer.self))
//
//        /// Registers the value transformer with `ValueTransformer`.
//        public static func register() {
//            let transformer = UIColorValueTransformer()
//            ValueTransformer.setValueTransformer(transformer, forName: name)
//        }
//}


// 1. Subclass from `NSSecureUnarchiveFromDataTransformer`
@objc(UIColorValueTransformer)
final class ColorValueTransformer: NSSecureUnarchiveFromDataTransformer {

    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: ColorValueTransformer.self))

    // 2. Make sure `UIColor` is in the allowed class list.
    override static var allowedTopLevelClasses: [AnyClass] {
        return [UIColor.self]
    }

    /// Registers the transformer.
    public static func register() {
        let transformer = ColorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
