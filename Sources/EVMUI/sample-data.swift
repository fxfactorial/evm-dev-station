import DevStationCommon
import SwiftUI

let sample_contract = LoadedContract(
    name: "local-compiled",
    bytecode: "608060405234801561000f575f80fd5b5061023b8061001d5f395ff3fe608060405234801561000f575f80fd5b5060043610610029575f3560e01c8063f4bd33381461002d575b5f80fd5b6100476004803603810190610042919061013f565b61005d565b604051610054919061018c565b60405180910390f35b5f808390505f607b8461007091906101d2565b905061007b81610088565b9050809250505092915050565b5f80600a8361009791906101d2565b9050600a816100a691906101d2565b915050919050565b5f80fd5b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f6100db826100b2565b9050919050565b6100eb816100d1565b81146100f5575f80fd5b50565b5f81359050610106816100e2565b92915050565b5f819050919050565b61011e8161010c565b8114610128575f80fd5b50565b5f8135905061013981610115565b92915050565b5f8060408385031215610155576101546100ae565b5b5f610162858286016100f8565b92505060206101738582860161012b565b9150509250929050565b6101868161010c565b82525050565b5f60208201905061019f5f83018461017d565b92915050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f6101dc8261010c565b91506101e78361010c565b92508282019050808211156101ff576101fe6101a5565b5b9291505056fea2646970667358221220d49e8c271999f56f086d72286cabdacdb88c39f281201c7a934057fe2bb86ae664736f6c63430008160033",
    address: "",
    abi_id: 3,
    method_names: ["WETH9", "quoteExactInputSingle"],
    abi: [
        ABIElement(inputs: [
            Put(internalType: "address", name: "tokenIn", type: "address"),
            Put(internalType: "address", name: "tokenOut", type: "address"),
            Put(internalType: "uint24", name: "fee", type: "uint24"),
            Put(internalType: "uint256", name: "amountIn", type: "uint256"),
            Put(internalType: "uint160", name: "sqrtPriceLimitX96", type: "uint160"),
        ],
                   stateMutability: "view",
                   type: "function",
                   name: "quoteExactInputSingle",
                   outputs: [])
        
    ],
    contract: try? EthereumContract(UNISWAP_QUOTER_ABI)
)

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
    
    func opcode_call_hook_enabled() -> Bool {
        false
    }

    func enable_opcode_call_callback(yes_no: Bool) {
        
    }


    
    func use_loaded_state_on_evm() {
    }

    func create_new_contract(code: String) throws -> String {
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
