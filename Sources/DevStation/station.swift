import SwiftUI
import AppKit
import EVMBridge
import EVMUI
import DevStationCommon

@main
struct DevStation : App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var app_delegate

    var body : some Scene {
        WindowGroup {
            Rootview()
        }
    }
}

extension String {
    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }

    func to_go_string() -> GoString {
        let code = self
        let data = Data(code.utf8)
        let value = data.withUnsafeBytes { $0.baseAddress }!
        let result = value.assumingMemoryBound(to: CChar.self)
        let wrapped = GoString(p: result, n: self.count)
        return wrapped
    }

    func to_go_string2() -> GoString {
        let wrapped = self.data(using: .ascii)?.withUnsafeBytes {
            $0.baseAddress?.assumingMemoryBound(to: CChar.self)
        }!
        let as_g = GoString(p: wrapped, n: self.count)
        return as_g
    }


}



final class EVM: EVMDriver {
    static let shared = EVM()
    
    func create_new_contract(code: String) throws -> String {
        let data = Data(code.utf8)
        let value = data.withUnsafeBytes { $0.baseAddress }!
        let result = value.assumingMemoryBound(to: CChar.self)
        let wrapped = GoString(p: result, n: code.count)
        let result_deploy = EVMBridge.DeployNewContract(wrapped)
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
        let calldata_gstr = calldata.to_go_string2()
        let target_addr_gstr = target_addr.to_go_string2()
        let msg_value_gstr = msg_value.to_go_string2()

//        GoString
        print("about to call \(calldata_gstr) \(target_addr_gstr) \(msg_value_gstr)")

        let result_call = EVMBridge.CallEVM(
          calldata_gstr,
          target_addr_gstr,
          msg_value_gstr
        )
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
    
}

func convert(length: Int, data: UnsafePointer<Int>) -> [Int] {
    let buffer = UnsafeBufferPointer(start: data, count: length);
    return Array(buffer)
}

struct Rootview : View {
    var body : some View {
        VStack {
            EVMDevCenter(driver: EVM.shared)
        }.frame(width: 1024, height: 760, alignment: .center)
    }
}

@_cdecl("speak_from_go")
public func speak(num: Int32) {
    //    let del = NSApplication.shared.delegate as! AppDelegate
    // let rootView = NSApplication.shared.mainWindow?.contentView as? Rootview
    // rootView?.evm_state.stack.append("Called from golang, please update")
    // let is_main = Thread.isMainThread
    // print("did it updated? \(rootView) is it main thread \(is_main)")

    print("program counter called from golang what what \(num)")
    DispatchQueue.main.async {
        // EVMState.shared.name = "somethign else now \(num)"
        // let is_main = Thread.isMainThread

        // rootView?.evm_state.stack.append("Called from golang, please update in async queue")
        // print("in async queue \(is_main)")
    }

}

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var evm_driver: EVMDriver = EVM.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // critical otherwise won't be able to get input into gui, instead via CLI
        NSApp.setActivationPolicy(.regular)
        NSApp.windows[0].makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        evm_driver.new_evm_singleton()
    }

}
