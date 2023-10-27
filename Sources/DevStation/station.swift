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

final class EVM: EVMDriver{
    static let shared = EVM()
    
    func create_new_contract(code: String) throws {
        let data = Data(code.utf8)
        let value = data.withUnsafeBytes { $0.baseAddress }!
        let result = value.assumingMemoryBound(to: CChar.self)
        let wrapped = GoString(p: result, n: code.count)
        let result_deploy = EVMBridge.DeployNewContract(wrapped)
        if result_deploy.is_error {
            let error_wrapped = Data(bytes: result_deploy.error_reason, count: result_deploy.error_reason_size)
            let error_str = String(bytes: error_wrapped, encoding: .utf8)!
            print("received error in swift code! \(error_str)")
            throw EVMError.deploy_issue(reason: error_str)
        } 
//        print("recevied what \(result_deploy)")
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
        print("in swift - available eips actually was \(rebound)")
        defer {
            free(eips.r0)
        }
        return rebound
        // let converted = convert(length: elem_count,
        //                         data: UnsafePointer(eips.data))


//        let loaded = eips.data.
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
