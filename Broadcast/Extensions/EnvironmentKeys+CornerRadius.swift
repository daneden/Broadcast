//
//  EnvironmentKeys+CornerRadius.swift
//  Broadcast
//
//  Created by Daniel Eden on 13/02/2022.
//

import Foundation
import SwiftUI

struct CornerRadiusKey: EnvironmentKey {
  static let defaultValue: Double = 12
}

extension EnvironmentValues {
  var cornerRadius: Double {
    get { self[CornerRadiusKey.self] }
    set { self[CornerRadiusKey.self] = newValue }
  }
}
