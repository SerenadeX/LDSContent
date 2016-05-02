//
//  Catalog+SubitemMetadata.swift
//  Pods
//
//  Created by Stephan Heilner on 4/28/16.
//
//

import Foundation
import SQLite

public extension Catalog {
    
    class SubitemMetadataTable {
        
        static let table = Table("subitem_metadata")
        static let id = Expression<Int64>("_id")
        static let itemID = Expression<Int64>("item_id")
        static let subitemID = Expression<Int64>("subitem_id")
        static let docID = Expression<String>("doc_id")
        static let docVersion = Expression<Int>("doc_version")
        
    }
    
    public func itemAndSubitemIDForDocID(docID: String) -> (itemID: Int64, subitemID: Int64)? {
        return db.pluck(SubitemMetadataTable.table.select(SubitemMetadataTable.itemID, SubitemMetadataTable.subitemID).filter(SubitemMetadataTable.docID == docID)).map { row in
            return (itemID: row[SubitemMetadataTable.itemID], subitemID: row[SubitemMetadataTable.subitemID])
        }
    }
    
    public func subitemIDForSubitemWithDocID(docID: String, itemID: Int64) -> Int64? {
        return db.pluck(SubitemMetadataTable.table.select(SubitemMetadataTable.subitemID).filter(SubitemMetadataTable.docID == docID && SubitemMetadataTable.itemID == itemID)).map { row in
            return row[SubitemMetadataTable.subitemID]
        }
    }
    
    public func docIDForSubitemWithID(subitemID: Int64, itemID: Int64) -> String? {
        return db.pluck(SubitemMetadataTable.table.select(SubitemMetadataTable.docID).filter(SubitemMetadataTable.subitemID == subitemID && SubitemMetadataTable.itemID == itemID)).map { row in
            return row[SubitemMetadataTable.docID]
        }
    }
    
    public func versionsForDocIDs(docIDs: [String]) -> [String: Int] {
        do {
            return [String: Int](try db.prepare(SubitemMetadataTable.table.select(SubitemMetadataTable.docID, SubitemMetadataTable.docVersion).filter(docIDs.contains(SubitemMetadataTable.docID))).map { row in
                return (row[SubitemMetadataTable.docID], row[SubitemMetadataTable.docVersion])
                })
        } catch {
            return [:]
        }
    }
    
}
