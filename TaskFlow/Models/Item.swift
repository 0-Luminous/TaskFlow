import Foundation
import CoreData

@objc(ItemModel)
public class ItemModel: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        timestamp = Date()
    }
}

extension ItemModel {
    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \ItemModel.timestamp, ascending: true)]
    }
    
    static var defaultFetchRequest: NSFetchRequest<ItemModel> {
        let request = NSFetchRequest<ItemModel>(entityName: "Item")
        request.sortDescriptors = defaultSortDescriptors
        return request
    }
}
