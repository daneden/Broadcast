//
//  ThumbnailFilmstrip.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

struct AttachmentThumbnail: View {
  @Binding var image: UIImage?
  
  var body: some View {
    Group {
      if let image = image {
        ZStack(alignment: .topTrailing) {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(image.size, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 8))
          
          Button(action: removeImage) {
            Label("Remove Image", systemImage: "xmark.circle.fill")
              .labelStyle(IconOnlyLabelStyle())
              .font(.broadcastTitle.bold())
          }
          .buttonStyle(BroadcastButtonStyle(paddingSize: 0, prominence: .tertiary, isFullWidth: false))
          .clipShape(Circle())
          .offset(x: -8, y: 8)
        }
      }
    }.transition(.opacity)
    
  }
  
  func removeImage() {
    withAnimation { image = nil }
  }
}

struct ThumbnailFilmstrip_Previews: PreviewProvider {
  static var previews: some View {
    AttachmentThumbnail(image: .constant(nil))
  }
}
