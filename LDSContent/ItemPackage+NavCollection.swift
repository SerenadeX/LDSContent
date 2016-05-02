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

extension ItemPackage {
    
    class NavCollectionTable {
        
        static let table = Table("nav_collection")
        static let id = Expression<Int64>("_id")
        static let navSectionID = Expression<Int64?>("nav_section_id")
        static let position = Expression<Int>("position")
        static let imageRenditions = Expression<String?>("image_renditions")
        static let titleHTML = Expression<String>("title_html")
        static let subtitle = Expression<String?>("subtitle")
        static let uri = Expression<String>("uri")
        
        static func fromRow(row: Row) -> NavCollection {
            return NavCollection(id: row[id], navSectionID: row[navSectionID], position: row[position], imageRenditions: (row[imageRenditions] ?? "").toImageRenditions() ?? [], titleHTML: row[titleHTML], subtitle: row[subtitle], uri: row[uri])
        }
        
    }
    
    public func rootNavCollection() -> NavCollection? {
        return db.pluck(NavCollectionTable.table.filter(NavCollectionTable.navSectionID == nil)).map { NavCollectionTable.fromRow($0) }
    }
    
    public func navCollectionWithID(id: Int64) -> NavCollection? {
        return db.pluck(NavCollectionTable.table.filter(NavCollectionTable.id == id)).map { NavCollectionTable.fromRow($0) }
    }
    
    public func navCollectionWithURI(uri: String) -> NavCollection? {
        return db.pluck(NavCollectionTable.table.filter(NavCollectionTable.uri == uri)).map { NavCollectionTable.fromRow($0) }
    }
    
    public func navCollectionExistsWithURI(uri: String) -> Bool {
        return db.scalar(NavCollectionTable.table.filter(NavCollectionTable.uri == uri).count) > 0
    }
    
    public func navCollectionsForNavSectionWithID(navSectionID: Int64) -> [NavCollection] {
        do {
            return try db.prepare(NavCollectionTable.table.filter(NavCollectionTable.navSectionID == navSectionID).order(NavCollectionTable.position)).map { NavCollectionTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func navCollectionsFromURI(uri: String?) -> [NavCollection] {
        guard let uri = uri else {
            guard let rootNavCollection = rootNavCollection() else { return [] }
            return [rootNavCollection]
        }
        
        var collection: NavCollection?
        if let navItem = navItemWithURI(uri), navSection = navSectionWithID(navItem.navSectionID), navCollection = navCollectionWithID(navSection.navCollectionID) {
            collection = navCollection
        } else if let navCollection = navCollectionWithURI(uri) {
            collection = navCollection
        } else if let navCollection = rootNavCollection() {
            collection = navCollection
        }
        
        var collections = [NavCollection]()
        
        while let navCollection = collection {
            collections.append(navCollection)
            if let sectionID = navCollection.navSectionID, navSection = navSectionWithID(sectionID) {
                collection = navCollectionWithID(navSection.navCollectionID)
            }
        }
        
        return collections
    }
    
}