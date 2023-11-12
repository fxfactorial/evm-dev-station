import Foundation

public protocol EVMDriver {
    func keccak256(input: String) -> String

    // done ported to the channel way
    func start_handling_bridge()
    func new_evm_singleton()
    func load_chaindata(chaindb_pathdir: String, db_kind: String, ancientdb_pathdir: String?, at_block: Int?)
    func load_chainhead()
    func load_contract(addr: String, nickname: String, abi_json: String)
    func call(calldata: String,
              caller_addr: String,
              target_addr: String,
              msg_value: String,
              gas_price: String,
              gas_limit: Int) 
    func create_new_contract(code: String, creator_addr: String,
                             contract_nickname: String,
                             gas_amount: String, initial_gas: String) 
    func step_forward_one()
    func all_known_opcodes() 
    func available_eips()
    func enable_breakpoint_on_opcode(yes_no: Bool, opcode_name: String)
    func enable_opcode_call_callback(yes_no: Bool)
    func enable_step_each_op(yes_no: Bool)
    func continue_evm_exec_break_on_opcode(yes_no: Bool, stack: [StackItem], mem: String)
    func continue_evm_exec_break_on_call(yes_no: Bool, caller: String, callee: String, payload: String)
    
    func read_contract_state(addr: String, key: String)
    func write_contract_state(addr: String, key: String, value: String)

    func evm_side_run(param: BridgeCmdEVMSideRun)
    
    // still open issues, that is not properly ported
    func reset_evm(enableOpCodeCallback: Bool, enableCallback: Bool, useStateInMemory:  Bool)
}


public final class StubEVMDriver: EVMDriver {
    public init() { }
    public func evm_side_run(param: BridgeCmdEVMSideRun) {}

    public func read_contract_state(addr: String, key: String) {}
    public func write_contract_state(addr: String, key: String, value: String) {}
    public func enable_step_each_op(yes_no: Bool) {}
    public func start_handling_bridge() {}
    public func step_forward_one(){}
    public func continue_evm_exec_break_on_opcode(yes_no: Bool, stack: [StackItem], mem: String) {}
    public func continue_evm_exec_break_on_call(yes_no: Bool, caller: String, callee: String, payload: String) {}
    public func keccak256(input: String) -> String {return input.sha3(.keccak256)}

    public func enable_breakpoint_on_opcode(yes_no: Bool, opcode_name: String) {}
    public func reset_evm(enableOpCodeCallback: Bool, 
                   enableCallback: Bool,
                   useStateInMemory: Bool) {}
    public func reset_evm() {}
    public func opcode_call_hook_enabled() -> Bool {false}
    public func enable_opcode_call_callback(yes_no: Bool) { }
    public func all_known_opcodes() { }
    public func create_new_contract(code: String, creator_addr: String,
                                    contract_nickname: String, gas_amount: String, initial_gas: String)  {}
    public func new_evm_singleton() {}
    public func available_eips() {}
    public func call(calldata: String,
              caller_addr: String,
              target_addr: String,
              msg_value: String,
              gas_price: String,
              gas_limit: Int) {}
    public func load_chaindata(
      chaindb_pathdir: String,
      db_kind: String,
      ancientdb_pathdir: String?,
      at_block: Int?) {}
    public func load_chainhead()  {}
    public func load_contract(addr: String, nickname: String, abi_json: String) {}
}
