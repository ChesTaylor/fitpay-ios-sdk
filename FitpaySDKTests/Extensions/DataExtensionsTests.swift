import XCTest
import Nimble

@testable import FitpaySDK

class DataExtensionsTests: XCTestCase {

    func testBase64URLencoded() {
        let payloadIV = String.random(JWEObject.PayloadIVSize).data(using: String.Encoding.utf8)
        guard let encodedPayloadIV = payloadIV?.base64URLencoded() else {
            fail("Bad encoding")
            return
        }

        expect(encodedPayloadIV.contains("/")).to(beFalse())
    }

    func testreverseEndian() {
        let original = PAYMENT_CHARACTERISTIC_UUID_APDU_CONTROL.data
        let reversed = original.reverseEndian
        expect(original.first == reversed.last).to(beTrue())
    }

    func testErrorMessage() {
        let errorJSON = "{\"message\":\"The property termsVersion contains an invalid value (null): may not be empty\"}"
        let errorData = errorJSON.data(using: .utf8)
        let errorMessage = errorData?.errorMessage
        expect(errorMessage).to(equal("The property termsVersion contains an invalid value (null): may not be empty"))
    }

    func testErrorMessages() {
        let errorsJSON = "{\"errors\": [{\"message\":\"The property termsVersion contains an invalid value (null): may not be empty\"}]}"
        let errorsData = errorsJSON.data(using: .utf8)
        let errorMessages = errorsData?.errorMessages
        expect(errorMessages?.first).to(equal("The property termsVersion contains an invalid value (null): may not be empty"))
    }

    func testUTF8String() {
        let testString = "The property termsVersion contains an invalid value (null): may not be empty"
        let utf32Data = testString.data(using: String.Encoding.utf32)
        let utf8Data = testString.data(using: String.Encoding.utf8)
        expect(utf8Data?.UTF8String).to(equal(testString))
        expect(utf32Data?.UTF8String).to(beNil())
    }

    func testArrayOfBytes() {
        let keyPair = MockSECP256R1KeyPair()
        guard let data = keyPair.generateSecretForPublicKey(keyPair.publicKey!) else {
            fail("bad secret")
            return
        }
        let bytes = data.arrayOfBytes()
        expect(bytes.count).to(equal(data.count))
    }

    func testHexadecimalString() {
        let keyPair = MockSECP256R1KeyPair()
        guard let data = keyPair.generateSecretForPublicKey(keyPair.publicKey!) else {
            fail("bad secret")
            return
        }
        let hexString = data.hexadecimalString()
        expect(hexString).to(equal("87A3FCE7DAF0FD7E57AD53128DD25820448835DB13507B1388F0CF0BF6BB8F4D"))
    }
}
