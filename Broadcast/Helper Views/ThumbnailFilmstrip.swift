//
//  ThumbnailFilmstrip.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

struct ThumbnailFilmstrip: View {
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
              .font(.broadcastTitle)
          }
          .foregroundColor(.primary)
          .background(Color(.systemBackground))
          .clipShape(Circle())
          .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
          .offset(x: 8, y: -8)
          .highPriorityGesture(TapGesture().onEnded(removeImage))
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
    ThumbnailFilmstrip(image: .constant(nil))
  }
}
