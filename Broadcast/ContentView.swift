//
//  ContentView.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI
import Introspect
import TwitterText

struct ContentView: View {
  @ScaledMetric private var captionSize: CGFloat = 14
  @ScaledMetric private var bottomPadding: CGFloat = 80
  
  @EnvironmentObject var twitterClient: TwitterClient
  @State var photoPickerIsPresented = false
  @State var signOutScreenIsPresented = false
  @State var sendingTweet = false
  @State var replying = false
  @State var replyBoxHeight: CGFloat = 0
  
  private var coordinateSpaceName = "mainViewCoordinateSpace"
  
  private var imageHeightCompensation: CGFloat {
    (twitterClient.draft.media == nil ? 0 : bottomPadding) +
      (replying ? replyBoxHeight : 0)
  }
  
  var body: some View {
    GeometryReader { geom in
      ZStack(alignment: .bottom) {
        ScrollView {
          VStack {
            if replying, let lastTweet = twitterClient.lastTweet {
              LastTweetReplyView(lastTweet: lastTweet, replying: replying)
                .onTapGesture {
                  withAnimation { replying = false }
                }
                .onAppear {
                  replyBoxHeight = geom.frame(in: .global).minY
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
            
            if $twitterClient.user.wrappedValue != nil {
              ComposerView(signOutScreenIsPresented: $signOutScreenIsPresented)
                .frame(
                  height: geom.size.height - (bottomPadding + (captionSize * 2)) - imageHeightCompensation,
                  alignment: .topLeading
                )
              
              AttachmentThumbnail(image: $twitterClient.draft.media)
            } else {
              WelcomeView()
            }
          }
          .padding()
          .padding(.bottom, bottomPadding)
          .frame(maxWidth: geom.size.width)
        }
        .coordinateSpace(name: coordinateSpaceName)
        
        VStack {
          if twitterClient.user != nil {
            HStack {
              if let replyId = twitterClient.lastTweet?.id {
                Button(action: {
                  if replying {
                    twitterClient.sendReply(to: replyId)
                  } else {
                    withAnimation(.spring()) { replying = true }
                  }
                }) {
                  if replying {
                    Label("Send Reply", systemImage: "arrowshape.turn.up.left.fill")
                      .font(.broadcastHeadline)
                  } else {
                    Label("Send Reply", systemImage: "arrowshape.turn.up.left.fill")
                      .font(.broadcastHeadline)
                      .labelStyle(IconOnlyLabelStyle())
                  }
                }
                .buttonStyle(
                  BroadcastButtonStyle(
                    prominence: replying ? .primary : .secondary,
                    isFullWidth: replying,
                    isLoading: twitterClient.state == .busy && replying
                  )
                )
                .disabled(replying && !twitterClient.draft.isValid)
              }
              
              Button(action: {
                if !replying {
                  twitterClient.sendTweet()
                } else {
                  withAnimation(.spring()) { replying = false }
                }
              }) {
                if !replying {
                  Label("Send Tweet", systemImage: "paperplane.fill")
                    .font(.broadcastHeadline)
                } else {
                  Label("Send Tweet", systemImage: "paperplane.fill")
                    .font(.broadcastHeadline)
                    .labelStyle(IconOnlyLabelStyle())
                }
              }
              .buttonStyle(
                BroadcastButtonStyle(
                  prominence: !replying ? .primary : .secondary,
                  isFullWidth: !replying,
                  isLoading: twitterClient.state == .busy && !replying
                )
              )
              .disabled(!replying && !twitterClient.draft.isValid)
              
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
        ImagePicker(image: $twitterClient.draft.media)
      }
      .sheet(isPresented: $signOutScreenIsPresented) {
        SignOutView()
      }
      .onAppear {
        UITextView.appearance().backgroundColor = .clear
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
