import SwiftUI

public class LoadChainModel: ObservableObject {
    public static let shared = LoadChainModel()
    @Published public var chaindata_directory = ""
    @Published public var is_chain_loaded = false
    @Published public var show_loading_db = false
    @Published public var db_kind : DBKind = .InMemory
//    public init(chaindata_directory: String = "",
//                is_chain_loaded: Bool = false,
//                show_loading_db: Bool = false,
//                db_kind: DBKind = .InMemory) {
//        self.chaindata_directory = chaindata_directory
//        self.is_chain_loaded = is_chain_loaded
//        self.show_loading_db = show_loading_db
//        self.db_kind = db_kind
//    }
}

public class ErrorFeedbackModel: ObservableObject {
    public static let hsared = ErrorFeedbackModel()
    // issues from when running the EVM
    @Published public var EVMError = ""
    // issues from 
    @Published public var UIInputError = ""
}

public struct EVMCall : Identifiable {
    public let id = UUID()
    public let address_name : String
    public let calldata : String
    public var children: [EVMCall]?
}


public struct ExecutedEVMCode: Identifiable, Hashable{
    public let id = UUID()
    // easiest when they are all strings
    public let pc: String
    public let op_name : String
    public let opcode: String
    public let gas: String
    public let gas_cost: String
    public let depth : String
    public let refund: String
    
    public init(
        pc: String, op_name: String, opcode: String,
        gas: Int, gas_cost: Int, depth: Int, refund: Int) {
        self.pc = pc
        self.op_name = op_name
        self.opcode = opcode
        self.gas = "\(gas)"
        self.gas_cost = "\(gas_cost)"
        self.depth = "\(depth)"
        self.refund = "\(refund)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

// REMEMBER When you want to have this be observed as a source of data
// for like a list or table, then have the View have a property wrapper of
// @ObservedObject private var thing = ExecutedOperation.shared
// and then use thing.execed_operations, then you can have it be used properly
public class ExecutedOperations : ObservableObject {
    public static let shared = ExecutedOperations()
    
    @Published public var execed_operations: [ExecutedEVMCode] = []
    @Published public var call_tree : [CallEvaled] = []
    @Published public var state_records : [StateRecord] = []
}

public class EVMRunStateControls: ObservableObject {
    public static let shared = EVMRunStateControls()

    @Published public var breakpoint_on_call = false
    @Published public var opcode_breakpoints_enabled = false
    @Published public var contract_currently_running = false
    @Published public var record_storage_keys = false
    @Published public var call_return_value = ""
    @Published public var evm_error = ""
}

public class BlockContextModel : ObservableObject {
    public static let shared = BlockContextModel()

    @Published public var coinbase = ""
    @Published public var base_gas = ""
    @Published public var base_gas_tip = ""
    @Published public var time = ""

    public func reset() {
        coinbase = ""
        base_gas = ""
        base_gas_tip = ""
        time = ""
    }
}


public class Item: ObservableObject {
    public let id = UUID()
    public let index : Int
    @Published public var name: String = ""
    public init(name: String, index: Int) {
        self.name = name
        self.index = index
    }
}

extension Item: Hashable {
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


public typealias continue_evm_exec_completion = (Bool, String, String, String) -> Void
public typealias continue_opcode_exec_completion = (Bool, [Item], String) -> Void

public class OpcodeCallbackModel: ObservableObject {
    public static let shared = OpcodeCallbackModel()
    public var continue_evm_exec : continue_evm_exec_completion?
    public var continue_evm_exec_break_on_opcode : continue_opcode_exec_completion?
    
    @Published public var hit_breakpoint = false
    @Published public var current_caller = ""
    @Published public var current_callee = ""
    @Published public var current_args = ""
    // how to update these effectively
    @Published public var current_stack : [Item] = [
//        Item(name: "0x01", index: 0),
//        Item(name: "0x02", index: 1),
//        Item(name: "0x03", index: 2)
    ]
    @Published public var selected_stack_item: Item?
    @Published public var current_memory = ""
    @Published public var current_opcode_hit = ""
    @Published public var use_modified_values = false
    public var current_opcode_continue_task : Task<Void, Error>?

    public func reset() {
        hit_breakpoint = false
        current_caller = ""
        current_callee = ""
        current_args = ""
        current_stack = []
        current_memory = ""
        current_opcode_hit = ""
        use_modified_values = false
        selected_stack_item = nil
    }
}

public enum DBKind : String {
    case InMemory = "in memory state"
    case GethDBPebble = "pebble based"
    case GethDBLevelDB = "leveldb based"
}


public class CurrentBlockHeader: ObservableObject {
    public static let shared = CurrentBlockHeader()

    // although they are strings - its up to consuming
    // caller to format them as properly as needed
    @Published public var block_time : String = ""
    @Published public var block_number: UInt32 = 0
    @Published public var state_root : String = ""
    @Published public var parent_hash: String = ""
    public init() {}
    
}

public class LoadedContracts: ObservableObject {
    public static let shared = LoadedContracts()
    @Published public var contracts : [LoadedContract] = []
    @Published public var current_selection: LoadedContract?
    public init() {}
}

public class RuntimeError: ObservableObject {
    public static let shared = RuntimeError()
    @Published public var show_error = false
    @Published public var error_reason = ""
}

public class LoadedContract : ObservableObject, Hashable, Equatable {
    static public func == (lhs: LoadedContract, rhs: LoadedContract) -> Bool {
        lhs.id == rhs.id
    }
    
    @Published public var name : String = ""
    @Published public var bytecode: String = ""
    @Published public var deployed_bytecode = ""
    @Published public var address : String = ""
    public let id = UUID() // maybe just the address next time
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    @Published public var contract: EthereumContract?
    @Published public var is_loaded_against_state = false
    @Published public var eth_balance = "0"
    @Published public var deployer_address : String = "0x0000000000000000000000000000000000000000"
    @Published public var gas_limit_deployment: String = "900000"
    @Published public var deployment_gas_cost = 0


    public init(name: String,
                bytecode: String,
                address: String,
                contract: EthereumContract? = nil,
                is_loaded_against_state: Bool = false
    ) {
        self.name = name
        self.bytecode = bytecode
        self.address = address
        self.contract = contract
        self.is_loaded_against_state = is_loaded_against_state
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


// MARK: - SignatureLookup
public struct SignatureLookup: Codable {
    let count: Int
    let next, previous: JSONNull?
    public let results: [Result]
}

// MARK: - Result
public struct Result: Codable {
    let id: Int
    public let createdAt, textSignature, hexSignature, bytesSignature: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case textSignature = "text_signature"
        case hexSignature = "hex_signature"
        case bytesSignature = "bytes_signature"
    }
}

public let SIG_DIR_URL = "https://www.4byte.directory"
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
