//
//  TwitterClientManager+CompressMedia.swift
//  Broadcast
//
//  Created by Daniel Eden on 11/02/2022.
//

import Foundation
import AVFoundation

extension TwitterClientManager {
  func compressVideo(
    inputURL: URL,
    outputURL: URL
  ) async -> AVAssetExportSession? {
    let urlAsset = AVURLAsset(url: inputURL, options: nil)
    
    guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetHighestQuality) else {
      return nil
    }
    
    exportSession.fileLengthLimit = 14 * 2^20 // 15mb limit
    exportSession.timeRange = CMTimeRange(start: CMTime.zero, duration: urlAsset.duration)
    exportSession.outputURL = outputURL
    exportSession.outputFileType = AVFileType.mp4
    exportSession.shouldOptimizeForNetworkUse = true
    
    await exportSession.export()
    return exportSession
  }
}
