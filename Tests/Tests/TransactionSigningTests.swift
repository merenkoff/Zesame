//
// Copyright 2019 Open Zesame
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under thexc License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
import EllipticCurveKit
@testable import Zesame

private let network: Network = .mainnet
private let service = DefaultZilliqaService(network: network)

class TransactionSigningTests: XCTestCase {

    func testTransactionSigning() {

        // Some uninteresting Zilliqa TESTNET private key, that might contain some worthless TEST tokens.
        let privateKey = PrivateKey(hex: "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638")!
        let publicKey = PublicKey(privateKey: privateKey)

        let unsignedTx = Transaction(
            payment: Payment(
                to: try! Address(string: "9Ca91EB535Fb92Fda5094110FDaEB752eDb9B039"),
                amount: 15,
                gasLimit: 1,
                gasPrice: GasPrice.min,
                nonce: Nonce(3)
            ),
            network: network
        )

        let message = messageFromUnsignedTransaction(unsignedTx, publicKey: publicKey)
        let signature = service.sign(message: message, using: KeyPair(private: privateKey, public: publicKey))

        let signedTransaction = SignedTransaction(transaction: unsignedTx, signedBy: publicKey, signature: signature)
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        do {
            let transactionJSONData = try jsonEncoder.encode(signedTransaction)
            let transactionJSONString = String(data: transactionJSONData, encoding: .utf8)!
            XCTAssertEqual(transactionJSONString, expectedTransactionJSONString)
        } catch {
            return XCTFail("Should not throw, unexpected error: \(error)")
        }
    }
}

private let expectedTransactionJSONString = """
{
  "amount" : "15000000000000",
  "toAddr" : "9Ca91EB535Fb92Fda5094110FDaEB752eDb9B039",
  "pubKey" : "034AE47910D58B9BDE819C3CFFA8DE4441955508DB00AA2540DB8E6BF6E99ABC1B",
  "data" : "",
  "code" : "",
  "signature" : "349A9085A4F4455B7F334A42D8C7DE552A377093BC55FDA20EBF7ADA9FDCFB92108A5956B16FD2334F6D83201E7B999164223765A3DDCBAFC69D215922DC1F80",
  "gasLimit" : "1",
  "version" : 65537,
  "gasPrice" : "1000000000",
  "nonce" : 4
}
"""
