//
//  BroadcastButtonStyle.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI
import CoreHaptics

struct BroadcastLabelStyle: LabelStyle {
  enum Appearance {
    case iconOnly, normal
  }
  
  var appearance: Appearance = .normal
  var accessibilityLabel: String
  
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .firstTextBaseline) {
      configuration.icon
      if appearance == .normal {
        configuration.title
          .accessibility(hidden: true)
      }
    }.accessibilityLabel(accessibilityLabel)
  }
}

struct BroadcastButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled
  
  enum Prominence {
    case primary, secondary, tertiary, destructive
  }
  
  @ScaledMetric var paddingSize: CGFloat = 16
  var prominence: Prominence = .primary
  var isFullWidth = true
  var isLoading = false
  
  var background: some View {
    Group {
      switch prominence {
      case .primary:
        Color.accentColor
      case .secondary:
        Color.accentColor.opacity(0.1).background(.ultraThinMaterial)
      case .tertiary:
        Color.clear.background(.ultraThinMaterial)
      case .destructive:
        Color.red
      }
    }
  }
  
  var foregroundColor: Color {
    switch prominence {
    case .secondary:
      return .accentColor
    case .tertiary:
      return isEnabled ? .primary : .secondary
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
    .background(background.padding(-paddingSize))
    .background(.regularMaterial)
    .foregroundStyle(foregroundColor)
    .overlay(
      Group {
        if isLoading {
          ProgressView().tint(foregroundColor)
        }
      }
    )
    .clipShape(RoundedRectangle(cornerRadius: 100, style: .continuous))
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
