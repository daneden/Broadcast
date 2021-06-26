//
//  Binding.extension.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation
import SwiftUI

public extension Binding where Value: Equatable {
  init(_ source: Binding<Value?>, replacingNilWith nilProxy: Value) {
    self.init(
      get: { source.wrappedValue ?? nilProxy },
      set: { newValue in
        if newValue == nilProxy {
          source.wrappedValue = nil
        }
        else {
          source.wrappedValue = newValue
        }
      })
  }
}
