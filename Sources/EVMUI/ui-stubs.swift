//
//  File.swift
//  
//
//  Created by Edgar Aroutiounian on 11/3/23.
//

import Foundation
import DevStationCommon

final class StubEVMDriver: EVMDriver {
    func start_handling_bridge() {}
    func step_forward_one(){}
    
    func keccak256(input: String) -> String {
        return input.sha3(.sha256)
    }

    func enable_breakpoint_on_opcode(yes_no: Bool) {
        //
    }
    
    func enable_breakpoint_on_opcode(yes_no: Bool, opcode_name: String) {
        //
    }
    

    func reset_evm(enableOpCodeCallback: Bool, 
                   enableCallback: Bool,
                   useStateInMemory: Bool) {
        //
    }

    func reset_evm() {
        //
    }
    
    func opcode_call_hook_enabled() -> Bool {
        false
    }

    func enable_opcode_call_callback(yes_no: Bool) {
        
    }

    func all_known_opcodes() -> [String] {
        return ["PUSH1", "PUSH2"]
    }

    func create_new_contract(code: String, creator_addr: String,
                             contract_nickname: String, gas_amount: String, initial_gas: String)  {
        //
    }
    
    func new_evm_singleton() {
        //
    }
    
    func available_eips() -> [Int] {
        return [12, 14, 15]
    }
 
    func call(calldata: String, target_addr: String, msg_value: String) {
        //
    }

    func load_chaindata(pathdir: String, db_kind: String) {
        //
    }

    func load_chainhead()  {
        //
    }

    func load_contract(addr: String, nickname: String, abi_json: String) {
        //
    }
}
