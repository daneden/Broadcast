//
//  ContentView.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI
import Introspect
import TwitterText
import Twift

struct ContentView: View {
  @ScaledMetric private var captionSize: CGFloat = 14
  @ScaledMetric private var bottomPadding: CGFloat = 80
  @ScaledMetric private var replyBoxLimit: CGFloat = 96
  
  @EnvironmentObject var twitterClient: TwitterClient
  
  @State private var photoPickerIsPresented = false
  @State private var signOutScreenIsPresented = false
  @State private var repliesSheetIsPresented = false
  
  @State private var sendingTweet = false
  @State private var replying = false
  @State private var replyBoxHeight: CGFloat = 0
  
  private var imageHeightCompensation: CGFloat {
    (twitterClient.draft.media == nil ? 0 : bottomPadding) +
      (replying ? min(replyBoxHeight, replyBoxLimit) : 0)
  }
  
  var body: some View {
    GeometryReader { geom in
      ZStack(alignment: .bottom) {
        ScrollView {
          VStack(spacing: 8) {
            if replying, let lastTweet = twitterClient.lastTweet {
              LastTweetReplyView(lastTweet: lastTweet)
                .background(GeometryReader { geometry in
                  Color.clear.preference(
                    key: ReplyBoxSizePreferenceKey.self,
                    value: geometry.size.height
                  )
                })
                .onTapGesture {
                  repliesSheetIsPresented = true
                }
            }
            
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
            
            if twitterClient.user != nil {
              ComposerView(signOutScreenIsPresented: $signOutScreenIsPresented)
                .frame(
                  height: geom.size.height - (bottomPadding + (captionSize * 2)) - imageHeightCompensation,
                  alignment: .topLeading
                )
              
//              AttachmentThumbnail(image: $twitterClient.draft.media)
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
            ActionBarView(replying: $replying)
          } else {
            Button(action: { twitterClient.signIn() }) {
              Label("Sign In With Twitter", image: "twitter.fill")
                .font(.broadcastHeadline)
            }
            .buttonStyle(BroadcastButtonStyle())
            .accessibilityIdentifier("loginButton")
          }
        }
        .padding()
        .animation(.springAnimation)
        .background(
          VisualEffectView(effect: UIBlurEffect(style: .regular))
            .ignoresSafeArea()
            .opacity(twitterClient.user == nil ? 0 : 1)
        )
        .gesture(DragGesture().onEnded({ _ in UIApplication.shared.endEditing() }))
      }
      .sheet(isPresented: $signOutScreenIsPresented) {
        SignOutView()
      }
      .sheet(isPresented: $repliesSheetIsPresented) {
        RepliesListView(tweet: twitterClient.lastTweet)
          .accentColor(ThemeHelper.shared.color)
          .font(.broadcastBody)
      }
      .onAppear {
        UITextView.appearance().backgroundColor = .clear
      }
      .onPreferenceChange(ReplyBoxSizePreferenceKey.self) { newValue in
        withAnimation(.springAnimation) { replyBoxHeight = newValue + 8 }
      }
    }
  }
}

extension ContentView {
  struct ReplyBoxSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat,
                       nextValue: () -> CGFloat) {
      value = max(value, nextValue())
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
