import SwiftUI

public let VALUE = 123

public enum EVMCallResult {
    case success(return_value: String)
    case failure(reason: String)
}

public protocol EVMDriver {
    func create_new_contract(code: String) throws -> String
    func new_evm_singleton()
    func available_eips() -> [Int]
    func call(calldata: String, target_addr: String, msg_value: String) -> EVMCallResult
}
