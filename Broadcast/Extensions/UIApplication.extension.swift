//
//  UIApplication.extension.swift
//  Broadcast
//
//  Created by Daniel Eden on 27/06/2021.
//

import Foundation
import UIKit

extension UIApplication {
  func endEditing() {
    sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
