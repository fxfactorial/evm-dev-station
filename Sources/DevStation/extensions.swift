import EVMBridge

extension String {
    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }
}


extension Bool {
    func to_go_bool() -> GoUint8 {
        self ? GoUint8(1) : GoUint8(0)
    }
}

