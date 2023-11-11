import SwiftUI
import AppKit
import EVMBridge
import EVMUI
import DevStationCommon
import AsyncAlgorithms

@main
struct DevStation : App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var app_delegate
    @AppStorage("prefer_dark_mode") private var prefer_dark = true
    @AppStorage("enable_full_debug") private var enable_loud_debugging = false

    var body : some Scene {
        WindowGroup {
            Rootview()
              .preferredColorScheme(prefer_dark ? .dark : .light)
        }
    }
}

final class EVM: EVMDriver {
    
    static let shared = EVM()
    let comm_channel = AsyncChannel<Data>()

    func start_handling_bridge() {
        Task.detached {
            EVMBridge.MakeChannelAndListenThread(true.to_go_bool())
            EVMBridge.MakeChannelAndReplyThread(true.to_go_bool())

            for await msg in self.comm_channel {
                String(data: msg, encoding: .utf8)!.withCString {
                    $0.withMemoryRebound(to: CChar.self, capacity: msg.count) {
                        EVMBridge.UISendCmd(GoString(p: $0, n: msg.count))
                    }
                }
            }
        }

    }
    
    func enable_breakpoint_on_opcode(yes_no: Bool, opcode_name: String) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage<BridgeCmdDoHookOnOpCode>(c: .CMD_DO_HOOK_ON_OPCODE,
                               p: BridgeCmdDoHookOnOpCode(opcode: opcode_name, enable: yes_no))
            )
            await comm_channel.send(msg)
        }

    }

    func reset_evm(enableOpCodeCallback: Bool,
                   enableCallback: Bool,
                   useStateInMemory: Bool) {
        // EVMBridge.ResetEVM(
        //   enableOpCodeCallback.to_go_bool(),
        //   enableCallback.to_go_bool(),
        //   useStateInMemory.to_go_bool()
        // )
    }


    func create_new_contract(code: String, creator_addr: String,
                             contract_nickname: String, gas_amount: String,
                             initial_gas: String)  {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(c: .CMD_DEPLOY_NEW_CONTRACT,
                               p: BridgeCmdDeployNewContract(
                                 code, creator_addr, contract_nickname,
                                 Int(gas_amount)!, initial_gas))
            )
            await comm_channel.send(msg)
        }

    }

    func new_evm_singleton() {
        Task {
            let msg = try! JSONEncoder().encode(EVMBridgeMessage<Int>(c: .CMD_NEW_EVM, p: 0))
            await comm_channel.send(msg)
        }
    }

    func keccak256(input: String) -> String {
        return input.sha3(.keccak256)
    }

    func available_eips() {
        Task {
            let msg = try! JSONEncoder().encode(EVMBridgeMessage<Int>(c: .CMD_ALL_KNOWN_EIPS, p: 0))
            await comm_channel.send(msg)
        }
    }
    
    func call(calldata: String,
              caller_addr: String,
              target_addr: String,
              msg_value: String,
              gas_price: String,
              gas_limit: Int) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(
                c: .CMD_RUN_CONTRACT,
                p: BridgeCmdRunContract(
                  calldata: calldata,
                  caller_addr: caller_addr,
                  target_addr:target_addr,
                  msg_value:msg_value,
                  gas_price: gas_price,
                  gas_limit: gas_limit
                )
              )
            )
            await comm_channel.send(msg)
        }
    }

    func enable_opcode_call_callback(yes_no: Bool) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(
                c: .CMD_DO_PAUSE_ON_CALL, p: BridgeCmdDoPauseOnCall(b: yes_no)
              )
            )
            await comm_channel.send(msg)
        }
    }

    func load_chaindata(chaindb_pathdir: String, db_kind: String, ancientdb_pathdir: String?, at_block: Int?) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(c: .CMD_LOAD_CHAIN,
                               p: BridgeCmdLoadChain(kind: db_kind,
                                                     directory: chaindb_pathdir,
                                                     ancientdb_directory: ancientdb_pathdir == nil ? "" : ancientdb_pathdir!,
                                                     at_block_num: at_block
                                                    ))
            )
            await comm_channel.send(msg)
        }
    }
    
    func load_chainhead() {
        Task {
            let msg = try! JSONEncoder().encode(EVMBridgeMessage<Int>(c: .CMD_REPORT_CHAIN_HEAD, p: 0))
            await comm_channel.send(msg)
        }
    }

    func step_forward_one() {
        Task {
            let msg = try! JSONEncoder().encode(EVMBridgeMessage<Int>(c: .CMD_STEP_FORWARD_ONE,p: 0))
            await comm_channel.send(msg)
        }
    }

    func load_contract(addr: String, nickname: String, abi_json: String) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(c: .CMD_LOAD_CONTRACT_FROM_STATE,
                               p: BridgeCmdLoadContractFromState(s: addr,
                                                                 nick: nickname,
                                                                 abi_json: abi_json))
            )
            await comm_channel.send(msg)
        }
    }

    func all_known_opcodes(){
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage<Int>(c: .CMD_ALL_KNOWN_OPCODES, p: 0)
            )
            await comm_channel.send(msg)
        }
    }

    func continue_evm_exec_break_on_call(yes_no: Bool, caller: String, callee: String, payload: String) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage<BridgeCmdContinuePausedEVMInCall>(
                c: .CMD_CONTINUE_PAUSED_EVM_IN_CALL,
                p: BridgeCmdContinuePausedEVMInCall(
                  do_use: yes_no, caller: caller, callee: callee, args: payload
                )
              )
            )
            await comm_channel.send(msg)
        }
    }

    func continue_evm_exec_break_on_opcode(yes_no: Bool, stack: [Item], mem: String) {
        let just_hex_ints = stack.map({$0.name})
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage<BridgeCmdOverwrittenStackMemory>(
                c: .CMD_OVERWRITE_STACK_MEM_IN_PAUSED_EVM,
                p: BridgeCmdOverwrittenStackMemory(
                  stack: just_hex_ints,mem: mem, do_use: yes_no
                )
              )
            )
            await comm_channel.send(msg)
        }
    }

}

struct Rootview : View {
    var body : some View {
        VStack {
            EVMDevCenter(driver: EVM.shared)
        }.frame(minWidth: 580, idealWidth: 1480, minHeight: 460, idealHeight: 950, alignment: .center)
    }
}

@_cdecl("send_error_back")
public func send_error_back(reply: UnsafeMutablePointer<CChar>) {
    let rpy = String(cString: reply)
    free(reply)
    RuntimeError.shared.show_error = true
    RuntimeError.shared.error_reason = rpy
}

@_cdecl("send_cmd_back")
public func send_cmd_back(reply: UnsafeMutablePointer<CChar>) {
    let rpy = String(cString: reply)
    free(reply)
    let decoded = try! JSONDecoder().decode(EVMBridgeMessage<AnyDecodable>.self, from: rpy.data(using: .utf8)!)

    switch decoded.Cmd  {
    case .RUN_EVM_OP_EXECED:
        let execed_op = decoded.Payload!.value as! Dictionary<String, AnyDecodable>
        let num = execed_op["program_counter"]?.value as! Int
        let gas_cost_static = execed_op["gas_cost_static"]?.value as! Int
        let gas_cost_dynamic = execed_op["gas_cost_dynamic"]?.value as! Int
        let gas_cost_total = execed_op["gas_cost_total"]?.value as! Int

        let opcode_name = execed_op["opcode_name"]?.value as! String
        let opcode_num = execed_op["opcode_hex"]?.value as! String
        
        DispatchQueue.main.async {
            ExecutedOperations.shared.total_static_gas_cost_so_far += gas_cost_static
            ExecutedOperations.shared.total_dynamic_gas_cost_so_far += gas_cost_dynamic
            ExecutedOperations.shared.total_gas_cost_so_far += gas_cost_total

            ExecutedOperations.shared.execed_operations.append(
              ExecutedEVMCode(pc: "\(num)",
                              op_name: opcode_name,
                              opcode: opcode_num,
                              gas: gas_cost_static,
                              gas_cost: gas_cost_static,
                              depth: 3,
                              refund: 0
              )
            )
        }

    case .CMD_NEW_EVM:
        print("loaded new evm")
    case .CMD_LOAD_CHAIN:
        EVM.shared.load_chainhead()
    case .CMD_ALL_KNOWN_EIPS:
        var eips = decoded.Payload!.value as! [String]
        eips.sort()
        DispatchQueue.main.async {
            for c in eips {
                EVMRunStateControls.shared.eips_used.append(.init(num: c))
            }
        }
        

    case .CMD_ALL_KNOWN_OPCODES:
        var opcodes = decoded.Payload!.value as! [String]
        opcodes.sort()
        DispatchQueue.main.async {
            for c in opcodes {
                EVMRunStateControls.shared.opcodes_used.append(.init(name: c))
            }
        }

    case .CMD_LOAD_CONTRACT_FROM_STATE:
        let loaded = decoded.Payload!.value as! Dictionary<String, String>
        let contract = LoadedContract(
          name: loaded["nickname"]!,
          bytecode: loaded["code"]!,
          address: loaded["address"]!,
          contract: try? EthereumContract(loaded["abi_json"]!)
        )
        
        DispatchQueue.main.async {
            LoadedContracts.shared.contracts.append(contract)
            withAnimation {
                LoadedContracts.shared.current_selection = contract
            }
        }

    case .RUN_EVM_STATE_TOUCHED:
        let record = decoded.Payload!.value as! StateRecord
        DispatchQueue.main.async {
            ExecutedOperations.shared.state_records.append(record)
        }
    case .CMD_RUN_CONTRACT:
        let call_result = decoded.Payload!.value as! Dictionary<String, AnyDecodable>
        let tree = call_result["CallTreeJSON"]?.value as! CallEvaled

        DispatchQueue.main.async {
            OpcodeCallbackModel.shared.hit_breakpoint = false
            EVMRunStateControls.shared.contract_currently_running = false
            EVMRunStateControls.shared.call_return_value = call_result["ReturnValue"]?.value as! String
            ExecutedOperations.shared.call_tree = [tree]
        }

    case .CMD_DEPLOY_NEW_CONTRACT:
        let reply = decoded.Payload!.value as! Dictionary<String, AnyDecodable>
        let gas_used = reply["gas_used"]?.value as! Int
        let new_addr = reply["new_contract_addr"]?.value as! String
        let deployed_code = reply["return_value"]?.value as! String
        let name = reply["name"]?.value as! String
        let contract = LoadedContracts.shared.contracts.filter({ $0.name == name }).first
        if let c = contract {
            DispatchQueue.main.async {
                withAnimation {
                    c.is_loaded_against_state = true
                    c.address  = new_addr
                    c.deployed_bytecode = deployed_code
                    c.deployment_gas_cost = gas_used
                    // Hack awesome way to force state to update
                    LoadedContracts.shared.objectWillChange.send()
                }
            }
        }
        // TODO need to update the current contract selection, its gas cost used to deploy, etc

    case .CMD_REPORT_CHAIN_HEAD:
        let blk_header = decoded.Payload!.value as! Dictionary<String, String?>
        let head_number = UInt32(blk_header["number"]!!.dropFirst(2), radix: 16)!
        let state_root = blk_header["stateRoot"]!!
        let ts_int = UInt(blk_header["timestamp"]!![2...], radix: 16)!
        let ts = Date(timeIntervalSince1970: TimeInterval(ts_int))
        
        DispatchQueue.main.async {
            withAnimation {
                LoadChainModel.shared.is_chain_loaded = true
                LoadChainModel.shared.show_loading_db = false
                BlockContextModel.shared.coinbase = blk_header["miner"]!!
                BlockContextModel.shared.time = ts.ISO8601Format()
                CurrentBlockHeader.shared.block_number = head_number
                CurrentBlockHeader.shared.state_root = state_root
                // TODO come back to this one
                // chaindb.db_kind = if db_kind == "pebble" { .GethDBPebble} else { .GethDBLevelDB }
            }
        }
    case .RUN_EVM_OPCODE_HIT:
        let reply = decoded.Payload!.value as! Dictionary<String, AnyDecodable>
        let memory_hex = reply["memory"]?.value as! String
        let opcode = reply["opcode"]?.value as! String
        let stack = reply["stack"]?.value as! [String]
        let stack_rep = stack.enumerated().map({ (idx, name) in Item(name: name, index: idx )})
        
        DispatchQueue.main.async {
            OpcodeCallbackModel.shared.current_stack = stack_rep
            OpcodeCallbackModel.shared.current_memory = memory_hex
            OpcodeCallbackModel.shared.current_opcode_hit = opcode
            OpcodeCallbackModel.shared.hit_breakpoint = true
        }
    case .RUN_EVM_CALL_HIT:
        let reply = decoded.Payload!.value as! Dictionary<String, AnyDecodable>
        let caller = reply["caller"]?.value as! String
        let callee = reply["callee"]?.value as! String
        let args = reply["args"]?.value as! String
        let value = reply["value"]?.value as! String
        
        DispatchQueue.main.async {
            OpcodeCallbackModel.shared.current_args = args
            OpcodeCallbackModel.shared.current_callee = callee
            OpcodeCallbackModel.shared.current_caller = caller
            OpcodeCallbackModel.shared.hit_breakpoint = true
        }
        
    default:
        DispatchQueue.main.async {
            RuntimeError.shared.show_error = true
            RuntimeError.shared.error_reason = "unhandled reply \(decoded)"
        }

        print("unknown command received", decoded)
    }

}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var evm_driver: any EVMDriver = EVM.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        evm_driver.start_handling_bridge()
        evm_driver.new_evm_singleton()
        evm_driver.all_known_opcodes()
        evm_driver.available_eips()

        // critical otherwise won't be able to get input into gui, instead via CLI
        NSApp.setActivationPolicy(.regular)
        NSApp.windows[0].makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

}
