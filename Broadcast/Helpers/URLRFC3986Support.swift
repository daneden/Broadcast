//
//  URLRFC3986Support.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation

extension CharacterSet {
  static var urlRFC3986Allowed: CharacterSet {
    CharacterSet(charactersIn: "-_.~").union(.alphanumerics)
  }
}

extension String {
  var oAuthURLEncodedString: String {
    self.addingPercentEncoding(withAllowedCharacters: .urlRFC3986Allowed) ?? self
  }
}
