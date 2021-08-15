//
//  TestUtils.swift
//  Broadcast
//
//  Created by Daniel Eden on 15/08/2021.
//

import Foundation

var isTestEnvironment: Bool {
  ProcessInfo.processInfo.arguments.contains("isTestEnvironment")
}
