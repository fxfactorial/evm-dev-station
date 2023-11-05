import SwiftUI
import AppKit
import EVMBridge
import EVMUI
import DevStationCommon

@main
struct DevStation : App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var app_delegate
    @AppStorage("prefer_dark_mode") private var prefer_dark = true

    var body : some Scene {
        WindowGroup {
            Rootview().preferredColorScheme(prefer_dark ? .dark : .light)
        }
    }
}

extension String {
    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }

    // These are all wrong because they holdonto the pointer!
    func to_go_string() -> GoString {
        let code = self
        let data = Data(code.utf8)
        let value = data.withUnsafeBytes { $0.baseAddress }!
        let result = value.assumingMemoryBound(to: CChar.self)
        let wrapped = GoString(p: result, n: self.count)
        return wrapped
    }

    func to_go_string2() -> GoString {
        //        let copy = String(self)
        let copy = self
        let wrapped = copy.data(using: .ascii)?.withUnsafeBytes {
            $0.baseAddress?.assumingMemoryBound(to: CChar.self)
        }!
        let as_g = GoString(p: wrapped, n: copy.count)
        return as_g
    }

    func to_go_string3() -> GoString {
        let wrapped = self.data(using: .utf8)?.withUnsafeBytes {
            $0.baseAddress?.assumingMemoryBound(to: CChar.self)
        }!
        let as_g = GoString(p: wrapped, n: self.count)
        return as_g
    }
    
    func as_go_string() -> GoString {
        let payload = self.withCString {pointee in
            pointee.withMemoryRebound(to: CChar.self, capacity: self.count) {
                GoString(p: $0, n: self.count)
            }
        }
        return payload
    }


}

final class ABIEncoder: ABIDriver {
    static let shared = ABIEncoder()
    private var abi_id = 0

    func add_abi(abi_json: String) throws -> Int {
        abi_id += 1
        let id = abi_id
        EVMBridge.AddABI(GoInt(abi_id), abi_json.to_go_string2())
        return id
    }

    func methods_for_abi(abi_id: Int) throws -> [String] {
        let methods_result = EVMBridge.MethodsForABI(GoInt(abi_id))
        var method_names = [String]()
        let buffer = UnsafeBufferPointer(start: methods_result.r0, count: Int(methods_result.r1))
        let wrapped = Array(buffer)

        for i in wrapped {
            let method = String(cString: i!)
            free(i!)
            method_names.append(method)
        }

        free(methods_result.r0)
        return method_names
    }

    func encode_arguments(abi_id: Int, args: [String]) throws -> String {
        ""
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

    func use_loaded_state_on_evm() {
        EVMBridge.UseLoadedStateOnEVM()
    }

    // NOTE THIS IS WRONG NEED TO DO WITH THE SCOPED POINTER THING
    func create_new_contract(code: String, creator_addr: String) throws -> String {
        var code = code
        code.makeContiguousUTF8()
        let data = Data(code.utf8)
        let value = data.withUnsafeBytes { $0.baseAddress }!
        let result = value.assumingMemoryBound(to: CChar.self)
        let wrapped = GoString(p: result, n: code.count)

        let data_ = Data(creator_addr.utf8)
        let value_ = data_.withUnsafeBytes { $0.baseAddress }!
        let result_ = value_.assumingMemoryBound(to: CChar.self)
        let wrapped_ = GoString(p: result_, n: creator_addr.count)

        
        let result_deploy = EVMBridge.DeployNewContract(wrapped, wrapped_)
        if result_deploy.is_error {
            let error_wrapped = Data(bytes: result_deploy.error_reason, count: result_deploy.error_reason_size)
            free(result_deploy.error_reason)
            let error_str = String(bytes: error_wrapped, encoding: .utf8)!
            throw EVMError.deploy_issue(reason: error_str)
        } 

        let new_addr = Data(bytes: result_deploy.new_contract_addr, count: 42)
        let addr_str = String(bytes: new_addr, encoding: .utf8)!
        free(result_deploy.new_contract_addr)
        return addr_str
    }

    func new_evm_singleton() {
        EVMBridge.NewGlobalEVM()
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
    
    func call(calldata: String, target_addr: String, msg_value: String) -> EVMCallResult {
        let calldata = calldata
        let target_addr = target_addr
        let msg_value = msg_value
        print("SWIFT using OG values:", calldata, " ", target_addr, " ", msg_value)
//        print("about to call \(calldata_gstr) \(target_addr_gstr) \(msg_value_gstr)")
        let result_call = msg_value.withCString {msg_value_pointee in
            let msg_value_gstr = msg_value_pointee.withMemoryRebound(to: CChar.self, capacity: msg_value.count) {
                GoString(p: $0, n: msg_value.count)
            }

            return calldata.withCString { calldata_pointee in
                let calldata_gstr = calldata_pointee.withMemoryRebound(to: CChar.self, capacity: calldata.count) {
                    GoString(p: $0, n: calldata.count)
                }
                
                return target_addr.withCString { target_addr_pointee in
                    let target_addr_gstr = target_addr_pointee.withMemoryRebound(to: CChar.self, capacity: target_addr.count) {
                        GoString(p: $0, n: target_addr.count)
                    }

                    return EVMBridge.CallEVM(
                        calldata_gstr,
                        target_addr_gstr,
                        msg_value_gstr
                    )
                }
            }
        }
        

        if result_call.error_reason_size > 0 {
            let error_wrapped = Data(bytes: result_call.error_reason, count: result_call.error_reason_size)
            let error_str = String(bytes: error_wrapped, encoding: .utf8)!
            free(result_call.error_reason)
            return .failure(reason: error_str)
        }

        if result_call.call_return_size > 0 {
            let result_wrapped = Data(bytes: result_call.call_return_value, count: result_call.call_return_size)
            let result_str = String(bytes: result_wrapped, encoding: .utf8)!
            free(result_call.call_return_value)
            return .success(return_value: result_str)
        }
        return .success(return_value: "")
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

    
    
    fileprivate var _cb_enabled : Bool = false

    func enable_exec_callback(yes_no: Bool) {
        if yes_no {
            EVMBridge.EnableCallback(GoUint8(1))
        } else {
            EVMBridge.EnableCallback(GoUint8(0))
        }
        _cb_enabled = yes_no
    }
    
    func exec_callback_enabled() -> Bool {
        return _cb_enabled
    }
    
    func load_chaindata(pathdir: String, db_kind: String) throws {
        let started = Date.now
        print("swift starting loading chain \(started) - \(pathdir) - \(db_kind)")
        let db_kind = db_kind.trimmingCharacters(in: .whitespacesAndNewlines)
        let pathdir = pathdir.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = pathdir.to_go_string2()
        let kind = switch db_kind {
        case "pebble":GoInt(0)
        case "leveldb":GoInt(1)
        default:
            throw EVMError.load_chaindata_problem("db kind wasnt pebble or leveldb")
        }
        let result = EVMBridge.LoadChainData(path, kind)
        let finished = Date.now
        print("finished loading chain \(finished)")
        if result.error_reason_size > 0 {
            let error_wrapped = Data(bytes: result.error_reason, count: result.error_reason_size)
            let error_str = String(bytes: error_wrapped, encoding: .utf8)!
            free(result.error_reason)
            throw EVMError.load_chaindata_problem(error_str)
//            return .failure(reason: error_str)
        }
    }
    
    func load_chainhead() throws -> String {
        let result = EVMBridge.ChainHead()
        let wrapped = String(cString: result.chain_head_json)
        free(result.chain_head_json)
        return wrapped
    }

    func load_contract(addr: String) throws -> String {
        let result = EVMBridge.LoadCodeFromState(addr.to_go_string2())
        let wrapped = Data(bytes: result.r0, count: Int(result.r1))
        let contract = String(bytes: wrapped, encoding: .utf8)!
        free(result.r0)
        return contract
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
            EVMDevCenter(driver: EVM.shared, abi_driver: ABIEncoder.shared)
        }.frame(minWidth: 780, idealWidth: 1480, minHeight: 660, idealHeight: 950, alignment: .center)
    }
}

//@_cdecl("chain_load_finished")
//public func chain_load_finished() {
//    let when_done = Date.now
//    print("finished loading chain at \(when_done)")
//}
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

@_cdecl("evm_run_callback")
public func evm_run_callback(
  num: Int32,
  // TODO Remember to free the pointers to cchar
  opcode_name: UnsafeMutablePointer<CChar>,
  opcode_hex: UnsafeMutablePointer<CChar>,
  gas_cost: Int
) {
    let opcode = String(cString: opcode_name)
    let opcode_num = String(cString: opcode_hex)
    free(opcode_name)
    free(opcode_hex)

    DispatchQueue.main.async {
        ExecutedOperations.shared.execed_operations.append(
          ExecutedEVMCode(pc: "\(num)",
                          op_name: opcode,
                          opcode: opcode_num,
                          gas: gas_cost,
                          gas_cost: gas_cost,
                          depth: 3,
                          refund: 0
          )
        )
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var evm_driver: any EVMDriver = EVM.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        evm_driver.new_evm_singleton()
        EVMBridge.UseInMemoryStateOnEVM()
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
