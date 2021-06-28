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
  var prominence: BroadcastButtonProminence = .primary
  var isFullWidth = true
  var isLoading = false
  
  @State private var engine: CHHapticEngine?
  
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
    .onAppear { prepareHaptics() }
    .onChange(of: configuration.isPressed) { isPressed in
      guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
      var events = [CHHapticEvent]()
      
      let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: isPressed ? 0.8 : 0.4)
      let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: isPressed ? 1 : 0.7)
      let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
      events.append(event)
      
      do {
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine?.makePlayer(with: pattern)
        try player?.start(atTime: 0)
      } catch {
        print("Failed to play pattern: \(error.localizedDescription).")
      }
    }
  }
  
  func prepareHaptics() {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
    
    do {
      self.engine = try CHHapticEngine()
      try engine?.start()
    } catch {
      print("There was an error creating the engine: \(error.localizedDescription)")
    }
  }
}
