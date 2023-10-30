import SwiftUI

public enum EVMCallResult {
    case success(return_value: String)
    case failure(reason: String)
}

public enum EVMError : Error {
    case deploy_issue(reason: String)
    case load_chaindata_problem(String)
}

// TODO rename to backend golang code interface, something cause
// we also load up the database and such
public protocol EVMDriver {

    // not sure how to do this as the get,set way without turning into existential type/observable later
    func exec_callback_enabled() -> Bool 
    func enable_exec_callback(yes_no: Bool)
        
    func create_new_contract(code: String) throws -> String
    func new_evm_singleton()
    func available_eips() -> [Int]
    func call(calldata: String, target_addr: String, msg_value: String) -> EVMCallResult
    func load_chaindata(pathdir: String, db_kind: String) throws
}

public struct ExecutedEVMCode: Identifiable{
    public let id = UUID()
    // easiest when they are all strings
    public let pc: String
    public let op_name : String
    public let opcode: String
    public let gas: String
    public let gas_cost: String
    public let depth : String
    public let refund: String

    public init(pc: String, op_name: String, opcode: String, gas: Int, gas_cost: Int, depth: Int, refund: Int) {
        self.pc = pc
        self.op_name = op_name
        self.opcode = opcode
        self.gas = "\(gas)"
        self.gas_cost = "\(gas_cost)"
        self.depth = "\(depth)"
        self.refund = "\(refund)"
    }
}

// REMEMBER When you want to have this be observed as a source of data
// for like a list or table, then have the View have a property wrapper of
// @ObservedObject private var thing = ExecutedOperation.shared
// and then use thing.execed_operations, then you can have it be used properly 
public class ExecutedOperations : ObservableObject {
    public static let shared = ExecutedOperations()
    
    @Published public var execed_operations: [ExecutedEVMCode] = []
    
}
