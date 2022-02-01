//
//  PhotoPicker.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation
import PhotosUI
import SwiftUI
import Twift

extension PHPickerResult {
  var mediaType: UTType? {
    if let typeIdentifier = itemProvider.registeredTypeIdentifiers.first {
      return UTType(typeIdentifier)
    } else if let pathExtension = itemProvider.suggestedName?.split(after: ".").first {
      return UTType(filenameExtension: pathExtension)
    } else {
      print(itemProvider.registeredTypeIdentifiers, itemProvider.suggestedName, itemProvider.preferredPresentationStyle)
      return nil
    }
  }
  
  var mediaMimeType: Media.MimeType? {
    if let mimeType = mediaType?.preferredMIMEType {
      let castMimeType = mimeType == "image/heic" ? "image/jpeg" : mimeType
      return Media.MimeType(rawValue: castMimeType)
    } else {
      return nil
    }
  }
  
  var allowsAltText: Bool {
    return mediaType?.conforms(to: .image) ?? false
  }
}

struct ImagePicker: UIViewControllerRepresentable {
  @Environment(\.presentationMode) var presentationMode
  var configuration: PHPickerConfiguration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
  
  @Binding var selection: [String: PHPickerResult]
  
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
      for result in results {
        self.parent.selection[result.assetIdentifier!] = result
      }
      
      self.parent.presentationMode.wrappedValue.dismiss()
    }
  }
}
