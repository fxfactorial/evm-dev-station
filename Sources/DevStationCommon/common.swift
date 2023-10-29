import SwiftUI

public enum EVMCallResult {
    case success(return_value: String)
    case failure(reason: String)
}

public protocol EVMDriver {

    // not sure how to do this as the get,set way without turning into existential type/observable later
    func exec_callback_enabled() -> Bool 
    func enable_exec_callback(yes_no: Bool)
        
    func create_new_contract(code: String) throws -> String
    func new_evm_singleton()
    func available_eips() -> [Int]
    func call(calldata: String, target_addr: String, msg_value: String) -> EVMCallResult

}

public struct ExecutedEVMCode: Identifiable{
    public let id = UUID()
    public let pc: String
    public let op_name : String
    public let opcode: String
    public let gas: Int
    public let gas_cost: Int
    public let depth : Int
    public let refund: Int

    public init(pc: String, op_name: String, opcode: String, gas: Int, gas_cost: Int, depth: Int, refund: Int) {
        self.pc = pc
        self.op_name = op_name
        self.opcode = opcode
        self.gas = gas
        self.gas_cost = gas_cost
        self.depth = depth
        self.refund = refund
    }
}

// REMEMBER When you want to have this be observed as a source of data
// for like a list or table, then have the View have a property wrapper of
// @ObservedObject private var thing = ExecutedOperation.shared
// and then use thing.execed_operations, then you can have it be used properly 
public class ExecutedOperations : ObservableObject {
    public static let shared = ExecutedOperations()
    
    @Published public var execed_operations: [ExecutedEVMCode] = [
        .init(pc: "0x07c9", op_name: "DUP2", opcode: "0x81", gas: 20684, gas_cost: 3, depth: 3, refund: 0),
        .init(pc: "0x07c9", op_name: "JUMP", opcode: "0x56", gas: 20684, gas_cost: 8, depth: 3, refund: 0)
    ]
    
}
