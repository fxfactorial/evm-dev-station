//
//  SwiftUIView.swift
//
//
//  Created by Edgar Aroutiounian on 10/24/23.
//

import SwiftUI

public protocol EVMDriver {
    func create_new_contract(code: String)
    func new_evm_singleton()
}

struct BlockContext : View {
    @State fileprivate var coinbase: String = "0x..."
    
    var body : some View {
        VStack {
            TextField("Coinbase", text: $coinbase)
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
public struct EVMDevCenter<Driver: EVMDriver> : View {
    
    @State private var bytecode_add = false
    @State private var new_contract_name = ""
    @State private var new_contract_bytecode = ""
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
        .init(name: "compound", bytecode: "456", address: "0x1234")
    ]
    
    //     @StateObject private var loaded_contracts = LoadedContracts()
    
    @State private var selected_contract_idx : LoadedContract?
    
    public var body: some View {
        
        TabView(selection: $current_tab,
                content:  {
            VStack {
                HStack {
                    NavigationStack {
                        List(loaded_contracts, id:\.self, selection: $selected_contract_idx) { item in
                            Text(item.name)
                        }.frame(maxWidth: 200)
                    }
                    VStack {
                        if let contract = selected_contract_idx {
                            NavigationLink(value: contract) {
                                Text("\(contract.bytecode)")
                                    .lineLimit(20, reservesSpace: true)
                                    .frame(maxWidth:.infinity)
                            }
                        } else {
                            Text("select something ")
                        }
                        Table(execed_operations) {
                            TableColumn("PC", value: \.pc)
                            TableColumn("OPNAME", value: \.op_name)
                            TableColumn("OPCODE", value: \.opcode)
                        }
                    }
                    VStack {
                        Button {
                            bytecode_add.toggle()
                        } label: {
                            Text("add contract bytecode")
                        }
                        Text("Continue")
                    }
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
                    contract_bytecode: $new_contract_bytecode
                )
            }
            
            .tabItem { Text("live dev") }.tag(0)
            TraceView().tabItem { Text("TraceView (goevmlab)") }.tag(1)
        })
        .padding(10)
    }
}

struct TraceView: View {
    var body : some View {
        Text("placeholder")
    }
}

struct NewContractByteCode: View {
    @Binding var contract_name : String
    @Binding var contract_bytecode : String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextField("new contract name...", text:$contract_name)
            TextField("contract bytecode...", text: $contract_bytecode, axis: .vertical)
                .lineLimit(20, reservesSpace: true)
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
    func create_new_contract(code: String) {
        print("stubbed out create new contract")
    }
    
    func new_evm_singleton() {
        //
    }
}

#Preview("dev center") {
    EVMDevCenter(driver: StubEVMDriver())
        .frame(width: 1024, height: 760)
}

#Preview("New Contract bytecode") {
    NewContractByteCode(
        contract_name: .constant(""),
        contract_bytecode: .constant("")
    )
}

#Preview("BlockContext") {
    BlockContext()
}
