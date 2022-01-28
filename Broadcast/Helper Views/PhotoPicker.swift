//
//  PhotoPicker.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation
import PhotosUI
import SwiftUI

struct UserSelectedMedia {
  let id = UUID()
  var data: Data?
  var thumbnailData: Data?
  var mimeType: String?
  var altText: String = ""
  
  var hasAltText: Bool { !altText.isEmpty }
  var canAddAltText: Bool { mimeType?.contains("image") ?? false }
}

struct ImagePicker: UIViewControllerRepresentable {
  @Environment(\.presentationMode) var presentationMode
  var configuration: PHPickerConfiguration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
  
  @Binding var selection: [UserSelectedMedia]
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> PHPickerViewController {
    let controller = PHPickerViewController(configuration: configuration)
    controller.delegate = context.coordinator
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: PHPickerViewController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: PHPickerViewControllerDelegate {
    let parent: ImagePicker
    
    init(_ parent: ImagePicker) {
      self.parent = parent
    }
    
    func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      if results.isEmpty {
        self.parent.presentationMode.wrappedValue.dismiss()
      }
      let dispatchQueue = DispatchQueue(label: "me.daneden.Twift_SwiftUI.AlbumImageQueue")
      var selectedImageDatas = [UserSelectedMedia?](repeating: nil, count: results.count) // Awkwardly named, sure
      var totalConversionsCompleted = 0
      
      for (index, result) in results.enumerated() {
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
          guard let url = url, let rawImageData = try? Data(contentsOf: url) else {
            dispatchQueue.sync { totalConversionsCompleted += 1 }
            return
          }
          
          let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
          
          guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            dispatchQueue.sync { totalConversionsCompleted += 1 }
            return
          }
          
          let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: false,
            kCGImageSourceThumbnailMaxPixelSize: 2_000,
          ] as CFDictionary
          
          guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            dispatchQueue.sync { totalConversionsCompleted += 1}
            return
          }
          
          let data = NSMutableData()
          let utType = UTType.init(filenameExtension: url.pathExtension)
          
          guard let imageDestination = CGImageDestinationCreateWithData(data, (utType ?? UTType.jpeg).identifier as CFString, 1, nil) else {
            dispatchQueue.sync { totalConversionsCompleted += 1 }
            return
          }
          
          let destinationProperties = [
            kCGImageDestinationLossyCompressionQuality: utType == .png ? 1.0 : 0.75
          ] as CFDictionary
          
          CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
          CGImageDestinationFinalize(imageDestination)
          
          dispatchQueue.sync {
            let selection = UserSelectedMedia(data: rawImageData,
                                              thumbnailData: data as Data,
                                              mimeType: utType?.preferredMIMEType ?? "image/jpeg")
            selectedImageDatas[index] = selection
            totalConversionsCompleted += 1
            
            if totalConversionsCompleted == results.count {
              print(selectedImageDatas)
              
              DispatchQueue.main.async {
                self.parent.selection.append(contentsOf: selectedImageDatas.compactMap { $0 })
              }
              self.parent.presentationMode.wrappedValue.dismiss()
            }
          }
        }
      }
    }
  }
}
