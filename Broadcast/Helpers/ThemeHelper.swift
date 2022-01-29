//
//  ThemeHelper.swift
//  Broadcast
//
//  Created by Daniel Eden on 27/06/2021.
//

import Foundation
import Combine
import SwiftUI

extension Color: RawRepresentable {
  public init?(rawValue: String) {
    guard let data = Data(base64Encoded: rawValue) else{
      self = .black
      return
    }
    
    do {
      let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor ?? .black
      self = Color(color)
    }catch{
      self = .accentColor
    }
  }
  
  public var rawValue: String {
    do {
      let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false) as Data
      return data.base64EncodedString()
    } catch {
      return ""
    }
  }
}

class ThemeHelper: ObservableObject {
  static let shared = ThemeHelper()
  
  @AppStorage("themeColor") var color = Color("twitterBrandColor")
  
  @AppStorage("themeColorIndex") private var currentColorIndex = 0 {
    didSet {
      withAnimation { color = allColors[currentColorIndex] }
    }
  }
  
  private var allColors: [Color] = [
    Color("twitterBrandColor"),
    Color(.systemIndigo),
    Color(.systemPurple),
    Color(.systemPink),
    Color(.systemOrange),
    Color(.systemGreen),
    Color(.systemTeal),
  ]
  
  func rotateTheme() {
    currentColorIndex = (currentColorIndex + 1) % allColors.count
  }
}
