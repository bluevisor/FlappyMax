//
//  FlappyMaxUITests.swift
//  FlappyMaxUITests
//
//  Created by John Zheng on 10/31/24.
//

import XCTest

final class FlappyMaxUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }

    @MainActor
    func testGameInteractions() throws {
        // Wait for the game to be ready
        let gameWindow = app.windows.firstMatch
        XCTAssertTrue(gameWindow.exists)
        
        // Initial tap to start the game
        gameWindow.tap()
        
        // Wait briefly to ensure game has started
        Thread.sleep(forTimeInterval: 1.0)
        
        // Multiple taps to simulate gameplay
        for _ in 0..<3 {
            gameWindow.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
