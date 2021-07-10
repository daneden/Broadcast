//
//  UIImage.extension.swift
//  Broadcast
//
//  Created by Daniel Eden on 10/07/2021.
//

import Foundation
import UIKit

extension UIImage {
  func fixOrientation(_ img: UIImage) -> UIImage {
    if (img.imageOrientation == .up) {
      return img
    }
    
    UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
    let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
    img.draw(in: rect)
    
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return normalizedImage
  }
  
  var fixedOrientation: UIImage {
    return fixOrientation(self)
  }
}
