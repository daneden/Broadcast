//
//  BroadcastButtonStyle.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

enum BroadcastButtonProminence {
  case primary, secondary
}

struct BroadcastButtonStyle: ButtonStyle {
  var prominence: BroadcastButtonProminence = .primary
  var isFullWidth = true
  var isLoading = false
  
  var backgroundColor: Color {
    switch prominence {
    case .primary:
      return .accentColor
    case .secondary:
      return .accentColor.opacity(0.1)
    }
  }
  
  var foregroundColor: Color {
    switch prominence {
    case .primary:
      return .white
    case .secondary:
      return .accentColor
    }
  }
  
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      if isFullWidth { Spacer(minLength: 0) }
      configuration.label
        .opacity(configuration.isPressed ? 0.8 : 1)
        .opacity(isLoading ? 0 : 1)
      if isFullWidth { Spacer(minLength: 0) }
    }
    .padding()
    .background(backgroundColor)
    .foregroundColor(foregroundColor)
    .overlay(
      Group {
        if isLoading {
          ProgressView()
        }
      }
    )
    .clipShape(Capsule())
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
    .animation(.interactiveSpring(), value: configuration.isPressed)
  }
}
