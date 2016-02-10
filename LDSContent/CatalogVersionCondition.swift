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
import PSOperations

class CatalogVersionCondition: OperationCondition {
    
    static let name = "CatalogVersion"
    static let isMutuallyExclusive = false
    
    let session: Session
    var catalogVersion: Int?
    let completion: (CatalogVersionCondition) -> Void
    
    init(session: Session, catalogVersion: Int?, completion: (CatalogVersionCondition) -> Void) {
        self.session = session
        self.catalogVersion = catalogVersion
        self.completion = completion
    }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        if catalogVersion == nil {
            return FetchCatalogVersionOperation(session: session, completion: { result in
                switch result {
                case let .Success(catalogVersion):
                    self.catalogVersion = catalogVersion
                case .Error(_):
                    break
                }
                
                self.completion(self)
            })
        } else {
            return nil
        }
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if catalogVersion != nil {
            completion(.Satisfied)
        } else {
            completion(.Failed(NSError(code: .ConditionFailed, userInfo: [
                OperationConditionKey: self.dynamicType.name
            ])))
        }
    }
    
}
