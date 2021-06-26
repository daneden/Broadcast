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
  @ScaledMetric private var minComposerHeight: CGFloat = 80
  
  @EnvironmentObject var twitterAPI: TwitterAPI
  @State var tweetText: String?
  @State var pickerResult: [UIImage] = []
  @State var photoPickerIsPresented = false
  @State var sendingTweet = false
  let placeholder = "What’s happening?"
  
  var validTweet: Bool {
    let text = tweetText ?? ""
    if !pickerResult.isEmpty && text.count <= 280 {
      return true
    }
    
    return !text.isEmpty && text.count <= 280
  }
  
  var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        VStack {
          if twitterAPI.user != nil {
            VStack(alignment: .trailing) {
              ZStack(alignment: .topLeading) {
                TextEditor(text: Binding($tweetText, replacingNilWith: ""))
                  .frame(minHeight: minComposerHeight, alignment: .leading)
                  .foregroundColor(Color(.label))
                  .multilineTextAlignment(.leading)
                Text(tweetText ?? placeholder)
                  .padding(.leading, leftOffset)
                  .padding(.vertical, verticalPadding)
                  .foregroundColor(Color(.placeholderText))
                  .opacity(tweetText == nil ? 1 : 0)
                  .accessibility(hidden: true)
              }
              .font(.title)
              
              if let tweetText = tweetText ?? "",
                 let count = tweetText.count {
                Divider()
                
                Text("\(280 - count)")
                  .foregroundColor(count > 200 ? count >= 280 ? Color(.systemRed) : Color(.systemOrange) : .secondary)
                  .font(.caption.bold())
              }
            }.padding()
            
            ThumbnailFilmstrip(images: $pickerResult)
          }
        }
      }
      
        VStack {
          if let screenName = twitterAPI.user?.screenName {
          HStack {
            Button(action: { print("tweet \(tweetText ?? "(empty)")") }) {
              Label("Send Tweet", systemImage: "paperplane.fill")
                .font(.headline)
            }
            .id("cta")
            .buttonStyle(BroadcastButtonStyle(isLoading: sendingTweet))
            .disabled(!validTweet || sendingTweet)
            .animation(.spring())
            
            Button(action: { photoPickerIsPresented.toggle() }) {
              Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                .labelStyle(IconOnlyLabelStyle())
            }
            .buttonStyle(BroadcastButtonStyle(prominence: .secondary, isFullWidth: false))
          }
          
          Text("Logged in as \(screenName)")
            .padding()
            .font(.caption.bold())
            .foregroundColor(.secondary)
          } else {
            Button(action: { twitterAPI.authorize() }) {
              Label("Sign In With Twitter", image: "twitter.fill")
                .font(.headline)
            }
            .id("cta")
            .buttonStyle(BroadcastButtonStyle())
          }
        }.padding()
    }
    .sheet(isPresented: $twitterAPI.authorizationSheetIsPresented) {
      SafariView(url: $twitterAPI.authorizationURL)
    }
    .sheet(isPresented: $photoPickerIsPresented) {
      PhotoPicker(pickerResult: $pickerResult, isPresented: $photoPickerIsPresented, limit: 4 - pickerResult.count)
    }
  }
  
  func sendTweet() {
    guard twitterAPI.user != nil else {
      return
    }
    
    sendingTweet = true
    
    twitterAPI.sendTweet(text: tweetText ?? "Beep boop")
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
