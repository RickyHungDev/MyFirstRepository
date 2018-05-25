//
//  BuyList+CoreDataProperties.swift
//  ToBuy
//
//  Created by Hung Ricky on 2018/5/17.
//
//

import Foundation
import CoreData


extension BuyList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BuyList> {
        return NSFetchRequest<BuyList>(entityName: "BuyList")
    }

    @NSManaged public var id: NSNumber?
    @NSManaged public var seq: NSNumber?
    @NSManaged public var itemname: String?
    @NSManaged public var remark: String?
    @NSManaged public var done: NSNumber?

}
