//
//  ContentView.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

struct ContentView: View {
  @ScaledMetric private var leftOffset: CGFloat = 4
  @ScaledMetric private var verticalPadding: CGFloat = 7
  @ScaledMetric private var bottomPadding: CGFloat = 120
  @ScaledMetric private var minComposerHeight: CGFloat = 80
  
  @EnvironmentObject var twitterClient: TwitterClient
  @State var photoPickerIsPresented = false
  @State var signOutScreenIsPresented = false
  @State var sendingTweet = false
  
  private let placeholder = "What’s happening?"
  
  var tweetText: String? {
    twitterClient.tweet
  }
  
  var validTweet: Bool {
    let text = tweetText ?? ""
    if twitterClient.image != nil && text.count <= 280 {
      return true
    }
    
    return !text.isEmpty && text.count <= 280
  }
  
  var body: some View {
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
                  .frame(minHeight: minComposerHeight, alignment: .leading)
                  .foregroundColor(Color(.label))
                  .multilineTextAlignment(.leading)
                  .allowsHitTesting(true)
              }
              .font(.broadcastTitle)
              
              if let tweetText = twitterClient.tweet ?? "",
                 let count = tweetText.count {
                Divider()
                
                Text("\(280 - count)")
                  .foregroundColor(count > 200 ? count >= 280 ? Color(.systemRed) : Color(.systemOrange) : .secondary)
                  .font(.broadcastCaption.bold())
              }
            }
            
            ThumbnailFilmstrip(image: $twitterClient.image)
          } else {
            WelcomeView()
          }
        }
        .padding()
        .padding(.bottom, bottomPadding)
      }
      
      VStack {
        if let screenName = twitterClient.user?.screenName {
          HStack {
            Button(action: sendTweet) {
              Label("Send Tweet", systemImage: "paperplane.fill")
                .font(.broadcastHeadline)
            }
            .id("cta")
            .buttonStyle(BroadcastButtonStyle(isLoading: twitterClient.state == .busy))
            .disabled(!validTweet)
            
            Button(action: { photoPickerIsPresented.toggle() }) {
              Label("Add Media", systemImage: "photo.on.rectangle.angled")
                .labelStyle(IconOnlyLabelStyle())
            }
            .buttonStyle(BroadcastButtonStyle(prominence: .tertiary, isFullWidth: false))
          }
          .disabled(twitterClient.state == .busy)
          
          Text("Logged in as @\(screenName)")
            .padding(.top)
            .font(.broadcastCaption.bold())
            .foregroundColor(.secondary)
            .onTapGesture {
              signOutScreenIsPresented = true
            }
        } else {
          Button(action: { twitterClient.signIn() }) {
            Label("Sign In With Twitter", image: "twitter.fill")
              .font(.broadcastHeadline)
          }
          .id("cta")
          .buttonStyle(BroadcastButtonStyle())
        }
      }
      .padding()
      .padding(.top, 40)
      .background(
        LinearGradient(
          gradient: Gradient(colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)]),
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .animation(.spring())
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
