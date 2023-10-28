//
//  SwiftUIView.swift
//
//
//  Created by Edgar Aroutiounian on 10/24/23.
//

import SwiftUI
import DevStationCommon

struct BlockContext : View {
    @State fileprivate var coinbase: String = ""
    @State fileprivate var base_gas: String = ""
    
    var body : some View {
        VStack {
            Text("Block Context")
                .font(.system(size: 14, weight: .bold))
            VStack {
                HStack {
                    Text("Coinbase")
                    TextField("0x..", text: $coinbase)
                }
                HStack {
                    Text("Base Gas Price")
                    TextField("base gas", text: $base_gas)
                }
            }
            .padding()
            .background()
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


struct LoadedContract : Hashable, Identifiable {
    let name : String
    let bytecode: String
    var address : String
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
    @State private var present_eips_sheet = false
    
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
    
    @State private var selected_contract : LoadedContract?
    @State private var deploy_contract_result = ""
    @State var eips_used : [EIP] = []
    
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
                            List(loaded_contracts, id:\.self,
                                 selection: $selected_contract) { item in
                                Text(item.name)
                            }
                                 .frame(maxWidth: 200)
                                 .padding([.trailing, .leading])
                            Button {
                                bytecode_add.toggle()
                            } label: {
                                Text("Add Contract")
                            }
                        }
                    }
                    VStack {
                        HStack {
                            if let contract = selected_contract {
                                VStack {
                                    Text("Contract bytecode")
                                        .font(.system(size: 14, weight: .bold))
                                    ScrollView {
                                        Text(contract.bytecode)
                                            .lineLimit(nil)
                                            .frame(maxWidth:.infinity, maxHeight:.infinity)
                                            .background()
                                    }
                                }
                            } else {
                                Text("select a contract from sidebar ")
                            }
                            VStack {
                                Text("Contract Details")
                                    .font(.system(size: 14, weight: .bold))
                                VStack {
                                    Button {
                                        if var contract = selected_contract {
                                            do {
                                                contract.address = try d.create_new_contract(
                                                    code: contract.bytecode
                                                )
                                                print("Should be saying \(contract.address) on screen")
                                            } catch EVMError.deploy_issue(let reason){
                                                deploy_contract_result = reason
                                            }  catch {
                                                return
                                            }
                                        }
                                    } label: {
                                        Text("Try deploy contract")
                                    }
                                    HStack {
                                        Text("deploy result")
                                        Text(deploy_contract_result)
                                    }
                                    HStack {
                                        Text("Deployed Addr")
                                        Spacer()
                                        if let contract = selected_contract {
                                            Text(contract.address)
                                        } else {
                                            Text("N/A")
                                        }
                                    }
                                }
                                .padding()
                                .background()
                            }
                            .frame(width: 200)
                        }
                        Text("Executed Operations")
                            .font(.system(size: 14, weight: .bold))
                        Table(execed_operations) {
                            TableColumn("PC", value: \.pc)
                            TableColumn("OPNAME", value: \.op_name)
                            TableColumn("OPCODE", value: \.opcode)
                        }
                    }
                    VStack {
                        BlockContext()
                            .frame(maxWidth: 300)
                        VStack {
                            Text("Running Controls")
                                .font(.system(size: 14, weight: .bold))
                                .help("load state/contract")
                            Text("Continue")
                        }
                        .background()
                        .padding()
                        VStack {
                            Text("EVM Configuration")
                                .font(.system(size: 14, weight: .bold))
                            VStack {
                                Button {
                                    present_eips_sheet.toggle()
                                } label: {
                                    Text("EIPS enabled")
                                }
                                Text("Something")
                            }
                            .padding()
                            .background()
                        }
                        StateDBDetails(kind: .InMemory)
                            .padding()
                    }.frame(maxHeight: .infinity, alignment: .topLeading)
                }
                HStack {
                    Text("current input")
                    TextField("call data", text: $calldata)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $present_eips_sheet,
                   onDismiss: {
                // just hold onto it
            }, content: {
                KnownEIPs(known_eips: $eips_used)
            })
            .sheet(isPresented: $bytecode_add) {
                if new_contract_name.isEmpty || new_contract_bytecode.isEmpty {
                    return
                }
                var new_addr: String

                do {
                    new_addr = try d.create_new_contract(code: new_contract_bytecode)
                } catch {
                    return
                }
                
                loaded_contracts.append(LoadedContract(
                    name: new_contract_name,
                    bytecode: new_contract_bytecode,
                    address: new_addr)
                )
            } content: {
                NewContractByteCode(
                    contract_name: $new_contract_name,
                    contract_bytecode: $new_contract_bytecode,
                    contract_abi: $new_contract_abi
                )
            }
            
            .tabItem { Text("live dev") }.tag(0)
            TraceView().tabItem { Text("TraceView") }.tag(1)
        }).onAppear {
            // TODO only during dev at the moment
            selected_contract = loaded_contracts[2]
            // only needs to happen once
            let all = d.available_eips()
            for item in all {
                eips_used.append(EIP(num: item, enabled: true))
            }
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
    let block_number: Int = 12_000_000
    let state_root : String = "0x01"
    
    var body: some View {
        VStack {
            Text("State used by EVM")
                .font(.system(size: 14, weight: .bold))
            VStack {
                HStack {
                    Text("Kind: ")
                    Spacer()
                    Text(kind.rawValue)
                }
                HStack {
                    Text("BlockNumber: ")
                    Spacer()
                    Text("\(block_number)")
                }
                HStack {
                    Text("State Root Hash:")
                    Spacer()
                    Text(state_root)
                }
            }
            .padding()
            .background()
        }.frame(alignment: .center)
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
    func create_new_contract(code: String) throws -> String {
        return "0x01"
    }
    
    func new_evm_singleton() {
        //
    }
    
    func available_eips() -> [Int] {
        return [12, 14, 15]
    }
    
}

struct EIP : Identifiable {
    let id = UUID()
    let num : Int
    var enabled: Bool
}

struct KnownEIPs: View {
    @Binding var known_eips : [EIP]
    @State var enable_all = false
    @Environment(\.dismiss) var dismiss
    
    var body : some View {
        VStack {
            HStack {
                Toggle(isOn: $enable_all) {
                    Text("enable all EIPs")
                }
                Button {
                    dismiss()
                } label: {
                    Text("Ok")
                }
            }
            Table(known_eips) {
                TableColumn("EIP") { d in
                    Text(String(d.num))
                }
                TableColumn("Enabled") { d in
                    // SO ELEGANT! custom binding on the fly!
                    Toggle("", isOn: Binding<Bool>(
                        get: {
                            if enable_all {
                                return true
                            }
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
        .padding()
        .frame(width: 500, height: 450)
    }
}


#Preview("dev center") {
    EVMDevCenter(driver: StubEVMDriver())
        .frame(width: 1024, height: 760)
    
}

#Preview("enabled EIPs") {
    KnownEIPs(known_eips: .constant([
        EIP(num: 1223, enabled: false),
        EIP(num: 1559, enabled: true),
        EIP(num: 44, enabled: false)]
                                   ))
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
