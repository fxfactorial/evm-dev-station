//
//  File.swift
//  
//
//  Created by Edgar Aroutiounian on 11/3/23.
//

import Foundation
import DevStationCommon

final class StubABIDriver: ABIDriver {
    private var id = 0
    
    func add_abi(abi_json: String) throws -> Int {
        id += 1
        return id
    }

    func methods_for_abi(abi_id: Int) throws -> [String] {
        [
            "quoteExactInput",
            "quoteExactInputSingle",
            "quoteExactOutput",
            "quoteExactOutputSingle",
            "uniswapV3SwapCallback",
            "WETH9",
            "factory",
        ]
    }

    func encode_arguments(abi_id: Int, args: [String]) throws -> String {
        ""
    }
}

final class StubEVMDriver: EVMDriver {
    
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


    
    func use_loaded_state_on_evm() {
    }

    func all_known_opcodes() -> [String] {
        return ["PUSH1", "PUSH2"]
    }

    func create_new_contract(code: String, 
                             creator_addr new_addr: String) throws -> String {
        return "0x522B3294E6d06aA25Ad0f1B8891242E335D3B459"
    }
    
    func new_evm_singleton() {
        //
    }
    
    func available_eips() -> [Int] {
        return [12, 14, 15]
    }
 
    func call(calldata: String, target_addr: String, msg_value: String) -> EVMCallResult {
        if _cb_enabled {
            let new_one = ExecutedEVMCode(pc: "123", op_name: "PUSH0", opcode: "1234", gas: 123, gas_cost: 123, depth: 3, refund: 0)
            ExecutedOperations.shared.execed_operations.append(new_one)
        }

        return .success(return_value:"")
    }

    fileprivate var _cb_enabled: Bool = false

    func enable_exec_callback(yes_no: Bool) {
        _cb_enabled = yes_no
    }

    func exec_callback_enabled() -> Bool {
        _cb_enabled
    }

    func load_chaindata(pathdir: String, db_kind: String) throws {
        //
    }

    func load_chainhead() throws -> String {
        return ""
    }

    func load_contract(addr: String) throws -> String{
        return ""
    }
}
