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

public class LibrarySection: Equatable {
    
    public var id: Int64
    public var externalID: String
    public var libraryCollectionID: Int64
    public var libraryCollectionExternalID: String
    public var position: Int
    public var title: String?
    public var indexTitle: String?
    
    public init(id: Int64, externalID: String, libraryCollectionID: Int64, libraryCollectionExternalID: String, position: Int, title: String?, indexTitle: String?) {
        self.id = id
        self.externalID = externalID
        self.libraryCollectionID = libraryCollectionID
        self.libraryCollectionExternalID = libraryCollectionExternalID
        self.position = position
        self.title = title
        self.indexTitle = indexTitle
    }

}

public func == (lhs: LibrarySection, rhs: LibrarySection) -> Bool {
    return lhs.id == rhs.id &&
        lhs.externalID == rhs.externalID &&
        lhs.libraryCollectionID == rhs.libraryCollectionID &&
        lhs.libraryCollectionExternalID == rhs.libraryCollectionExternalID &&
        lhs.position == rhs.position &&
        lhs.title == rhs.title &&
        lhs.indexTitle == rhs.indexTitle
}
