import Foundation

public struct EVMBridgeMessage<P: Codable> : Codable {
    public let Cmd: String
    public let Payload: P?
    public init(c : String, p: P) {
        self.Cmd = c
        self.Payload = p
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
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let kv = try? container.decode([String:String?].self) {
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

public struct BridgeCmdSendBackChainHeader: Codable {
    public init() {}
}

public struct BridgeCmdNewGlobalEVM: Codable {
    public init() { }
}

// TODO change to enum
public let CMD_NEW_EVM = "new_evm"
public let CMD_LOAD_CHAIN = "load_chaindb"
public let CMD_REPORT_ERROR = "error"
public let CMD_REPORT_CHAIN_HEAD = "report_chain_head"
