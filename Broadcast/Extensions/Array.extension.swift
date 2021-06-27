//
//  Array.extension.swift
//  Broadcast
//
//  Created by Daniel Eden on 27/06/2021.
//

import Foundation

extension Array {
  func randomElement() -> Element {
    return self[Int.random(in: 0...(count-1))]
  }
}
