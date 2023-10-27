//
//  SwiftUIView.swift
//
//
//  Created by Edgar Aroutiounian on 10/24/23.
//

import SwiftUI

public protocol EVMDriver {
    func create_new_contract(code: String) throws
    func new_evm_singleton()
}

struct BlockContext : View {
    @State fileprivate var coinbase: String = ""
    @State fileprivate var base_gas: String = ""
    
    var body : some View {
        VStack {
            Text("Block Context")
                .font(.system(size: 14, weight: .bold))
            HStack {
                Text("Coinbase")
                TextField("0x..", text: $coinbase)
            }
            HStack {
                Text("Base Gas Price")
                TextField("base gas", text: $base_gas)
            }
        }
    }
}

class EVMState : ObservableObject {
    @Published var calldata : String = ""
}

struct ExecutedEVMCode: Identifiable {
    let id = UUID()
    
    let pc: String
    let op_name : String
    let opcode: String
    let gas: Int
    let gas_cost: Int
    let depth : Int
    let refund: Int
}


struct LoadedContract : Identifiable, Hashable {
    let name : String
    let bytecode: String
    let address : String
    let id = UUID() // maybe just the address next time
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Collection {
    /// Returns the element at the specified index if it exists, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public enum EVMError : Error {
    case deploy_issue(reason: String)
}


public struct EVMDevCenter<Driver: EVMDriver> : View {

    @State private var bytecode_add = false
    @State private var new_contract_name = ""
    @State private var new_contract_bytecode = ""
    @State private var new_contract_abi = ""
    @State private var current_code_running = ""
    @State private var current_tab = 0
    @State private var calldata = ""
    let d : Driver
    
    @State private var execed_operations: [ExecutedEVMCode] = [
        .init(pc: "0x07c9", op_name: "DUP2", opcode: "0x81", gas: 20684, gas_cost: 3, depth: 3, refund: 0),
        .init(pc: "0x07c9", op_name: "JUMP", opcode: "0x56", gas: 20684, gas_cost: 8, depth: 3, refund: 0)
    ]
    
    public init(driver : Driver) {
        d = driver
    }
    
    
    @State private var loaded_contracts : [LoadedContract] = [
        .init(name: "uniswapv3", bytecode: "123", address: "0x1256"),
        .init(name: "compound", bytecode: "456", address: "0x1234"),
        sample_contract
    ]
        
    @State private var selected_contract_idx : LoadedContract?
    @State private var deploy_contract_result = ""
    
    public var body: some View {
        
        TabView(selection: $current_tab,
                content:  {
            VStack {
                HStack {
                    NavigationStack {
                        VStack {
                            Text("Loaded contracts")
                                .font(.system(size:14, weight: .bold))
                                .help("interact with contracts loaded")
                            List(loaded_contracts, id:\.self, selection: $selected_contract_idx) { item in
                                Text(item.name)
                            }
                            .frame(maxWidth: 200)
                            .padding([.trailing, .leading])
                        }
                    }
                    VStack {
                        HStack {
                            if let contract = selected_contract_idx {
                                VStack {
                                    Text("Contract bytecode")
                                        .font(.system(size: 14, weight: .bold))
                                    ScrollView {
                                        Text(contract.bytecode)
                                          .lineLimit(nil)
//                                          .lineLimit(20, reservesSpace: true)
                                          .frame(maxWidth:.infinity, maxHeight:.infinity)
                                          .background()
                                    }
                                }
                            } else {
                                Text("select a contract from sidebar ")
                            }
                            VStack {
                                Text("Loaded Details")
                                Button {
                                    if let contract = selected_contract_idx {
                                        do {
                                            try d.create_new_contract(code: contract.bytecode)
                                        } catch EVMError.deploy_issue(let reason){
                                            deploy_contract_result = reason
                                        }  catch {
                                            //
                                        }
                                    }
                                } label: {
                                    Text("Try deploy contract")
                                }
                                HStack {
                                    Text("deploy result")
                                    Text(deploy_contract_result)
                                }
                            }
                              .background()
                              .frame(width: 200)
                        }
                        Table(execed_operations) {
                            TableColumn("PC", value: \.pc)
                            TableColumn("OPNAME", value: \.op_name)
                            TableColumn("OPCODE", value: \.opcode)
                        }
                    }
                    VStack {

                            BlockContext()
                            .frame(maxWidth: 300)
                            .background()

                        VStack {
                            Text("Controls")
                                .font(.system(size: 14, weight: .bold))
                                .help("load state/contract")
                            Button {
                                bytecode_add.toggle()
                            } label: {
                                Text("add contract bytecode")
                            }
                            Text("Continue")
                        }
                        .background()
                        .padding()
                        Spacer()
                        VStack {
                            StateDBDetails(kind: .InMemory)
                        }
                        .background()
                        .padding()
                    }.frame(maxHeight: .infinity, alignment: .topLeading)
                }
                HStack {
                    Text("current input")
                    TextField("call data", text: $calldata)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $bytecode_add) {
                print("sheet dismissed")
            } content: {
                NewContractByteCode(
                    contract_name: $new_contract_name,
                    contract_bytecode: $new_contract_bytecode,
                    contract_abi: $new_contract_abi
                ).onDisappear {
                    if new_contract_name.isEmpty || new_contract_bytecode.isEmpty {
                        return
                    }
                    
                    do {
                        try d.create_new_contract(code: new_contract_bytecode)
                    } catch {
                        return
                    }
                    
                    loaded_contracts.append(LoadedContract(
                        name: new_contract_name,
                        bytecode: new_contract_bytecode, 
                        address: "")
                    )
                    print("removed the sheet")
                }
            }
            
            .tabItem { Text("live dev") }.tag(0)
            TraceView().tabItem { Text("TraceView (goevmlab)") }.tag(1)
        }).onAppear {
            // TODO only during dev at the moment
            selected_contract_idx = loaded_contracts[2]
        }
        .padding(10)
    }
}

struct TraceView: View {
    var body : some View {
        Text("placeholder")
    }
}

enum StateDBKind: String {
    case InMemory = "in memory state"
    case GethDB = "geth based leveldb"
//    var description: String {
//        switch self {
//        case .InMemory:
//            return "in memory state"
//        case .GethDB:
//            return "geth based leveldb"
//        }
//    }
}

struct StateDBDetails: View {
    let kind: StateDBKind
    var body: some View {
        VStack {
            Text("State used by EVM")
                .font(.system(size: 14, weight: .bold))
            HStack {
                Text("Kind: ")
                Text(kind.rawValue)
            }
        }
    }
}

struct NewContractByteCode: View {
    @Binding var contract_name : String
    @Binding var contract_bytecode : String
    @Binding var contract_abi: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextField("new contract name...", text:$contract_name)
            HStack {
                TextField("contract bytecode...", text: $contract_bytecode, axis: .vertical)
                    .lineLimit(20, reservesSpace: true)
                TextField("optional contract ABI...", text: $contract_abi, axis: .vertical)
                    .lineLimit(20, reservesSpace: true)
            }
            Button {
                print("dismiss")
                dismiss()
            } label: {
                Text("Add")
                    .padding(5)
                    .scaledToFill()
            }
        }.padding()
            .frame(width: 500, height: 450)
    }
}

class StubEVMDriver: EVMDriver {
    func create_new_contract(code: String) throws {
        print("stubbed out create new contract")
    }
    
    func new_evm_singleton() {
        //
    }
}

struct EIP : Identifiable {
    let id = UUID()
    let num : Int
    var enabled: Bool
}

struct KnownEIPs: View {
    @State var known_eips : [EIP]

    var body : some View {
        Table(known_eips) {
            TableColumn("EIP") { d in
                Text("\(d.num)")
            }
            TableColumn("Enabled") { d in
                // SO ELEGANT! custom binding on the fly!
                Toggle("", isOn: Binding<Bool>(
                   get: {
                       return d.enabled
                   },
                   set: {
                       if let index = known_eips.firstIndex(where: { $0.id == d.id }) {
                           known_eips[index].enabled = $0
                       }
                   }
                ))
            }
        }
    }
}

#Preview("enabled EIPs") {
    KnownEIPs(known_eips: [
        EIP(num: 12, enabled: false),
        EIP(num: 32, enabled: true),
        EIP(num: 44, enabled: false)
    ])
}

#Preview("dev center") {
    EVMDevCenter(driver: StubEVMDriver())
        .frame(width: 1024, height: 760)

}

#Preview("New Contract bytecode") {
    NewContractByteCode(
        contract_name: .constant(""),
        contract_bytecode: .constant(""),
        contract_abi: .constant("")
    )
}

#Preview("BlockContext") {
    BlockContext()
}
