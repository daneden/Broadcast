//
//  ParameterStringParser.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation

extension String {
  var urlQueryItems: [URLQueryItem]? {
    URLComponents(string: "://?\(self)")?.queryItems
  }
}

extension Array where Element == URLQueryItem {
  func value(for name: String) -> String? {
    return self.filter({$0.name == name}).first?.value
  }
  
  subscript(name: String) -> String? {
    return value(for: name)
  }
}
