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
                .font(.title)
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


struct RotatingDotAnimation: View {
    
    @State private var startAnimation = false
    @State private var duration = 1.0 // Works as speed, since it repeats forever
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .foregroundColor(.blue.opacity(0.5))
                .frame(width: 35, height: 35, alignment: .center)
            Circle()
                .fill(.blue)
                .frame(width: 12, height: 12, alignment: .center)
                .offset(x: -9)
                .rotationEffect(.degrees(startAnimation ? 360 : 0))
                .animation(.easeInOut(duration: duration).repeatForever(autoreverses: false),
                           value: startAnimation
                )
        }
        .onAppear {
            self.startAnimation.toggle()
        }
    }
}

public struct EVMDevCenter<Driver: EVMDriver> : View {
    
    @State private var bytecode_add = false
    // TODO refactor these into a stateobject
    @State private var new_contract_name = ""
    @State private var new_contract_bytecode = ""
    @State private var new_contract_abi = ""
    @State private var current_code_running = ""
    @State private var current_tab = 0
    @State private var calldata = ""
    @State private var present_eips_sheet = false
    @State private var present_load_db_sheet = false
    @State private var msg_sender = ""
    @State private var msg_sender_eth_balance = ""
    @State private var show_loading_db = false
    @State private var db_loaded_from_chain = false
    
    let d : Driver
    
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
    @ObservedObject private var execed_ops = ExecutedOperations.shared
    @StateObject private var current_block_header = CurrentBlockHeader()
    
    private func running_evm(calldata: String, msg_value: String) -> EVMCallResult {
        print("kicking off running evm \(calldata) \(msg_value) \(selected_contract!.address)")
        let call_result = d.call(calldata: calldata, target_addr: selected_contract!.address, msg_value: msg_value)
        print(call_result)
        return call_result
    }
    
    @State private var present_load_contract_sheet = false
    
    public var body: some View {
        
        TabView(selection: $current_tab,
                content:  {
            VStack {
                HStack {
                    NavigationStack {
                        VStack {
                            Text("Loaded contracts")
                                .font(.title)
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
                                Text("Add New Contract")
                            }
                            Button {
                                present_load_contract_sheet.toggle()
                            } label: {
                                Text("Load Contract from chain")
                            }.disabled(!db_loaded_from_chain)
                                .help("must first load an existing blockchain database")
                        }
                    }
                    VStack {
                        HStack {
                            if let contract = selected_contract {
                                VStack {
                                    Text("Contract bytecode")
                                        .font(.title)
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
                                    .font(.title)
                                VStack {
                                    Button {
                                        if var contract = selected_contract {
                                            do {
                                                contract.address = try d.create_new_contract(
                                                    code: contract.bytecode
                                                )
                                                // needed to cause ui update
                                                selected_contract = contract
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
                        Text("\(execed_ops.execed_operations.count) Executed Operations")
                            .font(.title)
                        Table(execed_ops.execed_operations) {
                            TableColumn("PC", value: \.pc)
                            TableColumn("OPNAME", value: \.op_name)
                            TableColumn("OPCODE", value: \.opcode)
                            TableColumn("GAS", value: \.gas_cost)
                        }.onReceive(ExecutedOperations.shared.$execed_operations,
                                    perform: { item in
                            // print("got a new value")
                        })
                    }
                    VStack {
                        BlockContext()
                            .frame(maxWidth: 240)
                        VStack {
                            Text("Load Blockchain")
                                .font(.title)
                                .help("load state/contract")
                            VStack {
                                HStack {
                                    if show_loading_db {
                                        RotatingDotAnimation()
                                    }
                                    Button {
                                        present_load_db_sheet.toggle()
                                    } label: {
                                        Text("load existing db")
                                    }
                                }
                            }
                            .padding()
                            .background()
                            
                        }
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
                        StateDBDetails()
                            .environmentObject(current_block_header)
                        .padding()
                    }.frame(maxHeight: .infinity, alignment: .topLeading)
                }
                RunningEVM(target_addr: Binding<String>(
                    get: {
                        if let contract = selected_contract {
                            return contract.address
                        }
                        return ""
                    },
                    set: {
                        if var contract = selected_contract {
                            contract.address = $0
                            selected_contract = contract
                        }
                    }
                ),
                           msg_sender: $msg_sender,
                           msg_sender_eth_balance: $msg_sender_eth_balance,
                           d: d)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            .sheet(isPresented: $present_load_contract_sheet, onDismiss: {
                // something
            }, content: {
                LoadContractFromChain(do_load: { name, addr in
                    
//                    Task.detached {
                        guard let code = try? d.load_contract(addr: addr) else {
                            print("problem loading contract")
                            return
                        }

                        print("here is the actual contract loaded from chain", code)

                        DispatchQueue.main.async {
                            loaded_contracts.append(
                                .init(name: name, bytecode: code, address: addr)
                            )
                            withAnimation {
                                selected_contract = loaded_contracts.last
                            }
                        }
//                    }
                })
            })
            
            
            .sheet(isPresented: $present_load_db_sheet, onDismiss: {
                //
            }, content: {
                LoadExistingDB(d:d) { db_kind, chaindata_dir in
                    print("got the \(db_kind) - \(chaindata_dir)")
                    withAnimation {
                        show_loading_db = true
                    }
                    
                    Task.detached {
                        defer {
                            Task {
                                await MainActor.run {
                                    withAnimation {
                                        show_loading_db = false
                                    }
                                }
                            }
                        }
                        
                        do {
                            // no idea why having this needless awaits just for preview to work - very dumb
                            try await d.load_chaindata(
                                pathdir: chaindata_dir,
                                db_kind: db_kind
                            )
                            let head = try await d.load_chainhead()
                            let decoder = JSONDecoder()
                            guard let blk_header = try? decoder.decode(
                                BlockHeader.self,
                                from: head.data(using: .utf8)!) else {
                                // should not be happening
                                return
                            }
                            guard let head_number = UInt32(
                                blk_header.number.dropFirst(2),
                                radix: 16
                            ) else {
                                print("problem converting \(blk_header.number)")
                                return
                            }
                            
                            DispatchQueue.main.async {
                                current_block_header.block_number = head_number
                                current_block_header.db_backing = .GethDB
                                current_block_header.state_root = blk_header.stateRoot
                                db_loaded_from_chain = true
                            }
                            
                            print("head is \(head) -> \(blk_header)")
                        } catch {
                            print("some kind of problem \(error)")
                            return
                        }
                        
                        
                    }
                }
            })
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
            
            .tabItem { Text("Live Dev") }.tag(0)
            StateInspector(d: d)
                .tabItem { Text("State Inspector") }.tag(1)
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

struct StateInspector: View {
    let d : EVMDriver
    var body : some View {
        Text("placeholder")
    }
}

struct StateDBDetails: View {
    @EnvironmentObject var current_head : CurrentBlockHeader
//    @EnvironmentObject var
    var body: some View {
        VStack {
            Text("State used by EVM")
                .font(.title)
            VStack {
                HStack {
                    Text("Kind: ")
                    Spacer()
                    Text(current_head.db_backing.rawValue)
                }
                HStack {
                    Text("BlockNumber: ")
                    Spacer()
                    Text("\(current_head.block_number)")
                }
                HStack {
                    Text("State Root")
                    Spacer()
                    Text(current_head.state_root)
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

struct ABIEncode: View {
    
    var body: some View {
        VStack {
            Text("some kind of encoder?")
        }
    }
}

struct LoadContractFromChain : View {
    let do_load: (String, String) -> Void
    @State private var contract_name = ""
    @State private var contract_addr = ""
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        VStack {
            HStack {
                Text("Contract Name")
                TextField("nickname", text: $contract_name)
            }
            HStack {
                Text("Contract Address")
                TextField("0x...", text: $contract_addr)
            }
            HStack {
                Button {
                    do_load(contract_name, contract_addr)
                    dismiss()
                } label: {
                    Text("Load Contract")
                        .help("could take a second please wait")
                }
                Button { dismiss() } label : { Text("Cancel") }
            }
        }
        .padding()
        .frame(width: 490, height: 220)
    }
    
}

#Preview("load from chain") {
    LoadContractFromChain { _, _ in
        //
    }
}

struct LoadExistingDB : View {
    let d : EVMDriver
    @Environment(\.dismiss) var dismiss
    @State private var options = ["pebble", "leveldb"]
    @State private var selected_option = "pebble"
    @State private var chaindata_dir = ""
    @State private var present_fileimporter = false
    let finished: ((db_kind: String, chaindata: String)) -> Void
    
    var body: some View {
        VStack {
            Picker("Database kind", selection: $selected_option) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .tint(.black)
            .pickerStyle(.menu)
            HStack {
                Text("Chaindata")
                TextField("directory", text: $chaindata_dir)
            }
            HStack {
                Button {
                    present_fileimporter.toggle()
                } label: {
                    Text("Select directory")
                }.fileImporter(isPresented: $present_fileimporter,
                               allowedContentTypes: [.directory]) { result in
                    switch result {
                    case .success(let directory):
                        chaindata_dir = directory.path()
                        // gain access to the directory
                    case .failure(let error):
                        // how would this even happen?
                        print(error)
                    }
                }
                Spacer()
                Button {
                    finished((db_kind: selected_option,
                              chaindata: chaindata_dir))
                    dismiss()
                } label: {
                    Text("Ok")
                }
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}



struct RunningEVM<Driver: EVMDriver>: View {
    @State private var calldata = ""
    @State private var msg_value = ""
    @State private var call_return_value = ""
    @State private var error_msg_evm = ""
    @State private var error_msg_contract_eval = ""
    // These can be updated from outside this view
    // as the EVM runs
    @Binding var target_addr: String
    @Binding var msg_sender: String
    @Binding var msg_sender_eth_balance: String
    let d : Driver
    @State private var _hack_redraw_hook = false
    
    func dev_mode() {
        // entry_point(address,uint256)
        calldata = "f4bd333800000000000000000000000001010101010101010101010101010101010101010000000000000000000000000000000000000000000000004563918244f40000"
        msg_value = "6000000000000000000"
    }
    
    var body: some View {
        VStack {
            Text("Live Contract Interaction")
                .font(.title)
            HStack {
                VStack {
                    HStack {
                        Text("Input")
                            .frame(width: 120, alignment: .leading)
                        TextField("calldata", text: $calldata)
                    }
                    HStack {
                        Text("Value")
                            .frame(width: 120, alignment: .leading)
                        TextField("msg value", text: $msg_value)
                    }
                    HStack {
                        Text("Target Addr")
                            .frame(width: 120, alignment: .leading)
                        TextField("target addr", text: $target_addr)
                    }
                    HStack {
                        Text("Return value")
                            .frame(width: 120, alignment: .leading)
                        TextField("last call return value", text: $call_return_value)
                            .disabled(true)
                    }
                }
                VStack{
                    HStack {
                        Text("Sender Addr")
                            .frame(width: 120, alignment: .leading)
                        TextField("msg.sender", text: $msg_sender)
                    }
                    HStack {
                        Text("Sender eth balance")
                            .frame(width: 120, alignment: .leading)
                        TextField("eth balance", text: $msg_sender_eth_balance)
                    }
                    HStack {
                        Text("EVM Error")
                            .frame(width: 120, alignment: .leading)
                        TextField("last failure message", text: $error_msg_evm)
                    }
                }.padding()
                VStack {
                    Button {
                        print("calling run evm handler \(calldata)-\(msg_value)")
                        let result = d.call(
                            calldata: calldata,
                            target_addr: target_addr,
                            msg_value: msg_value
                        )
                        switch result {
                        case .failure(reason: let r):
                            error_msg_evm = r
                        case .success(return_value: let r):
                            error_msg_evm = ""
                            call_return_value = r
                        }
                    } label: {
                        Text("Run contract")
                    }
                    Button {
                        dev_mode()
                    } label: {
                        Text("enable dev values")
                    }
                    Toggle(isOn: Binding<Bool>(
                        get: {
                            d.exec_callback_enabled()
                        },
                        set: {
                            d.enable_exec_callback(yes_no: $0)
                            _hack_redraw_hook = $0
                        }
                    ), label: {
                        Text("Record Executed Operations")
                    })
                }
            }
            .padding()
            .background()
        }
    }
}


#Preview("dev center") {
    EVMDevCenter(driver: StubEVMDriver())
        .frame(width: 1224, height: 760)
        .onAppear {
            let dummy_items : [ExecutedEVMCode] = [
                .init(pc: "0x07c9", op_name: "DUP2", opcode: "0x81", gas: 20684, gas_cost: 3, depth: 3, refund: 0),
                .init(pc: "0x07c9", op_name: "JUMP", opcode: "0x56", gas: 20684, gas_cost: 8, depth: 3, refund: 0)
            ]
            ExecutedOperations.shared.execed_operations.append(contentsOf: dummy_items)
        }
}

#Preview("load existing db") {
    LoadExistingDB(d: StubEVMDriver(), finished: { _, _ in
        //
    })
    .frame(width: 480, height: 380)
}



#Preview("state inspect") {
    StateInspector(d: StubEVMDriver())
        .frame(width: 768, height: 480)
}

#Preview("running EVM") {
    RunningEVM(
        target_addr: .constant(""),
        msg_sender: .constant(""),
        msg_sender_eth_balance: .constant(""),
        d: StubEVMDriver()
    )
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
