//
//  ThumbnailFilmstrip.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

struct ThumbnailFilmstrip: View {
  @Binding var images: [UIImage]
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(images, id: \.self) { image in
          ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 120, height: 120)
              .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: { removeImage(image) }) {
              Label("Remove Image", systemImage: "xmark.circle.fill")
                .labelStyle(IconOnlyLabelStyle())
            }
            .foregroundColor(.primary)
            .background(Color(.systemBackground))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .offset(x: 8, y: -8)
          }
        }.transition(.opacity)
      }.padding()
    }
  }
  
  func removeImage(_ image: UIImage) {
    withAnimation {
      self.images.removeAll { candidate in
        image == candidate
      }
    }
  }
}

struct ThumbnailFilmstrip_Previews: PreviewProvider {
    static var previews: some View {
      ThumbnailFilmstrip(images: .constant([]))
    }
}
