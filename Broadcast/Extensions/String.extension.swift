//
//  String.extension.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation

extension String {
  var isBlank: Bool {
    return allSatisfy({ $0.isWhitespace })
  }
}
