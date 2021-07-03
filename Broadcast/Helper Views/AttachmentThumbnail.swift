//
//  ThumbnailFilmstrip.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

struct AttachmentThumbnail: View {
  @Binding var imageData: Data?
  
  var image: UIImage? {
    guard let data = imageData else { return nil }
    return UIImage(data: data)
  }

  var body: some View {
    Group {
      if let image = image {
        ZStack(alignment: .topTrailing) {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(image.size, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 8))

          Button(action: removeImage) {
            Label("Remove Image", systemImage: "xmark.circle")
              .labelStyle(IconOnlyLabelStyle())
              .font(.broadcastTitle.bold())
              .foregroundColor(.white)
              .shadow(color: .black, radius: 8, x: 0, y: 4)
          }
          .buttonStyle(BroadcastButtonStyle(paddingSize: -2, prominence: .tertiary, isFullWidth: false))
          .clipShape(Circle())
          .offset(x: -8, y: 8)
        }
      }
    }.transition(.opacity)

  }

  func removeImage() {
    withAnimation { imageData = nil }
  }
}

struct ThumbnailFilmstrip_Previews: PreviewProvider {
  static var previews: some View {
    AttachmentThumbnail(imageData: .constant(nil))
  }
}
