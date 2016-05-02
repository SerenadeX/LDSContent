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

public class RelatedContentItem: Equatable {
    
    public var id: Int64
    public var subitemID: Int64
    public var refID: String
    public var labelHTML: String
    public var originID: String
    public var contentHTML: String
    public var wordOffset: Int
    public var byteLocation: Int
    
    public init(id: Int64, subitemID: Int64, refID: String, labelHTML: String, originID: String, contentHTML: String, wordOffset: Int, byteLocation: Int) {
        self.id = id
        self.subitemID = subitemID
        self.refID = refID
        self.labelHTML = labelHTML
        self.originID = originID
        self.contentHTML = contentHTML
        self.wordOffset = wordOffset
        self.byteLocation = byteLocation
    }
    
}

public func == (lhs: RelatedContentItem, rhs: RelatedContentItem) -> Bool {
    return lhs.id == rhs.id &&
        lhs.subitemID == rhs.subitemID &&
        lhs.refID == rhs.refID &&
        lhs.labelHTML == rhs.labelHTML &&
        lhs.originID == rhs.originID &&
        lhs.contentHTML == rhs.contentHTML &&
        lhs.wordOffset == rhs.wordOffset &&
        lhs.byteLocation == rhs.byteLocation
}
