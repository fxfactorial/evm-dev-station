import Foundation

public struct EVMBridgeMessage<P: Codable> : Codable {
    public let Cmd: EVMCommand
    public let Payload: P?
    public init(c : EVMCommand, p: P?) {
        self.Cmd = c
        self.Payload = p
    }

    public init(c: EVMCommand) {
        self.Cmd = c
        self.Payload = nil
    }
}

public struct AnyDecodable : Codable {
    
    public let value : Any 
    
    public init<T>(_ value :T?) {
        self.value = value ?? ()
    }

    public func encode(to encoder: Encoder) throws {
        // no-op whatever
    }

    
    public init(from decoder :Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let strs = try? container.decode([String].self) {
            self.init(strs)
        } else if let ints = try? container.decode([Int].self) {
            self.init(ints)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let state = try? container.decode(StateRecord.self) {
            self.init(state)
        } else if let call_evaled = try? container.decode(CallEvaled.self) {
            self.init(call_evaled)
        } else if let kv = try? container.decode([String:String].self) {
            self.init(kv)
        } else if let kv = try? container.decode([String:String?].self) {
            self.init(kv)
        } else if let kv = try? container.decode([String: AnyDecodable].self) {
            self.init(kv)
        } else if let kv = try? container.decode([AnyDecodable].self) {
            self.init(kv)
        } else {
            self.init(())
        }
        // handle all the different types including bool, array, dictionary, double etc
    }
}

public struct BridgeCmdLoadChain : Codable {
    public let DBKind:     String 
    public let Directory:  String
    public let AncientDBDirectory : String
    public let AtSpecificNumber : Int?
    public init(kind: String, directory: String, ancientdb_directory: String = "", at_block_num: Int? = nil) {
        self.DBKind = kind
        self.Directory = directory
        self.AncientDBDirectory = ancientdb_directory
        self.AtSpecificNumber = at_block_num
    }
}


public struct BridgeCmdLoadContractFromState: Codable {
    public let Addr: String
    public let Nickname: String
    public let ABIJSON: String
    public init(s : String, nick: String, abi_json: String) {
        self.Addr = s
        self.Nickname = nick
        self.ABIJSON = abi_json
    }
}

public struct BridgeCmdRunContract: Codable {
    public let CallData: String
    public let CallerAddr: String
    public let TargetAddr: String
    public let MsgValue: String
    public let GasPrice: String
    public let GasLimit: Int
    public init (calldata: String,
                 caller_addr: String,
                 target_addr: String,
                 msg_value: String,
                 gas_price: String,
                 gas_limit: Int
    ) {
        self.CallData = calldata
        self.CallerAddr = caller_addr
        self.TargetAddr = target_addr
        self.MsgValue = msg_value
        self.GasPrice = gas_price
        self.GasLimit = gas_limit
    }
}

public struct BridgeCmdDeployNewContract: Codable {
    public let CreationCode: String
    public let CreatorAddr: String
    public let Nickname: String
    public let GasAmount: Int
    public let InitialEthOnContract: String
    public init(
      _ creation: String, _ creator_addr: String, _ nickname: String,
      _ gas_amount: Int, _ init_eth_on_contract: String
    ) {
        self.CreationCode = creation
        self.CreatorAddr = creator_addr
        self.Nickname = nickname
        self.GasAmount = gas_amount
        self.InitialEthOnContract = init_eth_on_contract
    }
}

public struct CallEvaled: Codable, Identifiable {
    public let id = UUID()
    public let Caller: String
    public let Target: String
    public let CallData: String
    public let Kind: String
    public let Children: [CallEvaled]?

    public var icon: String { // makes things prettier
        if Children == nil {
            return "doc"
        } else if Children?.isEmpty == true {
            return "folder"
        } else {
            return "folder.fill"
        }
    }
}

public struct StateRecord: Codable, Identifiable, Hashable {
    public let id = UUID()
    public let Address: String
    public let Key     : String
    public let BeforeValue   : String
    public let AfterValue   : String
    public let Kind    : String
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct BridgeCmdDoHookOnOpCode: Codable {
    public let OpCode: String
    public let Enable: Bool
    public init(opcode: String, enable: Bool)  {
        self.OpCode = opcode
        self.Enable = enable
    }
}

public struct BridgeCmdOverwrittenStackMemory : Codable {
    public let SerializedStack: [String]
    public let Memory:          String
    public let UseOverrides:    Bool
    public init(stack: [String], mem: String, do_use: Bool) {
        self.SerializedStack = stack
        self.Memory = mem
        self.UseOverrides = do_use
    }
}

public struct BridgeCmdDoPauseOnCall : Codable {
    public let Enable: Bool
    public init(b : Bool) {
        self.Enable = b
    }
}

public struct BridgeCmdDoPauseEachTime : Codable {
    public let Enable: Bool
    public init(b : Bool) {
        self.Enable = b
    }
}

public struct BridgeCmdContinuePausedEVMInCall : Codable {
    public let UseOverrides: Bool
    public let Caller:       String
    public let Callee:       String
    public let Args:         String
    public init(do_use: Bool, caller: String, callee: String, args: String) {
        self.UseOverrides = do_use
        self.Caller = caller
        self.Callee = callee
        self.Args = args
    }
}

public struct BridgeCmdStateLookup : Codable {
    public let ContractAddr: String
    public let Key:          String
    public init(addr: String, key: String) {
        self.ContractAddr = addr
        self.Key = key
    }
}

public struct BridgeCmdStateWrite : Codable {
    public let ContractAddr: String
    public let Key: String
    public let NewValue: String
    public init(addr: String, key: String, new_value: String) {
        self.ContractAddr = addr
        self.Key = key
        self.NewValue = new_value
    }
}

public enum EVMCommand : String, Codable {
    case CMD_REPORT_ERROR = "error"
    case CMD_NEW_EVM = "new_evm"
    case CMD_LOAD_CHAIN = "load_chaindb"
    case CMD_REPORT_CHAIN_HEAD = "report_chain_head"
    case CMD_LOAD_CONTRACT_FROM_STATE = "load_contract_from_state"
    case CMD_RUN_CONTRACT = "run_contract"
    case CMD_DEPLOY_NEW_CONTRACT = "deploy_new_contract"
    case CMD_STEP_FORWARD_ONE = "step_once"
    case CMD_ALL_KNOWN_OPCODES = "all_known_opcodes"
    case CMD_ALL_KNOWN_EIPS = "all_known_eips"
    case CMD_DO_HOOK_ON_OPCODE = "do_hook_on_opcode"
    case CMD_OVERWRITE_STACK_MEM_IN_PAUSED_EVM = "overwrite_stack_mem_paused"
    case CMD_DO_PAUSE_ON_CALL = "do_hook_on_call"
    case CMD_CONTINUE_PAUSED_EVM_IN_CALL = "cont_evm_break_on_call"
    case CMD_STEP_ONE_BY_ONE = "enable_step_by_step"
    case CMD_STATE_LOOKUP = "get_state"
    case CMD_STATE_WRITE = "write_state"
    
    // keep a space
    case RUN_EVM_OP_EXECED = "ran_one_opcode"
    case RUN_EVM_OPCODE_HIT = "hit_break_on_opcode"
    case RUN_EVM_CALL_HIT = "hit_call"
    case RUN_EVM_STATE_TOUCHED = "running_evm_state_touched"

}
