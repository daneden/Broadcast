//
//  PhotoPicker.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation
import UIKit
import Photos
import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
  @Binding var pickerResult: [UIImage] // pass images back to the SwiftUI view
  @Binding var isPresented: Bool // close the modal view
  var limit = 4
  
  func makeUIViewController(context: Context) -> some UIViewController {
    var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
    configuration.filter = .images // filter only to images
    configuration.selectionLimit = limit // ignore limit
    
    let photoPickerViewController = PHPickerViewController(configuration: configuration)
    photoPickerViewController.delegate = context.coordinator // Use Coordinator for delegation
    return photoPickerViewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  // Create the Coordinator, in this case it is a way to communicate with the PHPickerViewController
  class Coordinator: PHPickerViewControllerDelegate {
    private let parent: PhotoPicker
    
    init(_ parent: PhotoPicker) {
      self.parent = parent
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      parent.pickerResult.removeAll() // remove previous pictures from the main view
      
      // unpack the selected items
      for image in results {
        if image.itemProvider.canLoadObject(ofClass: UIImage.self) {
          image.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] newImage, error in
            if let error = error {
              print("Can't load image \(error.localizedDescription)")
            } else if let image = newImage as? UIImage {
              // Add new image and pass it back to the main view
              self?.parent.pickerResult.append(image)
            }
          }
        } else {
          print("Can't load asset")
        }
      }
      
      // close the modal view
      parent.isPresented = false
    }
  }
}
