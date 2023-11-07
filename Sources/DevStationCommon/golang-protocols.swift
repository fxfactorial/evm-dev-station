//
//  File.swift
//  
//
//  Created by Edgar Aroutiounian on 11/3/23.
//

import Foundation

public protocol EVMDriver {
    // done ported to the channel way
    func start_handling_bridge()
    func new_evm_singleton()
    func use_loaded_state_on_evm()
    func load_chaindata(pathdir: String, db_kind: String)
    func load_chainhead()
    func load_contract(addr: String, nickname: String, abi_json: String)


    // still open issues
    func keccak256(input: String) -> String
    // not sure how to do this as the get,set way without turning into existential type/observable later
    func exec_callback_enabled() -> Bool
    func enable_exec_callback(yes_no: Bool)
    
    func opcode_call_hook_enabled() -> Bool
    func enable_opcode_call_callback(yes_no: Bool)
    
    func enable_breakpoint_on_opcode(yes_no: Bool, opcode_name: String)
    func enable_breakpoint_on_opcode(yes_no: Bool)
    
    func create_new_contract(code: String, creator_addr: String) throws -> String
    func available_eips() -> [Int]
    func all_known_opcodes() -> [String]
    func call(calldata: String, target_addr: String, msg_value: String) -> EVMCallResult
    func reset_evm(enableOpCodeCallback: Bool, enableCallback: Bool, useStateInMemory:  Bool)
}

