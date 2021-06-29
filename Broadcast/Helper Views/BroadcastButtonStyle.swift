//
//  BroadcastButtonStyle.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI
import CoreHaptics

enum BroadcastButtonProminence {
  case primary, secondary, tertiary, destructive
}

struct BroadcastButtonStyle: ButtonStyle {
  @ScaledMetric var paddingSize: CGFloat = 16
  var prominence: BroadcastButtonProminence = .primary
  var isFullWidth = true
  var isLoading = false
  
  var backgroundColor: some View {
    Group {
      switch prominence {
      case .primary:
        Color.accentColor
      case .secondary:
        Color.accentColor.opacity(0.1)
      case .tertiary:
        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
      case .destructive:
        Color(.systemRed)
      }
    }
  }
  
  var foregroundColor: Color {
    switch prominence {
    case .secondary:
      return .accentColor
    case .tertiary:
      return .primary
    default:
      return .white
    }
  }
  
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      if isFullWidth { Spacer(minLength: 0) }
      
      configuration.label
        .font(.broadcastBody.bold())
        .opacity(configuration.isPressed ? 0.8 : 1)
        .opacity(isLoading ? 0 : 1)
      
      if isFullWidth { Spacer(minLength: 0) }
    }
    .padding(paddingSize)
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
    .onChange(of: configuration.isPressed) { isPressed in
      Haptics.shared.sendFeedback(
        intensity: isPressed ? 0.8 : 0.4,
        sharpness: isPressed ? 1 : 0.7
      )
    }
  }
}
