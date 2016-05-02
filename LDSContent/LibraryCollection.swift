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

public class LibraryCollection: LibraryNode, Equatable {
    
    public var id: Int64
    public var externalID: String
    public var librarySectionID: Int64?
    public var librarySectionExternalID: String?
    public var position: Int
    public var title: String
    public var coverRenditions: [ImageRendition]
    public var type: LibraryCollectionType
    
    public init(id: Int64, externalID: String, librarySectionID: Int64?, librarySectionExternalID: String?, position: Int, title: String, coverRenditions: [ImageRendition], type: LibraryCollectionType) {
        self.id = id
        self.externalID = externalID
        self.librarySectionID = librarySectionID
        self.librarySectionExternalID = librarySectionExternalID
        self.position = position
        self.title = title
        self.coverRenditions = coverRenditions
        self.type = type
    }

}

public func == (lhs: LibraryCollection, rhs: LibraryCollection) -> Bool {
    return lhs.id == rhs.id &&
        lhs.externalID == rhs.externalID &&
        lhs.librarySectionID == rhs.librarySectionID &&
        lhs.librarySectionExternalID == rhs.librarySectionExternalID &&
        lhs.position == rhs.position &&
        lhs.title == rhs.title &&
        lhs.coverRenditions == rhs.coverRenditions &&
        lhs.type == rhs.type
}
