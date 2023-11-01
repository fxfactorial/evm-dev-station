import Foundation
import EVMBridge

extension String {
    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }

    func to_go_string() -> GoString {
        let code = self
        let data = Data(code.utf8)
        let value = data.withUnsafeBytes { $0.baseAddress }!
        let result = value.assumingMemoryBound(to: CChar.self)
        let wrapped = GoString(p: result, n: self.count)
        return wrapped
    }

    func to_go_string2() -> GoString {
        let copy = String(self)
        let wrapped = copy.data(using: .ascii, allowLossyConversion: false)?.withUnsafeBytes {
            $0.baseAddress?.assumingMemoryBound(to: CChar.self)
        }!
        let as_g = GoString(p: wrapped, n: copy.count)
        return as_g
    }

    func to_go_string3() -> GoString {
        let wrapped = self.data(using: .utf8)?.withUnsafeBytes {
            $0.baseAddress?.assumingMemoryBound(to: CChar.self)
        }!
        let as_g = GoString(p: wrapped, n: self.count)
        return as_g
    }

    // FINALLY i think its becauyse i used the pointeee from outside the closure! , not allowed to do that
    // come back to it in the other functions
    func test_4() -> GoString {
        let payload = self.withCString {pointee in
            pointee.withMemoryRebound(to: CChar.self, capacity: self.count) {
                GoString(p: $0, n: self.count)
            }
        }
        return payload
    }
}
                                                                                                               

