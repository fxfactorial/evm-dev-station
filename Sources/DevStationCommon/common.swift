import SwiftUI

public let VALUE = 123

public protocol EVMDriver {
    func create_new_contract(code: String) throws
    func new_evm_singleton()
    func available_eips() -> [Int]
}
