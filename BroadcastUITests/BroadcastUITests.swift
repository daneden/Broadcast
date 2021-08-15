//
//  BroadcastUITests.swift
//  BroadcastUITests
//
//  Created by Daniel Eden on 15/08/2021.
//

import XCTest

class BroadcastUITests: XCTestCase {
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testKeyElementsExist() throws {
    let app = XCUIApplication()
    app.launchArguments = ["isTestEnvironment"]
    app.launch()
    
    let sendTweet = app.buttons["sendTweetButton"]
    XCTAssert(sendTweet.exists)
    XCTAssert(!sendTweet.isEnabled)
    
    let composer = app.textViews["tweetComposer"]
    XCTAssert(composer.exists)
  }
  
  func testSendTweetButtonEnabledOnValidText() throws {
    let app = XCUIApplication()
    app.launchArguments = ["isTestEnvironment"]
    app.launch()
    
    let sendTweet = app.buttons["sendTweetButton"]
    let composer = app.textViews["tweetComposer"]
    
    composer.tap()
    UIPasteboard.general.string = "Hello, world"
    composer.press(forDuration: 1.1)
    app.menuItems["Paste"].tap()
    _ = XCTWaiter.wait(for: [expectation(description: "Wait for .5 seconds")], timeout: 0.5)
    
    XCTAssertEqual(composer.value as? String, "Hello, world")
    XCTAssert(sendTweet.isEnabled)
  }
  
  func testSendTweetButtonDisabledOnEmptyText() throws {
    let app = XCUIApplication()
    app.launchArguments = ["isTestEnvironment"]
    app.launch()
    
    let sendTweet = app.buttons["sendTweetButton"]
    let composer = app.textViews["tweetComposer"]
    
    composer.tap()
    UIPasteboard.general.string = " "
    composer.press(forDuration: 1.1)
    app.menuItems["Paste"].tap()
    _ = XCTWaiter.wait(for: [expectation(description: "Wait for .5 seconds")], timeout: 0.5)
    
    XCTAssertEqual(composer.value as? String, " ")
    XCTAssert(!sendTweet.isEnabled)
  }
  
  func testSendTweetButtonDisabledOnLargeText() throws {
    let app = XCUIApplication()
    app.launchArguments = ["isTestEnvironment"]
    app.launch()
    
    let sendTweet = app.buttons["sendTweetButton"]
    let composer = app.textViews["tweetComposer"]
    
    composer.tap()
    UIPasteboard.general.string = String(repeating: "a", count: 281)
    composer.press(forDuration: 1.1)
    app.menuItems["Paste"].tap()
    _ = XCTWaiter.wait(for: [expectation(description: "Wait for .5 seconds")], timeout: 0.5)
    
    XCTAssert(!sendTweet.isEnabled)
  }
  
  func testLogout() throws {
    let app = XCUIApplication()
    app.launchArguments = ["isTestEnvironment"]
    app.launch()
    
    let profilePhoto = app.images["profilePhotoButton"]
    profilePhoto.tap()
    
    let logoutHandle = app.descendants(matching: .any).matching(identifier: "logoutProfilePhotoHandle").firstMatch
    let logoutTarget = app.images["logoutTarget"]
    logoutHandle.press(forDuration: 0.1, thenDragTo: logoutTarget)
    
    _ = XCTWaiter.wait(for: [expectation(description: "Wait for .5 seconds")], timeout: 0.5)
    
    let loginButton = app.buttons["loginButton"]
    XCTAssert(loginButton.exists)
  }
}
