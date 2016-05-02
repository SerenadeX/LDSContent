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

public class MutableItemPackage: ItemPackage {
    
    public init(path: NSURL, iso639_1Code: String, iso639_3Code: String) throws {
        try super.init(path: path)
        
        try createDatabaseTables(iso639_1Code: iso639_1Code)
        
        self.iso639_3Code = iso639_3Code
    }
    
    private func createDatabaseTables(iso639_1Code iso639_1Code: String) throws {
        try db.transaction {
            if !self.db.tableExists("metadata") {
                if let sqlPath = NSBundle(forClass: self.dynamicType).pathForResource("ItemPackage", ofType: "sql") {
                    let sql = String(format: try String(contentsOfFile: sqlPath, encoding: NSUTF8StringEncoding), iso639_1Code)
                    try self.db.execute(sql)
                } else {
                    throw Error.errorWithCode(.Unknown, failureReason: "Unable to locate SQL for item package.")
                }
            }
        }
    }
    
    public override var schemaVersion: Int {
        get {
            return super.schemaVersion
        }
        set {
            setInt(Int64(newValue), forMetadataKey: "schemaVersion")
        }
    }
    
    public override var itemPackageVersion: Int {
        get {
            return super.itemPackageVersion
        }
        set {
            setInt(Int64(newValue), forMetadataKey: "itemPackageVersion")
        }
    }
    
    public override var iso639_3Code: String? {
        get {
            return super.iso639_3Code
        }
        set {
            setString(newValue, forMetadataKey: "iso639_3")
        }
    }
    
    public override var uri: String? {
        get {
            return super.uri
        }
        set {
            setString(newValue, forMetadataKey: "uri")
        }
    }
    
    public override var itemID: Int64? {
        get {
            return super.itemID
        }
        set {
            setInt(newValue, forMetadataKey: "item_id")
        }
    }
    
    public override var itemExternalID: String? {
        get {
            return super.itemExternalID
        }
        set {
            setString(newValue, forMetadataKey: "item_external_id")
        }
    }
    
    public func vacuum() throws {
        try db.execute("VACUUM")
    }
    
}

extension MutableItemPackage {
    
    func setInt(integerValue: Int64?, forMetadataKey key: String) {
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

extension MutableItemPackage {
    
    public func addSubitemWithURI(uri: String, docID: String, docVersion: Int, position: Int, titleHTML: String, title: String, webURL: NSURL, contentType: ContentType = .Default) throws -> Subitem {
        let id = try db.run(SubitemTable.table.insert(
            SubitemTable.uri <- uri,
            SubitemTable.docID <- docID,
            SubitemTable.docVersion <- docVersion,
            SubitemTable.position <- position,
            SubitemTable.titleHTML <- titleHTML,
            SubitemTable.title <- title,
            SubitemTable.webURL <- webURL.absoluteString,
            SubitemTable.contentType <- contentType
        ))
        
        return Subitem(id: id, uri: uri, docID: docID, docVersion: docVersion, position: position, titleHTML: titleHTML, title: title, webURL: webURL, contentType: contentType)
    }
    
    public func addSubitemContentWithSubitemID(subitemID: Int64, contentHTML: NSData) throws -> SubitemContent {
        let id = try db.run(SubitemContentVirtualTable.table.insert(
            SubitemContentVirtualTable.subitemID <- subitemID,
            SubitemContentVirtualTable.contentHTML <- contentHTML
        ))
        
        return SubitemContent(id: id, subitemID: subitemID, contentHTML: contentHTML)
    }

    public func addRelatedContentItemWithSubitemID(subitemID: Int64, refID: String, labelHTML: String, originID: String, contentHTML: String, wordOffset: Int, byteLocation: Int) throws -> RelatedContentItem {
        let id = try db.run(RelatedContentItemTable.table.insert(
            RelatedContentItemTable.subitemID <- subitemID,
            RelatedContentItemTable.refID <- refID,
            RelatedContentItemTable.labelHTML <- labelHTML,
            RelatedContentItemTable.originID <- originID,
            RelatedContentItemTable.contentHTML <- contentHTML,
            RelatedContentItemTable.wordOffset <- wordOffset,
            RelatedContentItemTable.byteLocation <- byteLocation
        ))
        
        return RelatedContentItem(id: id, subitemID: subitemID, refID: refID, labelHTML: labelHTML, originID: originID, contentHTML: contentHTML, wordOffset: wordOffset, byteLocation: byteLocation)
    }
    
    public func addRelatedAudioItemWithSubitemID(subitemID: Int64, mediaURL: NSURL, fileSize: Int, duration: Int) throws -> RelatedAudioItem {
        let id = try db.run(RelatedAudioItemTable.table.insert(
            RelatedAudioItemTable.subitemID <- subitemID,
            RelatedAudioItemTable.mediaURL <- mediaURL.absoluteString,
            RelatedAudioItemTable.fileSize <- fileSize,
            RelatedAudioItemTable.duration <- duration
        ))
        
        return RelatedAudioItem(id: id, subitemID: subitemID, mediaURL: mediaURL, fileSize: fileSize, duration: duration)
    }
    
    public func addNavCollectionWithNavSectionID(navSectionID: Int64?, position: Int, imageRenditions: [ImageRendition], titleHTML: String, subtitle: String?, uri: String) throws -> NavCollection {
        let id = try db.run(NavCollectionTable.table.insert(
            NavCollectionTable.navSectionID <- navSectionID,
            NavCollectionTable.position <- position,
            NavCollectionTable.imageRenditions <- String(imageRenditions),
            NavCollectionTable.titleHTML <- titleHTML,
            NavCollectionTable.subtitle <- subtitle,
            NavCollectionTable.uri <- uri
        ))
        
        return NavCollection(id: id, navSectionID: navSectionID, position: position, imageRenditions: imageRenditions, titleHTML: titleHTML, subtitle: subtitle, uri: uri)
    }

    public func addNavCollectionIndexEntryWithNavCollectionID(navCollectionID: Int64, position: Int, title: String, refNavCollectionID: Int64?, refNavItemID: Int64?) throws -> NavCollectionIndexEntry {
        let id = try db.run(NavCollectionIndexEntryTable.table.insert(
            NavCollectionIndexEntryTable.navCollectionID <- navCollectionID,
            NavCollectionIndexEntryTable.position <- position,
            NavCollectionIndexEntryTable.title <- title,
            NavCollectionIndexEntryTable.refNavCollectionID <- refNavCollectionID,
            NavCollectionIndexEntryTable.refNavItemID <- refNavItemID
        ))
        
        return NavCollectionIndexEntry(id: id, navCollectionID: navCollectionID, position: position, title: title, refNavCollectionID: refNavCollectionID, refNavItemID: refNavItemID)
    }
    
    public func addNavSectionWithNavCollectionID(navCollectionID: Int64, position: Int, title: String?, indentLevel: Int) throws -> NavSection {
        let id = try db.run(NavSectionTable.table.insert(
            NavSectionTable.navCollectionID <- navCollectionID,
            NavSectionTable.position <- position,
            NavSectionTable.indentLevel <- indentLevel,
            NavSectionTable.title <- title
        ))
        
        return NavSection(id: id, navCollectionID: navCollectionID, position: position, indentLevel: indentLevel, title: title)
    }
    
    public func addNavItemWithNavSectionID(navSectionID: Int64, position: Int, imageRenditions: [ImageRendition], titleHTML: String, subtitle: String?, preview: String?, uri: String, subitemID: Int64) throws -> NavItem {
        let id = try db.run(NavItemTable.table.insert(
            NavItemTable.navSectionID <- navSectionID,
            NavItemTable.position <- position,
            NavItemTable.imageRenditions <- String(imageRenditions),
            NavItemTable.titleHTML <- titleHTML,
            NavItemTable.subtitle <- subtitle,
            NavItemTable.preview <- preview,
            NavItemTable.uri <- uri,
            NavItemTable.subitemID <- subitemID
        ))
        
        return NavItem(id: id, navSectionID: navSectionID, position: position, imageRenditions: imageRenditions, titleHTML: titleHTML, subtitle: subtitle, preview: preview, uri: uri, subitemID: subitemID)
    }
    
    public func addParagraphMetadata(paragraphID paragraphID: String, paragraphAID: String, subitemID: Int64, verseNumber: String?, range: NSRange) throws {
        try db.run(ParagraphMetadataTable.table.insert(
            ParagraphMetadataTable.subitemID <- subitemID,
            ParagraphMetadataTable.paragraphID <- paragraphID,
            ParagraphMetadataTable.paragraphAID <- paragraphAID,
            ParagraphMetadataTable.verseNumber <- verseNumber,
            ParagraphMetadataTable.startIndex <- range.location,
            ParagraphMetadataTable.endIndex <- range.location + range.length
        ))
    }
    
    public func addAuthor(givenName givenName: String, familyName: String) throws -> Author {
        if let author = authorWithGivenName(givenName, familyName: familyName) {
            return author
        }
        
        let id = try db.run(AuthorTable.table.insert(or: .Ignore,
            AuthorTable.givenName <- givenName,
            AuthorTable.familyName <- familyName
        ))
        return Author(id: id, givenName: givenName, familyName: familyName)
    }
    
    public func addRole(name name: String, position: Int) throws -> Role {
        if let role = roleWithName(name) {
            return role
        }
        
        let id = try db.run(RoleTable.table.insert(or: .Ignore,
            RoleTable.name <- name,
            RoleTable.position <- position
        ))
        return Role(id: id, name: name, position: position)
    }
    
    public func addAuthorRole(author author: Author, role: Role, position: Int) throws -> AuthorRole {
        let id = try db.run(AuthorRoleTable.table.insert(or: .Ignore,
            AuthorRoleTable.authorID <- author.id,
            AuthorRoleTable.roleID <- role.id,
            AuthorRoleTable.position <- position
        ))
        return AuthorRole(id: id, authorID: author.id, roleID: role.id, position: position)
    }
    
    public func addSubitemAuthor(subitem: Subitem, author: Author) throws {
        try db.run(SubitemAuthorTable.table.insert(or: .Ignore,
            SubitemAuthorTable.subitemID <- subitem.id,
            SubitemAuthorTable.authorID <- author.id
        ))
    }
    
    public func addTopic(name: String) throws -> Topic {
        if let topic = topicWithName(name) {
            return topic
        }
        
        let id = try db.run(TopicTable.table.insert(
            TopicTable.name <- name
        ))
        return Topic(id: id, name: name)
    }
    
    public func addSubitemTopic(subitem: Subitem, topic: Topic) throws {
        try db.run(SubitemTopicTable.table.insert(or: .Ignore,
            SubitemTopicTable.subitemID <- subitem.id,
            SubitemTopicTable.topicID <- topic.id
        ))
    }
    
}
