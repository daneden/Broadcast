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
  @ScaledMetric private var captionSize: CGFloat = 20
  @ScaledMetric private var bottomPadding: CGFloat = 80
  @ScaledMetric private var replyBoxLimit: CGFloat = 96
  
  @EnvironmentObject var twitterClient: TwitterClientManager
  
  @State private var photoPickerIsPresented = false
  @State private var repliesSheetIsPresented = false
  
  @State private var sendingTweet = false
  @State private var replying = false
  @State private var replyBoxHeight: CGFloat = 0
  
  private var imageHeightCompensation: CGFloat {
    (twitterClient.selectedMedia.isEmpty ? 0 : bottomPadding) +
      (replying ? min(replyBoxHeight, replyBoxLimit) : 0)
  }
  
  var body: some View {
    GeometryReader { geom in
      ZStack(alignment: .bottom) {
        ScrollView {
          VStack(spacing: captionSize / 2) {
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
              ComposerView()
                .frame(
                  height: geom.size.height - (bottomPadding + (captionSize * 2)) - imageHeightCompensation,
                  alignment: .topLeading
                )
                .animation(.springAnimation, value: imageHeightCompensation)
              
              AttachmentThumbnail(media: $twitterClient.selectedMedia)
                .disabled(twitterClient.state == .busy())
            } else {
              WelcomeView()
            }
          }
          .padding(.top, captionSize)
          .padding(.horizontal)
          .frame(maxWidth: geom.size.width)
        }
        .safeAreaInset(edge: .bottom, content: {
          Group {
            if twitterClient.user != nil {
              ActionBarView(replying: $replying)
            } else {
              Button(action: { Task { await twitterClient.signIn() } }) {
                Label("Sign In With Twitter", image: "twitter.fill")
                  .font(.broadcastHeadline)
              }
              .accessibilityIdentifier("loginButton")
            }
          }
          .buttonStyle(BroadcastButtonStyle(isLoading: twitterClient.state != .idle))
          .padding()
          .background(Material.bar)
          .gesture(DragGesture().onEnded({ _ in UIApplication.shared.endEditing() }))
        })
      }
      .sheet(isPresented: $repliesSheetIsPresented) {
        RepliesListView(tweet: twitterClient.lastTweet)
          .accentColor(ThemeHelper.shared.color)
          .font(.broadcastBody)
          .environmentObject(twitterClient)
      }
      .onAppear {
        UITextView.appearance().backgroundColor = .clear
      }
      .onPreferenceChange(ReplyBoxSizePreferenceKey.self) { newValue in
        withAnimation(.springAnimation) { replyBoxHeight = newValue + (captionSize / 2) }
      }
      .overlay {
        if twitterClient.state == .initializing {
          ZStack {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }.background(.background)
        }
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
