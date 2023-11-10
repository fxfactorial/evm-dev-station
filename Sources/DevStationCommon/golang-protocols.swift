import Foundation

public protocol EVMDriver {
    // done ported to the channel way
    func start_handling_bridge()
    func new_evm_singleton()
    func load_chaindata(pathdir: String, db_kind: String)
    func load_chainhead()
    func load_contract(addr: String, nickname: String, abi_json: String)
    func call(calldata: String, target_addr: String, msg_value: String) 
    func create_new_contract(code: String, creator_addr: String,
                             contract_nickname: String,
                             gas_amount: String, initial_gas: String) 
    func step_forward_one()

    // still open issues, that is not properly ported
    func keccak256(input: String) -> String

    func opcode_call_hook_enabled() -> Bool
    func enable_opcode_call_callback(yes_no: Bool)
    
    func enable_breakpoint_on_opcode(yes_no: Bool, opcode_name: String)
    func enable_breakpoint_on_opcode(yes_no: Bool)
    
    func available_eips() -> [Int]
    func all_known_opcodes() -> [String]
    func reset_evm(enableOpCodeCallback: Bool, enableCallback: Bool, useStateInMemory:  Bool)
}

