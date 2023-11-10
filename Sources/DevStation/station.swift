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
    @AppStorage("show_first_load_help") private var show_help_msg = true
    @AppStorage("enable_full_debug") private var enable_loud_debugging = false

    var body : some Scene {
        WindowGroup {
            Rootview()
              .preferredColorScheme(prefer_dark ? .dark : .light)
        }
    }
}

extension String {
    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }
}


extension Bool {
    func to_go_bool() -> GoUint8 {
        self ? GoUint8(1) : GoUint8(0)
    }
}

final class EVM: EVMDriver {
    func enable_breakpoint_on_opcode(yes_no: Bool) {
        EVMBridge.EnableHookEveryOpcode(yes_no.to_go_bool())
    }
    
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
        opcode_name.withCString {pointee in
            let opcode_name_gstr = pointee.withMemoryRebound(to: CChar.self, capacity: opcode_name.count) {
                GoString(p: $0, n: opcode_name.count)
            }
            EVMBridge.DoHookOnOpcode(yes_no.to_go_bool(), opcode_name_gstr)
        }
    }

    func reset_evm(enableOpCodeCallback: Bool,
                   enableCallback: Bool,
                   useStateInMemory: Bool) {
        EVMBridge.ResetEVM(
          enableOpCodeCallback.to_go_bool(),
          enableCallback.to_go_bool(),
          useStateInMemory.to_go_bool()
        )
    }


    func create_new_contract(code: String, creator_addr: String,
                             contract_nickname: String, gas_amount: String, initial_gas: String)  {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(c: CMD_DEPLOY_NEW_CONTRACT,
                               p: BridgeCmdDeployNewContract(
                                 code, creator_addr, contract_nickname,
                                 Int(gas_amount)!, initial_gas))
            )
            await comm_channel.send(msg)
        }

    }

    func new_evm_singleton() {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage<BridgeCmdNewGlobalEVM>(c: CMD_NEW_EVM, p: BridgeCmdNewGlobalEVM())
            )
            await comm_channel.send(msg)
        }
    }

    func keccak256(input: String) -> String {
        return input.sha3(.sha256)

//        return input.withCString {
//            let g_str = GoString(p: $0, n: input.count)
//            let result = EVMBridge.Keccak256(g_str)
//            let copy = String(cString: result!)
//            free(result)
//            return copy
//        }
    }

    func available_eips() -> [Int] {
        let eips = EVMBridge.AvailableEIPS()
        let elem_count = Int(eips.r1)
        let rebound = eips.r0.withMemoryRebound(to: Int.self, capacity: elem_count) {
            Array(UnsafeBufferPointer(start: $0, count: elem_count))
        }
        free(eips.r0)
        return rebound
    }
    
    func call(calldata: String, target_addr: String, msg_value: String) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(
                c: CMD_RUN_CONTRACT, p: BridgeCmdRunContract(calldata, target_addr, msg_value)
              )
            )
            await comm_channel.send(msg)
        }
    }

    fileprivate var _opcode_call_hook_enabled = false

    func opcode_call_hook_enabled() -> Bool {
        return _opcode_call_hook_enabled
    }

    func enable_opcode_call_callback(yes_no: Bool) {
        if yes_no {
            EVMBridge.EnableOPCodeCallHook(yes_no.to_go_bool())
        } else {
            EVMBridge.EnableOPCodeCallHook(yes_no.to_go_bool())
        }
        _opcode_call_hook_enabled = yes_no
    }
    
    func load_chaindata(pathdir: String, db_kind: String) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(c: CMD_LOAD_CHAIN,
                               p: BridgeCmdLoadChain(kind: db_kind, directory: pathdir))
            )
            await comm_channel.send(msg)
        }
    }
    
    func load_chainhead() {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(c: CMD_REPORT_CHAIN_HEAD,
                               p: BridgeCmdSendBackChainHeader())
            )
            await comm_channel.send(msg)
        }
    }

    func step_forward_one() {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(c: CMD_STEP_FORWARD_ONE,
                               p: BridgeCmdStepForwardOnce())
            )
            await comm_channel.send(msg)
        }
    }

    func load_contract(addr: String, nickname: String, abi_json: String) {
        Task {
            let msg = try! JSONEncoder().encode(
              EVMBridgeMessage(c: CMD_LOAD_CONTRACT_FROM_STATE,
                               p: BridgeCmdLoadContractFromState(s: addr,
                                                                 nick: nickname,
                                                                 abi_json: abi_json))
            )
            await comm_channel.send(msg)
        }

        // let result = EVMBridge.LoadCodeFromState(addr.to_go_string2())
        // let wrapped = Data(bytes: result.r0, count: Int(result.r1))
        // let contract = String(bytes: wrapped, encoding: .utf8)!
        // free(result.r0)
        // return contract
    }

    func all_known_opcodes() -> [String] {
        let codes = EVMBridge.AllKnownOpcodes()
        let elem_count = Int(codes.r1)
        var known = [String]()
        let buf = codes.r0.withMemoryRebound(to: UnsafePointer<CChar>.self, capacity: elem_count) {
            Array(UnsafeBufferPointer(start: $0, count: elem_count))
        }
        for i in buf {
            let s = String(cString: i)
            free(UnsafeMutableRawPointer(mutating: i))
            known.append(s)
        }
        
        free(codes.r0)
        return known
    }
}

func convert(length: Int, data: UnsafePointer<Int>) -> [Int] {
    let buffer = UnsafeBufferPointer(start: data, count: length);
    return Array(buffer)
}

struct Rootview : View {
    var body : some View {
        VStack {
            EVMDevCenter(driver: EVM.shared)
        }.frame(minWidth: 580, idealWidth: 1480, minHeight: 460, idealHeight: 950, alignment: .center)
    }
}

@_cdecl("evm_opcode_callback")
public func evm_opcode_callback(
    opcode_name: UnsafeMutablePointer<CChar>,
    stack: UnsafeMutablePointer<UnsafeMutablePointer<CChar>>,
    stack_size: Int,
    memory: UnsafeMutablePointer<CChar>
) {
    let opcode = String(cString: opcode_name)
    free(opcode_name)

    var stack_rep = [Item]()
    let buf = stack.withMemoryRebound(to: UnsafePointer<CChar>.self, capacity: stack_size) {
        Array(UnsafeBufferPointer(start: $0, count: stack_size))
    }


    for (name, index) in zip(buf, buf.indices) {
        let s = String(cString: name)
        free(UnsafeMutableRawPointer(mutating: name))
        stack_rep.append(Item(name: s, index: index))
    }
                         
    free(stack)
    let memory_hex = String(cString: memory)
    free(memory)
    print("SWIFT-> current opcode ", opcode, stack_rep, memory_hex)
    
    DispatchQueue.main.async {
        OpcodeCallbackModel.shared.current_stack = stack_rep
        OpcodeCallbackModel.shared.current_memory = memory_hex
        OpcodeCallbackModel.shared.current_opcode_hit = opcode
        OpcodeCallbackModel.shared.hit_breakpoint = true
    }
}



@_cdecl("evm_opcall_callback")
public func evm_opcall_callback(
    caller_: UnsafeMutablePointer<CChar>,
    callee_: UnsafeMutablePointer<CChar>,
    args_: UnsafeMutablePointer<CChar>
) {
    let caller = String(cString: caller_)
    let callee = String(cString: callee_)
    let args = String(cString: args_)
    free(caller_)
    free(callee_)
    free(args_)

    DispatchQueue.main.async {
        OpcodeCallbackModel.shared.current_args = args
        OpcodeCallbackModel.shared.current_callee = callee
        OpcodeCallbackModel.shared.current_caller = caller
        OpcodeCallbackModel.shared.hit_breakpoint = true
    }

    print("SWIFT call back from running EVM \(caller)-\(callee)-\(args)")
    // EVMBridge.SendValueToPausedEVMInCall()
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

    switch decoded.Cmd {
    case RUN_EVM_OP_EXECED:
        let execed_op = decoded.Payload!.value as! Dictionary<String, AnyDecodable>
        let num = execed_op["program_counter"]?.value as! Int
        let gas_cost = execed_op["gas_cost"]?.value as! Int
        let opcode_name = execed_op["opcode_name"]?.value as! String
        let opcode_num = execed_op["opcode_hex"]?.value as! String

        DispatchQueue.main.async {
            ExecutedOperations.shared.execed_operations.append(
              ExecutedEVMCode(pc: "\(num)",
                              op_name: opcode_name,
                              opcode: opcode_num,
                              gas: gas_cost,
                              gas_cost: gas_cost,
                              depth: 3,
                              refund: 0
              )
            )
        }

    case CMD_NEW_EVM:
        print("loaded new evm")
    case CMD_LOAD_CHAIN:
        EVM.shared.load_chainhead()
        
    case CMD_LOAD_CONTRACT_FROM_STATE:
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

    case CMD_RUN_CONTRACT:
        let call_result = decoded.Payload!.value as! Dictionary<String, AnyDecodable>
        let tree = call_result["CallTreeJSON"]?.value as! CallEvaled
        let state_tracking = call_result["State"]?.value as! [StateRecord]

//        let state = call_result["State"]?.value as []
        DispatchQueue.main.async {
            OpcodeCallbackModel.shared.hit_breakpoint = false
            EVMRunStateControls.shared.contract_currently_running = false
            EVMRunStateControls.shared.call_return_value = call_result["ReturnValue"]?.value as! String
            ExecutedOperations.shared.call_tree = [tree]
            ExecutedOperations.shared.state_records = state_tracking
        }

    case CMD_DEPLOY_NEW_CONTRACT:
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

    case CMD_REPORT_CHAIN_HEAD:
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
    default:
        print("unknown command received", decoded)
    }

}



final class AppDelegate: NSObject, NSApplicationDelegate {
    var evm_driver: any EVMDriver = EVM.shared


    func applicationDidFinishLaunching(_ notification: Notification) {
        evm_driver.start_handling_bridge()
        evm_driver.new_evm_singleton()

        OpcodeCallbackModel.shared.continue_evm_exec_break_on_opcode = {do_use, stack, memory in
            let just_hex_ints = stack.map({$0.name})
            print("should be calling evm bridge now", do_use, just_hex_ints)
            let encoded = try? JSONEncoder().encode(just_hex_ints)
            guard let s = encoded else {
                EVMBridge.SendValueToPausedEVMInOpCode(false.to_go_bool(), GoString(p: nil, n: 0), GoString(p: nil, n: 0))
                return
            }
            
            s.withUnsafeBytes {
                let stack_gstr = GoString(p: $0, n: s.count)
                memory.withCString {
                    let memory_gstr =  GoString(p: $0, n: memory.count)
                    // but actually this showed a bug anyway
                    EVMBridge.SendValueToPausedEVMInOpCode(do_use.to_go_bool(), stack_gstr, memory_gstr)
                }
            }
        }

        OpcodeCallbackModel.shared.continue_evm_exec = { do_use, caller, callee, args in
            caller.withCString({ caller_pointee in
                let caller_gstr = caller_pointee.withMemoryRebound(to: CChar.self, capacity: caller.count) {
                    GoString(p: $0, n: caller.count)
                }
                
                callee.withCString { callee_pointee in
                    let callee_gstr = callee_pointee.withMemoryRebound(to: CChar.self, capacity: callee.count) {
                        GoString(p: $0, n: callee.count)
                    }
                    args.withCString { args_pointee in
                        let args_gstr = args_pointee.withMemoryRebound(to: CChar.self, capacity: args.count) {
                            GoString(p: $0, n: args.count)
                        }
                        EVMBridge.SendValueToPausedEVMInCall(
                            do_use.to_go_bool(),
                            caller_gstr,
                            callee_gstr,
                            args_gstr
                        )
                    }
                }
            })
        }

        // critical otherwise won't be able to get input into gui, instead via CLI
        NSApp.setActivationPolicy(.regular)
        NSApp.windows[0].makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

}
