import SwiftUI
import AppKit
import EVMBridge

@main
struct DevStation : App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var app_delegate

    var body : some Scene {
        WindowGroup {
            Rootview()
        }
    }
}


class EVMState : ObservableObject {
    @Published var stack = [String]()
    @Published var name = "INITIAL"
    static let shared = EVMState()
}

struct Rootview : View {
    @StateObject var evm_state = EVMState.shared


    var body : some View {
        VStack {
            Text("hello \(evm_state.name)")
            Text("World")
            Button {
                print("a button was pressed")
                EVMBridge.CallGoFromSwift()
                print("called go from swift")
            } label : {
                Text("call into goland which should call back into swift code")
            }
            List {
                ForEach(evm_state.stack, id: \.self) { item in
                    Text(item)
                    
                }
            }
        }.frame(width: 400, height: 300, alignment: .center)
    }
}


@_cdecl("speak_from_go")
public func speak() {
//    let del = NSApplication.shared.delegate as! AppDelegate
    // let rootView = NSApplication.shared.mainWindow?.contentView as? Rootview
    // rootView?.evm_state.stack.append("Called from golang, please update")
    // let is_main = Thread.isMainThread
    // print("did it updated? \(rootView) is it main thread \(is_main)")

    EVMState.shared.name = "somethign else now"

    DispatchQueue.main.async {
        // let is_main = Thread.isMainThread

        // rootView?.evm_state.stack.append("Called from golang, please update in async queue")
        // print("in async queue \(is_main)")
    }

}

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("yes did laynch application")
    }

}
