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
        } else if let state = try? container.decode([StateRecord].self) {
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
    public init(kind: String, directory: String) {
        self.DBKind = kind
        self.Directory = directory
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
    public let TargetAddr: String
    public let MsgValue: String
    public init (_ calldata: String, _ target_addr: String, _ msg_value: String) {
        self.CallData = calldata
        self.TargetAddr = target_addr
        self.MsgValue = msg_value
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
    public let Value   : String
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
    
    case RUN_EVM_OP_EXECED = "ran_one_opcode"
    case RUN_EVM_OPCODE_HIT = "hit_break_on_opcode"
}
