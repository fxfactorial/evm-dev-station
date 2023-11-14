import SwiftUI

public class LoadChainModel: ObservableObject {
    public static let shared = LoadChainModel()
    @Published public var chaindata_directory = ""
    @Published public var is_chain_loaded = false
    @Published public var show_loading_db = false
    @Published public var db_kind : DBKind = .InMemory
    @Published public var ancientdb_dir = ""
    @Published public var at_block_number = ""
    public func reset() {
        chaindata_directory = ""
        is_chain_loaded = false
        ancientdb_dir = ""
        at_block_number = ""
    }
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

public struct OPCodeFreq {
    public let name : String
    public var count: Int
    public var invokers : [String:Int] // their addrs + times they called
    public init(name: String, count: Int, invokers: [String : Int]) {
        self.name = name
        self.count = count
        self.invokers = invokers
    }
}


// REMEMBER When you want to have this be observed as a source of data
// for like a list or table, then have the View have a property wrapper of
// @ObservedObject private var thing = ExecutedOperation.shared
// and then use thing.execed_operations, then you can have it be used properly
public class ExecutedOperations : ObservableObject {
    public static let shared = ExecutedOperations()
    
    @Published public var execed_operations: [ExecutedEVMCode] = []
    @Published public var total_static_gas_cost_so_far = 0
    @Published public var total_dynamic_gas_cost_so_far = 0
    @Published public var total_gas_cost_so_far = 0
    @Published public var call_tree : [CallEvaled] = []
    @Published public var state_records : [StateRecord] = []
    @Published public var opcode_freq : [String: OPCodeFreq] = [:]
        // :
//        "PUSH1":   .init(name: "PUSH1", count: 100, invokers: ["0x01":100]),
//        "CALL":    .init(name: "CALL", count: 20, invokers: ["0x01":10, "0x02":10]),
//        "ADDRESS": .init(name: "ADDRESS", count: 30, invokers: ["0x01":20, "0x03":10])
//    ]
    
    public func reset() {
        execed_operations = []
        state_records = []
        call_tree = []
        total_static_gas_cost_so_far = 0
        total_dynamic_gas_cost_so_far = 0
        total_gas_cost_so_far = 0
        opcode_freq = [:]
    }
}

public struct OPCodeEnable: Identifiable {
    public let id = UUID()
    public let name : String
    public var enabled: Bool = false
    public init(name: String) {
        self.name = name
    }
}

public struct EIP : Identifiable {
    public let id = UUID()
    public let num : String
    public var enabled = true
    public init(num: String) {
        self.num = num
    }
}

public class CallParams : ObservableObject {
    public var calldata : String = ""
    public var caller_addr: String = ""
    public var caller_eth_bal = ""
    public var target_addr: String = ""
    public var gas_price: String = ""
    public var gas_limit : String = ""
    public var msg_value : String = "0"
}

public class EVMRunStateControls: ObservableObject {
    public static let shared = EVMRunStateControls()

    @Published public var breakpoint_on_call = false
    @Published public var step_each_op = false
    @Published public var opcode_breakpoints_enabled = false
    @Published public var contract_currently_running = false
    @Published public var record_storage_keys = false
    @Published public var call_return_value = ""
    @Published public var evm_error = ""
    @Published public var opcodes_used :[OPCodeEnable] = []
    @Published public var eips_used :[EIP] = []
    @Published public var current_call_params = CallParams()

    public func reset() {
        evm_error = ""
        call_return_value = ""
        breakpoint_on_call = false
        opcode_breakpoints_enabled = false
        contract_currently_running = false
        step_each_op = false
    }

}

public class TransactionLookupModel: ObservableObject {
    public static let shared = TransactionLookupModel()
    @Published public var to_addr = ""
    @Published public var from_addr = ""
    @Published public var input_calldata = ""
//    @Published public var current_lookup
}

public class BlockContextModel : ObservableObject {
    public static let shared = BlockContextModel()

    @Published public var coinbase = ""
    @Published public var base_gas = ""
    @Published public var base_gas_tip = ""
    @Published public var time = ""
    @Published public var gas_limit = ""
    @Published public var gas_used = ""
    
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

public class StackItem: ObservableObject, Hashable {
    public let id = UUID()
    public let index : Int
    @Published public var name: String = ""
    @Published public var pretty: String = ""

    public init(name: String, index: Int, pretty: String) {
        self.name = name
        self.index = index
        self.pretty = pretty
    }

    public static func == (lhs: StackItem, rhs: StackItem) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public class OpcodeCallbackModel: ObservableObject {
    public static let shared = OpcodeCallbackModel()
    
    @Published public var hit_breakpoint = false
    @Published public var current_caller = ""
    @Published public var current_callee = ""
    @Published public var current_args = ""
    // how to update these effectively
    @Published public var current_stack : [StackItem] = [
//        Item(name: "0x01", index: 0),
//        Item(name: "0x02", index: 1),
//        Item(name: "0x03", index: 2)
    ]
    @Published public var selected_stack_item: Item?
    @Published public var current_memory = ""
    @Published public var current_opcode_hit = ""
    @Published public var use_modified_values = false

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
    case GethDBPebble = "pebble"
    case GethDBLevelDB = "leveldb"
}

public class CurrentBlockHeader: ObservableObject {
    public static let shared = CurrentBlockHeader()

    @Published public var block_time : String = ""
    @Published public var block_number: String = ""
    @Published public var state_root : String = ""
    @Published public var parent_hash: String = ""
    @Published public var raw_block_header: BlockHeader?
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
    public func reset() {
        show_error = false
        error_reason = ""
    }
}

public class StateChange: ObservableObject, Identifiable, Hashable {
    public let id = UUID()
    public var nice_name: String
    @Published public var key: String
    @Published public var original_value: String
    @Published public var new_value: String
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public init(nice_name: String, key: String, original_value: String, new_value: String) {
        self.nice_name = nice_name
        self.key = key
        self.original_value = original_value
        self.new_value = new_value
    }
    
    static public func == (lhs: StateChange, rhs: StateChange) -> Bool {
        lhs.id == rhs.id
    }

}

public struct RunHistory {
    public let input : CallParams
    public let error_result: String
    public let success_result: String
}

public class RunHistoryModel : ObservableObject {
    static public let shared = RunHistoryModel()
    @Published public var history : [RunHistory] = []
}

public class StateChanges: ObservableObject {
    @Published public var overrides : [StateChange] = []
    @Published public var temp_key = ""
    @Published public var temp_value = ""
}

public class SideEVMResult: ObservableObject {
    static public let shared = SideEVMResult()
    @Published public var call_input = ""
    @Published public var call_result = ""
}

public class CommonABIsModel: ObservableObject {
    public static let shared = CommonABIsModel()
    @Published public var abis : [String: [ABI.Element.Function]] = [:]
    @Published public var all_methods : [ABI.Element.Function] = []

    init() {
        let jsonData = ERC20_ABI.data(using: .utf8)
        let abis = try! JSONDecoder().decode([ABI.Record].self, from: jsonData!)
        self.abis = try! abis.map({ try! $0.parse() }).getFunctions()
        for (k, _) in self.abis {
            if k.hasHexPrefix() {
                self.abis.removeValue(forKey: k)
            }
            if !k.hasSuffix(")") {
                self.abis.removeValue(forKey: k)
            }
        }
        let abis_copy = try! JSONDecoder().decode([ABI.Record].self, from: jsonData!)
        let copy = try! abis_copy.map({ try! $0.parse() }).getFunctions()
        
        let allMethods = copy.filter { pair in
            let data = Data.fromHex(pair.key)
            return data?.count == 4
        }.values.flatMap { $0 }
        all_methods = allMethods
    }

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
    @Published public var state_overrides = StateChanges()
    
    public init(name: String,
                bytecode: String,
                address: String,
                contract: EthereumContract? = nil,
                is_loaded_against_state: Bool = false
//                state_overrides: [StateChange] = []
    ) {
        self.name = name
        self.bytecode = bytecode
        self.address = address
        self.contract = contract
        self.is_loaded_against_state = is_loaded_against_state
//        self.state_overrides = state_overrides
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
            throw DecodingError.typeMismatch(JSONNull.self,
                                             DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
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

public let EMPTY_HASH = "0x0000000000000000000000000000000000000000000000000000000000000000"

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


public let ERC20_ABI = """
  [
    {
        "constant": true,
        "inputs": [],
        "name": "name",
        "outputs": [
            {
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "spender",
                "type": "address"
            },
            {
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "approve",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "totalSupply",
        "outputs": [
            {
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "from",
                "type": "address"
            },
            {
                "name": "to",
                "type": "address"
            },
            {
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "transferFrom",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "decimals",
        "outputs": [
            {
                "name": "",
                "type": "uint8"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "name": "owner",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "name": "balance",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "symbol",
        "outputs": [
            {
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "to",
                "type": "address"
            },
            {
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "transfer",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "name": "owner",
                "type": "address"
            },
            {
                "name": "spender",
                "type": "address"
            }
        ],
        "name": "allowance",
        "outputs": [
            {
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "payable": true,
        "stateMutability": "payable",
        "type": "fallback"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "name": "owner",
                "type": "address"
            },
            {
                "indexed": true,
                "name": "spender",
                "type": "address"
            },
            {
                "indexed": false,
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Approval",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "name": "from",
                "type": "address"
            },
            {
                "indexed": true,
                "name": "to",
                "type": "address"
            },
            {
                "indexed": false,
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Transfer",
        "type": "event"
    }
    ]
"""
