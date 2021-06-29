//
//  ContentView.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI
import Introspect
import TwitterText

let placeholderCandidates: [String] = [
  "Wh—what’s going on?",
  "Oh hey uh, what’s up",
  "What’s Twitter?",
  "Tweet away, sweet child",
  "Say something nice",
  "Cowabunga, dude",
  "You’re doing a great job"
]

struct ContentView: View {
  @ScaledMetric private var leftOffset: CGFloat = 4
  @ScaledMetric private var verticalPadding: CGFloat = 6
  @ScaledMetric private var bottomPadding: CGFloat = 80
  @ScaledMetric private var minComposerHeight: CGFloat = 120
  @ScaledMetric private var captionSize: CGFloat = 14
  
  @EnvironmentObject var twitterClient: TwitterClient
  @State var photoPickerIsPresented = false
  @State var signOutScreenIsPresented = false
  @State var sendingTweet = false
  
  @State private var placeholder: String = placeholderCandidates.randomElement()
  
  private var tweetText: String? {
    twitterClient.tweet
  }
  
  private var charCount: Int {
    TwitterText.tweetLength(text: tweetText ?? "")
  }
  
  private var validTweet: Bool {
    let text = tweetText ?? ""
    if twitterClient.image != nil && text.count <= 280 {
      return true
    }
    
    return !text.isEmpty && text.count <= 280
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
    case 42349...Int.max:
      return " (fin)"
    default:
      return ""
    }
  }
  
  private var imageHeightCompensation: CGFloat {
    twitterClient.image == nil ? 0 : bottomPadding
  }
  
  var body: some View {
    GeometryReader { geom in
      ZStack(alignment: .bottom) {
        ScrollView {
          VStack {
            if case .error(let errorMessage) = twitterClient.state {
              Text(errorMessage ?? "Some weird kind of error occurred; @_dte is probably to blame since he made this app.")
                .font(.broadcastFootnote.weight(.semibold))
                .foregroundColor(Color(.systemRed))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemRed).opacity(0.2))
                .cornerRadius(captionSize)
                .onTapGesture {
                  withAnimation {
                    twitterClient.state = .idle
                  }
                }
            }
            
            if $twitterClient.user.wrappedValue != nil {
              VStack(alignment: .trailing) {
                HStack(alignment: .top) {
                  if let profileImageURL = twitterClient.profileImageURL {
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
                    
                    TextEditor(text: Binding($twitterClient.tweet, replacingNilWith: ""))
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
              .frame(height: geom.size.height - (bottomPadding + (captionSize * 2)) - imageHeightCompensation, alignment: .topLeading)
              
              AttachmentThumbnail(image: $twitterClient.image)
            } else {
              WelcomeView()
            }
          }
          .padding()
          .padding(.bottom, bottomPadding)
          .frame(maxWidth: geom.size.width)
        }
        
        VStack {
          if twitterClient.user != nil {
            HStack {
              Button(action: {
                sendTweet()
                UIApplication.shared.endEditing()
              }) {
                Label("Send Tweet", systemImage: "paperplane.fill")
                  .font(.broadcastHeadline)
              }
              .buttonStyle(BroadcastButtonStyle(isLoading: twitterClient.state == .busy))
              .disabled(!validTweet)
              
              Button(action: {
                photoPickerIsPresented.toggle()
                UIApplication.shared.endEditing()
              }) {
                Label("Add Media", systemImage: "photo.on.rectangle.angled")
                  .labelStyle(IconOnlyLabelStyle())
              }
              .buttonStyle(BroadcastButtonStyle(prominence: .tertiary, isFullWidth: false))
            }
            .disabled(twitterClient.state == .busy)
          } else {
            Button(action: { twitterClient.signIn() }) {
              Label("Sign In With Twitter", image: "twitter.fill")
                .font(.broadcastHeadline)
            }
            .buttonStyle(BroadcastButtonStyle())
          }
        }
        .padding()
        .animation(.spring())
        .background(
          VisualEffectView(effect: UIBlurEffect(style: .regular))
            .ignoresSafeArea()
            .opacity(twitterClient.user == nil ? 0 : 1)
        )
        .gesture(DragGesture().onEnded({ _ in UIApplication.shared.endEditing() }))
      }
      .sheet(isPresented: $photoPickerIsPresented) {
        ImagePicker(image: $twitterClient.image)
      }
      .sheet(isPresented: $signOutScreenIsPresented) {
        SignOutView()
      }
      .onAppear {
        UITextView.appearance().backgroundColor = .clear
      }
      .onShake {
        rotatePlaceholder()
        Haptics.shared.sendStandardFeedback(feedbackType: .success)
      }
      .onChange(of: validTweet) { isValid in
        if !isValid && charCount > 280 {
          Haptics.shared.sendStandardFeedback(feedbackType: .warning)
        }
      }
      
    }
  }
  
  func sendTweet() {
    guard twitterClient.user != nil else {
      return
    }
    
    if let image = twitterClient.image {
      twitterClient.sendTweet(tweet: tweetText ?? "", media: image.jpegData(compressionQuality: 80))
      return
    }
    
    twitterClient.sendTweet(tweet: tweetText ?? "")
    
    rotatePlaceholder()
  }
  
  func rotatePlaceholder() {
    var newPlaceholder = placeholder
    
    while newPlaceholder == placeholder {
      newPlaceholder = placeholderCandidates.randomElement()
    }
    
    placeholder = newPlaceholder
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
