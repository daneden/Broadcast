//
//  WelcomeView.swift
//  Broadcast
//
//  Created by Daniel Eden on 27/06/2021.
//

import SwiftUI

struct WelcomeView: View {
  @EnvironmentObject var themeHelper: ThemeHelper
  @ScaledMetric var spacing: CGFloat = 24
  
  @State var rotation: Double = -3
  
  var animation = Animation.interactiveSpring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.4)
  
  var body: some View {
    VStack(alignment: .leading, spacing: spacing) {
      Spacer()
      
      HStack {
        Spacer()
        Label("Broadcast", systemImage: "exclamationmark.bubble.fill")
          .font(.broadcastLargeTitle.weight(.heavy))
          .foregroundColor(.white)
          .rotationEffect(Angle(degrees: rotation))
          .padding()
          .background(
            RoundedRectangle(cornerRadius: spacing, style: .continuous)
              .rotation(Angle(degrees: rotation / 2))
              .fill(Color.accentColor)
          )
          .onTapGesture {
            themeHelper.rotateTheme()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation(animation) {
              rotation = Double.random(in: -7...7)
            }
          }
        Spacer()
      }
      
      Spacer()
      
      Group {
        Text("Broadcast is a Twitter app like no other: it’s write-only.")
          .rotationEffect(Angle(degrees: rotation * 0.125))
        Text("No notifications, likes, retweets, ads, replies, sliding-into-DMs, lists—not even a timeline.")
          .rotationEffect(Angle(degrees: rotation * -0.2))
        Text("Tweet like nobody’s watching.")
          .rotationEffect(Angle(degrees: rotation * 0.3))
      }.font(.broadcastTitle.bold())
      
      Spacer()
    }
  }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
