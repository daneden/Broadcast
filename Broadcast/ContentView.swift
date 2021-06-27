//
//  ContentView.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI
import Introspect

struct ContentView: View {
  @ScaledMetric private var leftOffset: CGFloat = 4
  @ScaledMetric private var verticalPadding: CGFloat = 7
  @ScaledMetric private var bottomPadding: CGFloat = 120
  @ScaledMetric private var minComposerHeight: CGFloat = 120
  @ScaledMetric private var captionSize: CGFloat = 14
  
  @EnvironmentObject var twitterClient: TwitterClient
  @State var photoPickerIsPresented = false
  @State var signOutScreenIsPresented = false
  @State var sendingTweet = false
  
  private let placeholder = "What’s happening?"
  
  private var tweetText: String? {
    twitterClient.tweet
  }
  
  private var charCount: Int {
    (tweetText ?? "").count
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
    case 2048...4096:
      return " (I’ll give you a clue: two nice numbers)"
    case 4096...19999:
      return " (you’re really gonna keep going?)"
    case 20000...30000:
      return " (I’m impressed, really)"
    case 30000...40000:
      return " (almost there)"
    case 41788...Int.max:
      return " (nice)"
    default:
      return ""
    }
  }
  
  var body: some View {
    GeometryReader { geom in
      ZStack(alignment: .bottom) {
        ScrollView {
          VStack {
            if $twitterClient.user.wrappedValue != nil {
              VStack(alignment: .trailing) {
                ZStack(alignment: .topLeading) {
                  Text(tweetText ?? placeholder)
                    .padding(.leading, leftOffset)
                    .padding(.vertical, verticalPadding)
                    .foregroundColor(Color(.placeholderText))
                    .opacity(tweetText == nil ? 1 : 0)
                    .accessibility(hidden: true)
                  
                  TextEditor(text: Binding($twitterClient.tweet, replacingNilWith: ""))
                    .frame(minHeight: geom.size.height / 3, alignment: .leading)
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.leading)
                    .keyboardType(.twitter)
                    .introspectTextView { textView in
                      textView.isScrollEnabled = false
                    }
                }
                .font(.broadcastTitle2)
                
                if let tweetText = twitterClient.tweet ?? "",
                   let count = tweetText.count {
                  Divider()
                  
                  Text("\(280 - count)\(tweetLengthWarning)")
                    .foregroundColor(count > 200 ? count >= 280 ? Color(.systemRed) : Color(.systemOrange) : .secondary)
                    .font(.system(size: captionSize * max(CGFloat(charCount) / 280, 1), weight: .bold, design: .rounded))
                    .multilineTextAlignment(.trailing)
                }
              }
              .padding()
              .background(Color(.tertiarySystemGroupedBackground))
              .cornerRadius(captionSize)
              
              if case .error(let errorMessage) = twitterClient.state {
                Text(errorMessage ?? "Some weird kind of error occurred; @_dte is probably to blame since he made this app.")
                  .font(.broadcastBody.weight(.semibold))
                  .foregroundColor(Color(.systemRed))
                  .padding(verticalPadding)
                  .frame(maxWidth: .infinity)
                  .background(Color(.systemRed).opacity(0.2))
                  .cornerRadius(verticalPadding)
              }
              
              ThumbnailFilmstrip(image: $twitterClient.image)
            } else {
              WelcomeView()
            }
          }
          .padding()
          .padding(.bottom, bottomPadding)
          .frame(maxWidth: geom.size.width)
        }
        
        VStack {
          if let screenName = twitterClient.user?.screenName {
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
            
            Text("Logged in as @\(screenName)")
              .padding(.top, verticalPadding)
              .font(.broadcastCaption.weight(.medium))
              .foregroundColor(.accentColor)
              .onTapGesture {
                signOutScreenIsPresented = true
                UIApplication.shared.endEditing()
              }
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
          VisualEffectView(effect: UIBlurEffect(style: .prominent))
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
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
