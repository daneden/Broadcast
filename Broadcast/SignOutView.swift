//
//  SignOutView.swift
//  Broadcast
//
//  Created by Daniel Eden on 27/06/2021.
//

import SwiftUI
import CoreHaptics

struct SignOutView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var twitterClient: TwitterClient
  @EnvironmentObject var themeHelper: ThemeHelper
  
  @State private var offset = CGSize.zero
  @State private var willDelete = false
  @State private var engine: CHHapticEngine?
  
  @ScaledMetric var size: CGFloat = 88
  
  var labelOpacity: Double {
    Double(1 - abs(offset.height) / 200)
  }
  
  var body: some View {
    VStack {
      Spacer()
      if let screenName = twitterClient.user?.screenName {
        Label("Drag to sign out @\(screenName)", systemImage: "arrow.down.circle")
          .font(.broadcastBody.bold())
          .foregroundColor(.secondary)
          .padding()
          .opacity(labelOpacity)
      }
      
      VStack {
        Group {
          if let profileImageURL = twitterClient.profileImageURL?.absoluteString {
            RemoteImage(url: profileImageURL)
              .cornerRadius(size)
          } else {
            Image("person.fill")
              .resizable()
          }
        }
          .foregroundColor(.white)
          .padding(8)
          .frame(width: size, height: size)
          .background(willDelete ? Color(.secondarySystemBackground) : .accentColor)
          .clipShape(Circle())
          .onTapGesture {
            themeHelper.rotateTheme()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
          }
        .offset(offset)
        .highPriorityGesture(
          DragGesture()
            .onChanged { gesture in
              withAnimation { self.offset.height = min(gesture.translation.height, 200 + size) }
              
              withAnimation(.interactiveSpring()) { willDelete = self.offset.height >= 200 }
            }
            
            .onEnded { _ in
              if self.offset.height >= 200 {
                startSignOut()
              } else {
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.4)) {
                  self.offset = .zero
                  willDelete = false
                }
              }
            }
        )
        
        Color.clear.frame(height: 180)
        
        Image(systemName: "trash")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .padding(size * 0.3)
          .frame(width: size, height: size)
          .background(willDelete ? Color(.systemRed) : Color(.secondarySystemBackground))
          .foregroundColor(willDelete ? .white : .primary)
          .clipShape(Circle())
      }
      Spacer()
      
      Button(action: { presentationMode.wrappedValue.dismiss() }) {
        Text("Close")
      }.buttonStyle(BroadcastButtonStyle(prominence: .tertiary))
      .opacity(labelOpacity)
    }
    .padding()
    .onAppear { prepareHaptics() }
    .onChange(of: willDelete) { willDelete in
      guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
      var events = [CHHapticEvent]()
      
      let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: willDelete ? 1 : 0.3)
      let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: willDelete ? 1 : 0.3)
      let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
      events.append(event)
      
      do {
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine?.makePlayer(with: pattern)
        try player?.start(atTime: 0)
      } catch {
        print("Failed to play pattern: \(error.localizedDescription).")
      }
    }.accentColor(themeHelper.color)
  }
  
  func startSignOut() {
    twitterClient.signOut()
    presentationMode.wrappedValue.dismiss()
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

struct SignOutView_Previews: PreviewProvider {
    static var previews: some View {
        SignOutView()
    }
}