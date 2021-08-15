//
//  BroadcastUITests.swift
//  BroadcastUITests
//
//  Created by Daniel Eden on 15/08/2021.
//

import XCTest

extension XCUIApplication {
  static func initWithLaunchParameters() -> XCUIApplication {
    let instance = XCUIApplication()
    instance.launchArguments = ["isTestEnvironment"]
    
    return instance
  }
}

class BroadcastUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }
  
  func testKeyElementsExist() throws {
    let app = XCUIApplication.initWithLaunchParameters()
    app.launch()
    
    let sendTweet = app.buttons["sendTweetButton"]
    XCTAssert(sendTweet.exists)
    XCTAssert(!sendTweet.isEnabled)
    
    let composer = app.textViews["tweetComposer"]
    XCTAssert(composer.exists)
  }
  
  func testSendTweetButtonEnabledOnValidText() throws {
    let app = XCUIApplication.initWithLaunchParameters()
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
    let app = XCUIApplication.initWithLaunchParameters()
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
    let app = XCUIApplication.initWithLaunchParameters()
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
    let app = XCUIApplication.initWithLaunchParameters()
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
