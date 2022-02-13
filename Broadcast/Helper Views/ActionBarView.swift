//
//  ActionBarView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/07/2021.
//

import SwiftUI
import PhotosUI

struct ActionBarView: View {
  @ScaledMetric var barHeight: CGFloat = 80
  @EnvironmentObject var twitterClient: TwitterClientManager
  @Binding var replying: Bool
  
  @State private var photoPickerIsPresented = false
  
  var loadingLabel: String? {
    switch twitterClient.state {
    case .busy(let label): return label
    default: return nil
    }
  }
  
  private var pickerConfig: PHPickerConfiguration {
    var config = PHPickerConfiguration(photoLibrary: .shared())
    
    config.preferredAssetRepresentationMode = .compatible
    config.selection = .ordered
    
    if moreMediaAllowed && !twitterClient.selectedMedia.isEmpty {
      config.filter = .images
      config.selectionLimit = 4
      config.preselectedAssetIdentifiers = twitterClient.selectedMedia.map(\.key)
    } else {
      config.filter = .any(of: [.images, .videos])
    }
    
    return config
  }
  
  private var moreMediaAllowed: Bool {
    if twitterClient.selectedMedia.contains(where: { $0.value.mediaType!.conforms(to: .movie) || $0.value.mediaType!.conforms(to: .video) }) { return false }
    if twitterClient.selectedMedia.count == 4 { return false }
    return true
  }
  
  var body: some View {
    publishingActions
      .disabled(twitterClient.state.isBusy)
      .sheet(isPresented: $photoPickerIsPresented) {
        ImagePicker(configuration: pickerConfig, selection: $twitterClient.selectedMedia)
          .ignoresSafeArea()
      }
      .onLongPressGesture {
        ThemeHelper.shared.rotateTheme()
        Haptics.shared.sendStandardFeedback(feedbackType: .success)
      }
  }
  
  var publishingActions: some View {
    HStack {
      if twitterClient.lastTweet != nil {
        Button(action: {
          if replying {
            Task {
              await twitterClient.sendTweet(asReply: true)
            }
          } else {
            withAnimation(.springAnimation) { replying = true }
          }
        }) {
          Label("Send Reply", systemImage: "arrowshape.turn.up.left.fill")
            .font(.broadcastHeadline)
            .labelStyle(
              BroadcastLabelStyle(
                appearance: !replying ? .iconOnly : .normal,
                accessibilityLabel: "Send Reply"
              )
            )
        }
        .buttonStyle(
          BroadcastButtonStyle(
            prominence: replying ? .primary : .secondary,
            isFullWidth: replying,
            isLoading: twitterClient.state.isBusy && replying,
            loadingLabel: loadingLabel
          )
        )
        .disabled(replying && !twitterClient.draftIsValid())
      }
      
      Button(action: {
        if !replying {
          Task {
            await twitterClient.sendTweet()
          }
        } else {
          withAnimation(.springAnimation) { replying = false }
        }
      }) {
        Label("Send Tweet", systemImage: "paperplane.fill")
          .font(.broadcastHeadline)
          .labelStyle(
            BroadcastLabelStyle(
              appearance: replying ? .iconOnly : .normal,
              accessibilityLabel: "Send Tweet"
            )
          )
      }
      .accessibilityIdentifier("sendTweetButton")
      .buttonStyle(
        BroadcastButtonStyle(
          prominence: !replying ? .primary : .secondary,
          isFullWidth: !replying,
          isLoading: twitterClient.state.isBusy && !replying,
          loadingLabel: loadingLabel
        )
      )
      .disabled(!replying && !twitterClient.draftIsValid())
      
      Button(action: {
        photoPickerIsPresented.toggle()
        UIApplication.shared.endEditing()
      }) {
        Label("Add Media", systemImage: "photo.on.rectangle.angled")
          .labelStyle(IconOnlyLabelStyle())
      }
      .buttonStyle(BroadcastButtonStyle(prominence: .tertiary, isFullWidth: false))
      .accessibilityIdentifier("imagePickerButton")
      .disabled(!moreMediaAllowed)
    }
  }
}
