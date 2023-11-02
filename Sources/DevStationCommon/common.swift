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
    
    func opcode_call_hook_enabled() -> Bool
    func enable_opcode_call_callback(yes_no: Bool)
    
    func create_new_contract(code: String) throws -> String
    func new_evm_singleton()
    func available_eips() -> [Int]
    func call(calldata: String, target_addr: String, msg_value: String) -> EVMCallResult
    func load_chaindata(pathdir: String, db_kind: String) throws
    func load_chainhead() throws -> String
    func load_contract(addr: String) throws -> String
    func use_loaded_state_on_evm()
}

public protocol ABIDriver {
    func add_abi(abi_json: String) throws -> Int
    func methods_for_abi(abi_id: Int) throws -> [String]
    func encode_arguments(abi_id: Int, args: [String]) throws -> String
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

public typealias continue_evm_exec_completion = (Bool, String, String, String) -> Void

public class OpcodeCallbackModel: ObservableObject {
    public static let shared = OpcodeCallbackModel()
    public var continue_evm_exec : continue_evm_exec_completion?
    @Published public var hit_breakpoint = false
    @Published public var current_caller = ""
    @Published public var current_callee = ""
    @Published public var current_args = ""
}

public enum DBKind : String {
    case InMemory = "in memory state"
    case GethDBPebble = "pebble based"
    case GethDBLevelDB = "leveldb based"
}


public class CurrentBlockHeader: ObservableObject {
    // although they are strings - its up to consuming
    // caller to format them as properly as needed
    @Published public var block_time : String = ""
    @Published public var block_number: UInt32 = 0
    @Published public var state_root : String = ""
    @Published public var parent_hash: String = ""
    public init() {
        
    }
    
}

/*
 {
 "parentHash": "0xb222f1a60364148ab5b44ee63a70bd31167d12f209f57c7bedc238dcc54c279c",
 "sha3Uncles": "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
 "miner": "0x4675c7e5baafbffbca748158becba61ef3b0a263",
 "stateRoot": "0xbffc5cf42c13f3705c397983e78565019900cc3cdabfb648cba10d0bbcccb6d7",
 "transactionsRoot": "0x8b9c117332bc178825ebe95f1617d10114ca07c0fc9b43ae49198c01840a3c0f",
 "receiptsRoot": "0x9a5197f42101d521ae4e98529a2ff0ab5965916369195b7662705d987947fd30",
 "logsBloom": "0x2333096445d9d32837c92187b0257dedb33320b778badde078b91514d4000229d86367f2c0142904b05d3bead655fd2f06250ac28c9ea8a47152e31de56a6fe44304d89ef0ea49c9b8f7fc2e702d16b28321038d9de39b083cb9b6ea993602a17b73e4f1e22f91eee50c74b145adea333e800ee39d572e0637745e9c4b0f8c5f3d28b5fc7563c7f2f97d40503b63b6e7444cbded89e47d3ec63a0edbe1bb9d71ff00fb40898c7ae03de1c4c196b617194c32a74627960dce279cdffbb62b1c6398db2e5fc371a17b145b99690038e2230134b9d6942a64f49b9e690b0439a1263f7c354ca3adc8ecbec4b6b85583fa542578fc26e9e82fc44e9d891dfb3a74df",
 "difficulty": "0x0",
 "number": "0x1194f40",
 "gasLimit": "0x1c9c380",
 "gasUsed": "0xf48ca3",
 "timestamp": "0x653aa2ef",
 "extraData": "0xd883010c00846765746888676f312e32302e37856c696e7578",
 "mixHash": "0x354b9832fcdb785feaf425d62bddc2ab9712395ba81cb3c58c60d7953394fa8f",
 "nonce": "0x0000000000000000",
 "baseFeePerGas": "0x79aeba5c9",
 "withdrawalsRoot": "0xa44f3d59b353ab74c62e216b1836afaf3924d91c4c68cc61b426e9d749bc9c4e",
 "blobGasUsed": null,
 "excessBlobGas": null,
 "parentBeaconBlockRoot": null,
 "hash": "0x8523036440976e7d0380fc0273cd778c2dea64ced9f656b7b9113e19e8afb6dd"
 }
 */
// MARK: - BlockHeader
public struct BlockHeader: Codable {
    public let parentHash, sha3Uncles, miner, stateRoot: String
    public let transactionsRoot, receiptsRoot, logsBloom, difficulty: String
    public let number, gasLimit, gasUsed, timestamp: String
    public let extraData, mixHash, nonce, baseFeePerGas: String
    public let withdrawalsRoot: String
    public let blobGasUsed, excessBlobGas, parentBeaconBlockRoot: JSONNull?
    public let hash: String
}

// MARK: - Encode/decode helpers

public class JSONNull: Codable, Hashable {
    
    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }
    
    public func hash(into hasher: inout Hasher) {
        // No-op
    }
    
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

// MARK: - ABIElement
public struct ABIElement: Codable, Equatable {
    public let inputs: [Put]
    public let stateMutability, type: String
    public let name: String?
    public let outputs: [Put]?
    public init(inputs: [Put], stateMutability: String, type: String, name: String?, outputs: [Put]?) {
        self.inputs = inputs
        self.stateMutability = stateMutability
        self.type = type
        self.name = name
        self.outputs = outputs
    }
}

// MARK: - Put
public struct Put: Codable, Equatable {
    public let internalType, name, type: String
    public init(internalType: String, name: String, type: String) {
        self.internalType = internalType
        self.name = name
        self.type = type
    }
}

public typealias SolidityABI = [ABIElement]

public let UNISWAP_QUOTER_ABI = """
[
  {
    "inputs": [
      { "internalType": "address", "name": "_factory", "type": "address" },
      { "internalType": "address", "name": "_WETH9", "type": "address" }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [],
    "name": "WETH9",
    "outputs": [{ "internalType": "address", "name": "", "type": "address" }],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "factory",
    "outputs": [{ "internalType": "address", "name": "", "type": "address" }],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "bytes", "name": "path", "type": "bytes" },
      { "internalType": "uint256", "name": "amountIn", "type": "uint256" }
    ],
    "name": "quoteExactInput",
    "outputs": [
      { "internalType": "uint256", "name": "amountOut", "type": "uint256" }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "address", "name": "tokenIn", "type": "address" },
      { "internalType": "address", "name": "tokenOut", "type": "address" },
      { "internalType": "uint24", "name": "fee", "type": "uint24" },
      { "internalType": "uint256", "name": "amountIn", "type": "uint256" },
      {
        "internalType": "uint160",
        "name": "sqrtPriceLimitX96",
        "type": "uint160"
      }
    ],
    "name": "quoteExactInputSingle",
    "outputs": [
      { "internalType": "uint256", "name": "amountOut", "type": "uint256" }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "bytes", "name": "path", "type": "bytes" },
      { "internalType": "uint256", "name": "amountOut", "type": "uint256" }
    ],
    "name": "quoteExactOutput",
    "outputs": [
      { "internalType": "uint256", "name": "amountIn", "type": "uint256" }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "address", "name": "tokenIn", "type": "address" },
      { "internalType": "address", "name": "tokenOut", "type": "address" },
      { "internalType": "uint24", "name": "fee", "type": "uint24" },
      { "internalType": "uint256", "name": "amountOut", "type": "uint256" },
      {
        "internalType": "uint160",
        "name": "sqrtPriceLimitX96",
        "type": "uint160"
      }
    ],
    "name": "quoteExactOutputSingle",
    "outputs": [
      { "internalType": "uint256", "name": "amountIn", "type": "uint256" }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "int256", "name": "amount0Delta", "type": "int256" },
      { "internalType": "int256", "name": "amount1Delta", "type": "int256" },
      { "internalType": "bytes", "name": "path", "type": "bytes" }
    ],
    "name": "uniswapV3SwapCallback",
    "outputs": [],
    "stateMutability": "view",
    "type": "function"
  }
]
"""
