// Copyright (c) 2017 Spotify AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
@testable import SpotifyLogin

class KeychainWrapperTests: XCTestCase {

    let testKey = "key"
    let testData = "test".data(using: .utf8)!

    override func tearDown() {
        _ = KeychainWrapper.removeData(forKey: testKey)
    }

    func testThatRemovingDataBeforeSavingItFails() {
        XCTAssertFalse(KeychainWrapper.removeData(forKey: testKey))
    }

    func testThatRetrievingDataBeforeSavingItReturnsNil() {
        XCTAssertNil(KeychainWrapper.data(forKey: testKey))
    }

    func testThatRemovingDataAfterSavingItSucceeds() {
        XCTAssertTrue(KeychainWrapper.save(testData, forKey: testKey))
        XCTAssertTrue(KeychainWrapper.removeData(forKey: testKey))
    }

    func testThatRetrievingDataAfterSavingItReturnsTheData() {
        XCTAssertTrue(KeychainWrapper.save(testData, forKey: testKey))
        XCTAssertNotNil(KeychainWrapper.data(forKey: testKey))
    }

}
