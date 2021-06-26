//
//  HMACSHA1Hash.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation

import CommonCrypto

extension String {
  func hmacSHA1Hash(key: String) -> String {
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1),
           key,
           key.count,
           self,
           self.count,
           &digest)
    return Data(digest).base64EncodedString()
  }
}
