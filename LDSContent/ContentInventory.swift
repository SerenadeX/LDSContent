//
// Copyright (c) 2016 Hilton Campbell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import SQLite

class ContentInventory {
    
    let db: Connection
    
    private static let currentVersion = 1
    
    init(path: String? = nil) throws {
        print(path)
        do {
            db = try Connection(path ?? "")
        } catch {
            throw error
        }
        
        if databaseVersion < self.dynamicType.currentVersion {
            upgradeDatabaseFromVersion(databaseVersion)
        }
    }
    
    func inTransaction(closure: () throws -> Void) throws {
        let inTransactionKey = "txn:\(unsafeAddressOf(self))"
        if NSThread.currentThread().threadDictionary[inTransactionKey] != nil {
            try closure()
        } else {
            NSThread.currentThread().threadDictionary[inTransactionKey] = true
            defer { NSThread.currentThread().threadDictionary.removeObjectForKey(inTransactionKey) }
            try db.transaction {
                try closure()
            }
        }
    }
    
    var databaseVersion: Int {
        get {
            return Int(db.scalar("PRAGMA user_version") as? Int64 ?? 0)
        }
        set {
            do {
                try db.run("PRAGMA user_version = \(newValue)")
            } catch {}
        }
    }
    
    private func upgradeDatabaseFromVersion(fromVersion: Int) {
        if fromVersion < 1 {
            do {
                try inTransaction {
                    try self.db.run(MetadataTable.table.create(ifNotExists: true) { builder in
                        builder.column(MetadataTable.key, primaryKey: true)
                        builder.column(MetadataTable.stringValue)
                    })
                    
                    try self.db.run(InstalledItemTable.table.create(ifNotExists: true) { builder in
                        builder.column(InstalledItemTable.itemID, primaryKey: true)
                        builder.column(InstalledItemTable.schemaVersion)
                        builder.column(InstalledItemTable.itemPackageVersion)
                    })
                    
                    self.databaseVersion = 1
                }
            } catch {}
        }
    }
    
    var catalogVersion: Int? {
        get {
            return self.intForMetadataKey("catalogVersion")
        }
        set {
            setInt(newValue, forMetadataKey: "catalogVersion")
        }
    }
    
}

extension ContentInventory {
    
    class MetadataTable {
        
        static let table = Table("metadata")
        static let key = Expression<String>("key")
        static let integerValue = Expression<Int>("value")
        static let stringValue = Expression<String>("value")
        
    }
    
    func intForMetadataKey(key: String) -> Int? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).flatMap { row in
            let string = row[MetadataTable.stringValue]
            return Int(string)
        }
    }
    
    func stringForMetadataKey(key: String) -> String? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).map { row in
            return row[MetadataTable.stringValue]
        }
    }
    
    func setInt(integerValue: Int?, forMetadataKey key: String) {
        do {
            if let integerValue = integerValue {
                try db.run(MetadataTable.table.insert(or: .Replace, MetadataTable.key <- key, MetadataTable.integerValue <- integerValue))
            } else {
                try db.run(MetadataTable.table.filter(MetadataTable.key == key).delete())
            }
        } catch {}
    }
    
    func setString(stringValue: String?, forMetadataKey key: String) {
        do {
            if let stringValue = stringValue {
                try db.run(MetadataTable.table.insert(or: .Replace, MetadataTable.key <- key, MetadataTable.stringValue <- stringValue))
            } else {
                try db.run(MetadataTable.table.filter(MetadataTable.key == key).delete())
            }
        } catch {}
    }
    
}

extension ContentInventory {
    
    class InstalledItemTable {
        
        static let table = Table("installed_item")
        static let itemID = Expression<Int64>("item_id")
        static let schemaVersion = Expression<Int>("schema_version")
        static let itemPackageVersion = Expression<Int>("item_package_version")
        
    }
    
    func installedItemIDs() -> [Int64] {
        do {
            return try db.prepare(InstalledItemTable.table.select(InstalledItemTable.itemID)).map { $0[InstalledItemTable.itemID] }
        } catch {
            return []
        }
    }
    
    func installedVersionOfItemWithID(itemID: Int64) -> (schemaVersion: Int, itemPackageVersion: Int)? {
        return db.pluck(InstalledItemTable.table.filter(InstalledItemTable.itemID == itemID)).map { row in
            return (schemaVersion: row[InstalledItemTable.schemaVersion], itemPackageVersion: row[InstalledItemTable.itemPackageVersion])
        }
    }
    
    func isItemWithIDInstalled(itemID itemID: Int64) -> Bool {
        return db.scalar(InstalledItemTable.table.filter(InstalledItemTable.itemID == itemID).count) != 0
    }
    
    func setSchemaVersion(schemaVersion: Int, itemPackageVersion: Int, forItemWithID itemID: Int64) throws {
        try db.run(InstalledItemTable.table.insert(or: .Replace,
            InstalledItemTable.itemID <- itemID,
            InstalledItemTable.schemaVersion <- schemaVersion,
            InstalledItemTable.itemPackageVersion <- itemPackageVersion
        ))
    }
    
    func removeVersionForItemWithID(itemID: Int64) throws {
        try db.run(InstalledItemTable.table.filter(InstalledItemTable.itemID == itemID).delete())
    }

}
