//
//  ThumbnailFilmstrip.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI
import PhotosUI

extension String: Identifiable {
  public var id: String { self }
}

struct AttachmentThumbnail: View {
  @Environment(\.cornerRadius) var cornerRadius
  @EnvironmentObject var twitterClient: TwitterClientManager
  @Binding var media: [String: NSItemProvider]
  @State private var altTextSheetIsPresented = false
  @State private var selectedMediaId: String?

  var body: some View {
    VStack {
      if let media = media, !media.isEmpty {
        ForEach(Array(media.keys), id: \.self) { key in
          ZStack(alignment: .top) {
            LocalMediaPreview(assetId: key, asset: media[key]!)
              .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            
            HStack {
              Button(action: { removeImage(key) }) {
                Label("Remove Image", systemImage: "xmark")
                  .labelStyle(.iconOnly)
              }
              .buttonStyle(BroadcastButtonStyle(paddingSize: 8, prominence: .tertiary, isFullWidth: false))
              .clipShape(Circle())
              .offset(x: 8, y: 8)
              
              Spacer()
              
              if let item = media[key],
                 item.allowsAltText {
                Button(action: { selectedMediaId = key }) {
                  Label("Edit Alt Text", systemImage: "captions.bubble")
                    .labelStyle(.iconOnly)
                }
                .buttonStyle(BroadcastButtonStyle(paddingSize: 8, prominence: itemHasAltText(key) ? .primary : .tertiary, isFullWidth: false))
                .clipShape(Circle())
                .offset(x: -8, y: 8)
                .sheet(item: $selectedMediaId) { id in
                  AltTextSheet(assetId: id, asset: item)
                }
              }
            }
          }
        }.transition(.scale)
      }
    }
  }
  
  func itemHasAltText(_ id: String) -> Bool {
    return !(twitterClient.mediaAltText[id]?.isEmpty ?? true)
  }

  func removeImage(_ id: String) {
    withAnimation {
      _ = media.removeValue(forKey: id)
    }
  }
}

fileprivate struct AltTextSheet: View {
  @Environment(\.cornerRadius) var cornerRadius: Double
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var twitterClient: TwitterClientManager
  
  var assetId: String
  var asset: NSItemProvider
  
  @State var altText = ""
  
  var body: some View {
    NavigationView {
      Form {
        HStack {
          Spacer()
          LocalMediaPreview(assetId: assetId, asset: asset)
            .cornerRadius(cornerRadius / 2)
            .frame(minWidth: 0, maxWidth: 200, minHeight: 0, maxHeight: 200)
          Spacer()
        }
        .padding()
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
        
        Section(footer: Text("You can add a description, sometimes called alt-text, to your photos so they’re accessible to even more people, including people who are blind or have low vision. Good descriptions are concise, but present what’s in your photos accurately enough to understand their context.")) {
          TextField("Enter Alt Text", text: $altText)
            .onSubmit {
              self.presentationMode.wrappedValue.dismiss()
            }
        }
      }
      .navigationTitle("Edit Alt Text")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
      }
      .onDisappear {
        withAnimation(.springAnimation) {
          twitterClient.mediaAltText[assetId] = altText
        }
      }
      .onAppear {
        if let currentValue = twitterClient.mediaAltText[assetId] {
          DispatchQueue.main.async {
            altText = currentValue
          }
        }
      }
    }
  }
}


struct ThumbnailFilmstrip_Previews: PreviewProvider {
  static var previews: some View {
    AttachmentThumbnail(media: .constant([:]))
  }
}
