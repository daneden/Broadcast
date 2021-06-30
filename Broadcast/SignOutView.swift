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
          if let profileImageURL = twitterClient.user?.profileImageURL {
            RemoteImage(url: profileImageURL, placeholder: { ProgressView() })
              .cornerRadius(size)
          } else {
            Image("person")
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
            Haptics.shared.sendStandardFeedback(feedbackType: .success)
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
    .onChange(of: willDelete) { willDelete in
      let v: Float = willDelete ? 1 : 0.3
      Haptics.shared.sendFeedback(intensity: v, sharpness: v)
    }.accentColor(themeHelper.color)
  }
  
  func startSignOut() {
    twitterClient.signOut()
    presentationMode.wrappedValue.dismiss()
  }
}

struct SignOutView_Previews: PreviewProvider {
    static var previews: some View {
        SignOutView()
    }
}
