//
// MIT License
//
// Copyright (c) 2018-2019 Open Zesame (https://github.com/OpenZesame)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import CryptoSwift
import EllipticCurveKit

public extension Keystore {
    public struct Crypto: Codable, Equatable {

        /// "cipher"
        let cipherType: String

        /// "cipherparams"
        let cipherParameters: CipherParameters

        let encryptedPrivateKeyHex: String
        var encryptedPrivateKey: Data { return Data(hex: encryptedPrivateKeyHex) }

        let kdf: KeyDerivationFunction

        /// "kdfparams"
        let keyDerivationFunctionParameters: KeyDerivationFunction.Parameters

        /// "mac"
        let messageAuthenticationCodeHex: String
        var messageAuthenticationCode: Data { return Data(hex: messageAuthenticationCodeHex) }

        public init(
            cipherType: String = "aes-128-ctr",
            cipherParameters: CipherParameters,
            encryptedPrivateKeyHex: String,
            kdf: KDF,
            kdfParams: KDFParams,
            messageAuthenticationCodeHex: String
            ) {
            self.cipherType = cipherType
            self.cipherParameters = cipherParameters
            self.encryptedPrivateKeyHex = encryptedPrivateKeyHex
            self.kdf = kdf
            self.keyDerivationFunctionParameters = kdfParams
            self.messageAuthenticationCodeHex = messageAuthenticationCodeHex
        }
    }
}

// MARK: - Convenience Init
public extension Keystore.Crypto {
    init(
        derivedKey: DerivedKey,
        privateKey: PrivateKey,
        kdf: KDF,
        parameters: KDFParams
        ) {

        /// initializationVector
        let iv = try! securelyGenerateBytes(count: 16).asData

        let aesCtr = try! AES(key: derivedKey.asData.prefix(16).bytes, blockMode: CTR(iv: iv.bytes))

        let encryptedPrivateKey = try! aesCtr.encrypt(privateKey.bytes).asData

        let mac = (derivedKey.asData.suffix(16) + encryptedPrivateKey).asData.sha3(.sha256)

        self.init(
            cipherParameters:
            Keystore.Crypto.CipherParameters(initializationVectorHex: iv.asHex),
            encryptedPrivateKeyHex: encryptedPrivateKey.asHex,
            kdf: kdf,
            kdfParams: parameters,
            messageAuthenticationCodeHex: mac.asHex)
    }
}

// MARK: - Codable
extension Keystore.Crypto {
    public enum CodingKeys: String, CodingKey {
        case cipherType = "cipher"
        case cipherParameters = "cipherparams"
        case encryptedPrivateKeyHex = "ciphertext"
        case kdf = "kdf"
        case keyDerivationFunctionParameters = "kdfparams"
        case messageAuthenticationCodeHex = "mac"
    }
}
