//
//  NSRegularExpression+Convenience.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/08/2021.
//

import Foundation

extension NSRegularExpression {
  convenience init(_ pattern: String) {
    do {
      try self.init(pattern: pattern)
    } catch {
      preconditionFailure("Illegal regular expression: \(pattern).")
    }
  }
  
  convenience init(_ pattern: String, options: NSRegularExpression.Options) {
    do {
      try self.init(pattern: pattern, options: options)
    } catch {
      preconditionFailure("Illegal regular expression: \(pattern).")
    }
  }
}

extension NSRegularExpression {
  func matches(_ string: String) -> Bool {
    let range = NSRange(location: 0, length: string.utf16.count)
    return firstMatch(in: string, options: [], range: range) != nil
  }
  
  func firstMatchAsString(_ string: String) -> String? {
    let nsString = string as NSString
    let range = NSRange(location: 0, length: string.utf16.count)
    guard let firstMatch = firstMatch(in: string, options: [], range: range) else {
      return nil
    }
    
    return nsString.substring(with: firstMatch.range)
  }
}

extension String {
  static func ~= (lhs: String, rhs: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
    let range = NSRange(location: 0, length: lhs.utf16.count)
    return regex.firstMatch(in: lhs, options: [], range: range) != nil
  }
}
