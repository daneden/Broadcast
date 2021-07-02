//
//  ComposerView.swift
//  Broadcast
//
//  Created by Daniel Eden on 30/06/2021.
//

import SwiftUI
import TwitterText

fileprivate let placeholderCandidates: [String] = [
  "Wh—what’s going on?",
  "Oh hey uh, what’s up",
  "What’s Twitter?",
  "Tweet away, sweet child",
  "Say something nice",
  "Cowabunga, dude",
  "You’re doing a great job"
]

struct ComposerView: View {
  @Binding var signOutScreenIsPresented: Bool
  
  @EnvironmentObject var twitterClient: TwitterClient
  @ScaledMetric private var minComposerHeight: CGFloat = 120
  @ScaledMetric private var captionSize: CGFloat = 14
  @ScaledMetric private var leftOffset: CGFloat = 4
  @ScaledMetric private var verticalPadding: CGFloat = 6
  
  @State private var placeholder: String = placeholderCandidates.randomElement()
  
  private var tweetText: String? {
    twitterClient.draft.text
  }
  
  private var charCount: Int {
    TwitterText.tweetLength(text: tweetText ?? "")
  }
  
  private var tweetLengthWarning: String {
    switch charCount {
    case 380...479:
      return " (ok c’mon dude)"
    case 480...679:
      return " (this isn’t the notes app)"
    case 680...1023:
      return " (the app probably looks pretty bad right now, huh)"
    case 1024...2047:
      return " (I bet you’re wondering when this will stop)"
    case 2048...19999:
      return " (you’re really gonna keep going?)"
    case 20000...30000:
      return " (I’m impressed, really)"
    case 30000...42348:
      return " (almost there)"
    case 42349:
      return " (nice)"
    case 42350...Int.max:
      return " (fin)"
    default:
      return ""
    }
  }
  
  var body: some View {
    VStack(alignment: .trailing) {
      HStack(alignment: .top) {
        if let profileImageURL = twitterClient.user?.profileImageURL {
          RemoteImage(url: profileImageURL, placeholder: { ProgressView() })
            .frame(width: 36, height: 36)
            .cornerRadius(36)
            .onTapGesture {
              signOutScreenIsPresented = true
              UIApplication.shared.endEditing()
            }
        }
        
        ZStack(alignment: .topLeading) {
          Text(tweetText ?? placeholder)
            .padding(.leading, leftOffset)
            .padding(.vertical, verticalPadding)
            .foregroundColor(Color(.placeholderText))
            .opacity(tweetText == nil ? 1 : 0)
            .accessibility(hidden: true)
          
          TextEditor(text: Binding($twitterClient.draft.text, replacingNilWith: ""))
            .foregroundColor(Color(.label))
            .multilineTextAlignment(.leading)
            .keyboardType(.twitter)
            .padding(.top, (verticalPadding / 3) * -1)
        }
        .font(.broadcastTitle3)
      }.transition(.scale)
      
      Divider()
      
      Text("\(280 - charCount)\(tweetLengthWarning)")
        .foregroundColor(charCount > 200 ? charCount >= 280 ? Color(.systemRed) : Color(.systemOrange) : .secondary)
        .font(.system(size: min(captionSize * max(CGFloat(charCount) / 280, 1), 28), weight: .bold, design: .rounded))
        .multilineTextAlignment(.trailing)
    }
    .padding()
    .background(Color(.tertiarySystemGroupedBackground))
    .cornerRadius(captionSize)
    .onShake {
      rotatePlaceholder()
      Haptics.shared.sendStandardFeedback(feedbackType: .success)
    }
    .onChange(of: twitterClient.draft.isValid) { isValid in
      if !isValid && charCount > 280 {
        Haptics.shared.sendStandardFeedback(feedbackType: .warning)
      }
    }
  }
  
  func rotatePlaceholder() {
    var newPlaceholder = placeholder
    
    while newPlaceholder == placeholder {
      newPlaceholder = placeholderCandidates.randomElement()
    }
    
    placeholder = newPlaceholder
  }
}

struct ComposerView_Previews: PreviewProvider {
    static var previews: some View {
      ComposerView(signOutScreenIsPresented: .constant(false))
    }
}