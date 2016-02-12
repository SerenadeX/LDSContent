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

import XCTest

func XCTAssertNoThrow<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}

func XCTAssertNoThrowEqual<T : Equatable>(@autoclosure expression1: () throws -> T, @autoclosure _ expression2: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        let result1 = try expression1()
        let result2 = try expression2()
        XCTAssertEqual(result1, result2, message, file: file, line: line)
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}
