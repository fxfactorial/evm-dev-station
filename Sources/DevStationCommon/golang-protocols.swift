//
//  File.swift
//  
//
//  Created by Edgar Aroutiounian on 11/3/23.
//

import Foundation

public protocol EVMDriver {
    
    // not sure how to do this as the get,set way without turning into existential type/observable later
    func exec_callback_enabled() -> Bool
    func enable_exec_callback(yes_no: Bool)
    
    func opcode_call_hook_enabled() -> Bool
    func enable_opcode_call_callback(yes_no: Bool)
    
    func create_new_contract(code: String, creator_addr: String) throws -> String
    func new_evm_singleton()
    func available_eips() -> [Int]
    func all_known_opcodes() -> [String]
    func call(calldata: String, target_addr: String, msg_value: String) -> EVMCallResult
    func load_chaindata(pathdir: String, db_kind: String) throws
    func load_chainhead() throws -> String
    func load_contract(addr: String) throws -> String
    func use_loaded_state_on_evm()
    func reset_evm(enableOpCodeCallback: Bool, enableCallback: Bool, useStateInMemory:  Bool)
}

public protocol ABIDriver {
    func add_abi(abi_json: String) throws -> Int
    func methods_for_abi(abi_id: Int) throws -> [String]
    func encode_arguments(abi_id: Int, args: [String]) throws -> String
}
