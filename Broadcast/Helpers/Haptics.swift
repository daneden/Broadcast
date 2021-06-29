//
//  Haptics.swift
//  Broadcast
//
//  Created by Daniel Eden on 29/06/2021.
//

import Foundation
import CoreHaptics
import UIKit

class Haptics {
  private var engine: CHHapticEngine?
  static let shared = Haptics()
  
  static var isSupported: Bool {
    CHHapticEngine.capabilitiesForHardware().supportsHaptics
  }
  
  deinit {
    engine?.stop()
  }
  
  func sendFeedback(intensity: Float, sharpness: Float) {
    guard Haptics.isSupported else { return }
    
    do {
      try engine = CHHapticEngine()
      try engine?.start()
    } catch let error {
      print(error.localizedDescription)
    }
    
    var events = [CHHapticEvent]()
    
    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
    let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
    let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
    events.append(event)
    
    do {
      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try engine?.makePlayer(with: pattern)
      try player?.start(atTime: 0)
    } catch {
      print("Failed to play pattern: \(error.localizedDescription).")
    }
    
    engine?.stop()
  }
  
  func sendStandardFeedback(feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(feedbackType)
  }
}
