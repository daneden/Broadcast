//
//  ThumbnailFilmstrip.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

struct AttachmentThumbnail: View {
  @Binding var media: [UserSelectedMedia]
  @State private var altTextSheetIsPresented = false

  var body: some View {
    VStack {
      if let media = media, !media.isEmpty {
        ForEach(media, id: \.id) { item in
          if let previewData = item.thumbnailData,
             let image = UIImage(data: previewData) {
            ZStack(alignment: .top) {
              Image(uiImage: image)
                .resizable()
                .aspectRatio(image.size, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              
              HStack {
                if item.canAddAltText {
                  Button(action: { altTextSheetIsPresented = true }) {
                    Label("Edit Alt Text", systemImage: "captions.bubble")
                      .labelStyle(.iconOnly)
                  }
                  .buttonStyle(BroadcastButtonStyle(paddingSize: 8, prominence: item.hasAltText ? .primary : .tertiary, isFullWidth: false))
                  .clipShape(Circle())
                  .offset(x: 8, y: 8)
                  .sheet(isPresented: $altTextSheetIsPresented) {
                    AltTextSheet(mediaSet: $media, itemId: item.id)
                  }
                }
              
                Spacer()
                
                Button(action: { removeImage(item.id) }) {
                  Label("Remove Image", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                }
                .buttonStyle(BroadcastButtonStyle(paddingSize: 8, prominence: .tertiary, isFullWidth: false))
                .clipShape(Circle())
                .offset(x: -8, y: 8)
              }
            }
          }
        }
      }
    }
    .transition(.opacity)
  }

  func removeImage(_ id: UUID) {
    withAnimation {
      media.removeAll(where: { $0.id == id })
    }
  }
}

fileprivate struct AltTextSheet: View {
  @Environment(\.presentationMode) var presentationMode
  @Binding var mediaSet: [UserSelectedMedia]
  var itemId: UUID
  
  var preview: UIImage? {
    guard let data = mediaSet.first(where: { $0.id == itemId })?.thumbnailData,
          let image = UIImage(data: data) else {
            return nil
          }
    
    return image
  }
  
  var body: some View {
    NavigationView {
      Form {
        if let preview = preview {
          HStack {
            Spacer()
            Image(uiImage: preview)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .cornerRadius(8)
              .frame(maxWidth: 200, maxHeight: 200)
            Spacer()
          }
          .padding()
          .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
          .listRowBackground(Color.clear)
        }
        
        Section(footer: Text("You can add a description, sometimes called alt-text, to your photos so they’re accessible to even more people, including people who are blind or have low vision. Good descriptions are concise, but present what’s in your photos accurately enough to understand their context.")) {
          TextField("Enter Alt Text", text: $mediaSet.first(where: { $0.wrappedValue.id == itemId })!.altText)
        }
      }
      .navigationTitle("Edit Alt Text")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
      }
    }
  }
}

struct ThumbnailFilmstrip_Previews: PreviewProvider {
  static var previews: some View {
    AttachmentThumbnail(media: .constant([]))
  }
}
