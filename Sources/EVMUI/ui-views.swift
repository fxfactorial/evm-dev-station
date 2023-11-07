//
//  SwiftUIView.swift
//
//
//  Created by Edgar Aroutiounian on 10/24/23.
//

import SwiftUI
import DevStationCommon

struct BlockContext : View {
    @ObservedObject private var model = BlockContextModel.shared
    
    var body : some View {
        VStack {
            VStack {
                HStack {
                    Text("Coinbase")
                    TextField("0x..", text: $model.coinbase)
                }
                HStack {
                    Text("Base Gas Price")
                    TextField("base gas", text: $model.base_gas)
                }
                HStack {
                    Text("Time")
                    TextField("time", text: $model.time)
                }
            }
              .padding()
              .background()
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it exists, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct RotationParam {
    let inner_circle_width: CGFloat
    let inner_circle_height : CGFloat
    let inner_circle_offset: CGFloat
    
    let outer_circle_width: CGFloat
    let outer_circle_height: CGFloat
}

struct RotatingDotAnimation: View {
    
    @State private var startAnimation = false
    @State private var duration = 1.0 // Works as speed, since it repeats forever
    let param : RotationParam
    
    var body: some View {
        ZStack {
            Circle()
              .stroke(lineWidth: 4)
              .foregroundColor(.blue.opacity(0.5))
              .frame(width: param.outer_circle_width, height: param.outer_circle_height, alignment: .center)
            Circle()
              .fill(.blue)
              .frame(width: param.inner_circle_width, height: param.inner_circle_height, alignment: .center)
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
    let d : Driver
    
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
    @State private var current_contract_detail_tab = 0

    // NOTE Use observedobject on singletons
    @ObservedObject private var chaindb = LoadChainModel.shared
    @ObservedObject private var evm_run_controls = EVMRunStateControls.shared
    @ObservedObject private var execed_ops = ExecutedOperations.shared
    @ObservedObject private var current_block_header = CurrentBlockHeader.shared
    @ObservedObject private var contracts = LoadedContracts.shared
    
    @State private var present_load_contract_sheet = false

    public init(driver : Driver) {
        d = driver
    }
    
    @State private var deploy_contract_result = ""
    @State var eips_used : [EIP] = []
    
    private func running_evm(calldata: String, msg_value: String) -> EVMCallResult {
        //        print("kicking off running evm \(calldata) \(msg_value) \(selected_contract!.address)")
        // let call_result = d.call(calldata: calldata, target_addr: selected_contract!.address, msg_value: msg_value)
        //        print(call_result)
        //        return call_result
        return .success(return_value: "")
    }
    
    
    public var body: some View {
        
        TabView(selection: $current_tab,
                content:  {
                    VStack {
                        HStack {
                            VStack {
                                HStack {
                                    NavigationStack {
                                        VStack {
                                            Text("Loaded contracts")
                                              .font(.title2)
                                              .help("interact with contracts loaded")
                                            List(contracts.contracts, id:\.self,
                                                 selection: $contracts.current_selection) { item in
                                                Text(item.name)
                                            }
                                              .frame(maxWidth: 150)
                                              .padding([.trailing, .leading])
                                            Button {
                                                bytecode_add.toggle()
                                            } label: {
                                                Text("Add New Contract").frame(maxWidth: 150)
                                            }
                                            Button {
                                                present_load_contract_sheet.toggle()
                                            } label: {
                                                Text("Load from chain").frame(maxWidth: 150)
                                            }
                                              .disabled(!chaindb.is_chain_loaded)
                                              .help("must first load an existing blockchain database")
                                        }
                                    }
                                    TabView(selection: $current_contract_detail_tab) {
                                        VStack {
                                            Button {
                                                if var contract = contracts.current_selection {
                                                    do {
                                                        contract.address = try d.create_new_contract(
                                                          code: contract.bytecode,
                                                          creator_addr: "0x00000000000000000000"
                                                        )
                                                        // needed to cause ui update
                                                        contracts.current_selection = contract
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
                                                if let contract = contracts.current_selection {
                                                    Text(contract.address)
                                                } else {
                                                    Text("N/A")
                                                }
                                            }
                                        }
                                          .padding()
                                          .background()
                                          .tabItem{ Text("Contract State") }.tag(0)
                                        VStack {
                                            if let contract = contracts.current_selection {
                                                VStack {
                                                    ScrollView {
                                                        Text(contract.bytecode)
                                                          .lineLimit(nil)
                                                          .frame(maxWidth:.infinity, maxHeight:300)
                                                          .background()
                                                    }
                                                }
                                            } else {
                                                Text("select a contract from sidebar ")
                                            }
                                        }.tabItem { Text("Bytecode") }.tag(1)
                                    }
                                }
                                ScrollViewReader { (proxy: ScrollViewProxy) in
                                    Text("\(execed_ops.execed_operations.count) Executed Operations")
                                      .font(.title2)
                                    Table(execed_ops.execed_operations) {
                                        TableColumn("PC", value: \.pc)
                                        TableColumn("OPNAME", value: \.op_name)
                                        TableColumn("OPCODE", value: \.opcode)
                                        TableColumn("GAS", value: \.gas_cost)                                
                                    }
                                      .frame(maxHeight: 400)
                                      .onReceive(execed_ops.$execed_operations,
                                                 perform: { item in
                                                     let id = item.last
                                                     proxy.scrollTo(id)
                                                 })
                                }
                                if let contract = contracts.current_selection {
                                    ABIEncode(loaded_contract: contract)
                                      .padding()
                                      .background()
                                }
                            }
                            VStack {
                                TabView {
                                    VStack {
                                        BlockContext()
                                          .frame(maxWidth: .infinity)
                                        Button {
                                            present_load_db_sheet.toggle()
                                        } label: {
                                            Text("Load Chaindata")
                                        }.disabled(chaindb.is_chain_loaded)
                                        if chaindb.show_loading_db {
                                            RotatingDotAnimation(param: .init(
                                                                   inner_circle_width: 12,
                                                                   inner_circle_height: 12,
                                                                   inner_circle_offset: -9,
                                                                   outer_circle_width: 35,
                                                                   outer_circle_height: 35)
                                            )
                                        }
                                    }
                                      .frame(maxWidth: .infinity, maxHeight: .infinity)
                                      .background()
                                      .tabItem {
                                          Text("Load Blockchain")
                                      }.tag(0)
                                    StateDBDetails()
                                      .environmentObject(current_block_header)
                                      .environmentObject(chaindb)
                                      .frame(maxWidth: .infinity, maxHeight: .infinity)
                                      .background()
                                      .tabItem { Text("StateDB Details") }.tag(1)
                                    VStack {
                                        Button {
                                            present_eips_sheet.toggle()
                                        } label: {
                                            Text("EIPS enabled")
                                        }
                                    }
                                      .frame(maxWidth: .infinity, maxHeight: .infinity)
                                      .background()
                                      .tabItem { Text("EVM Config")}.tag(2)
                                }.frame(minHeight: 200)
                                BreakpointView()
                            }.frame(maxHeight: .infinity, alignment: .topLeading)
                        }
                        RunningEVM(target_addr: Binding<String>(
                                     get: {
                            if let contract = contracts.current_selection {
                                return contract.address
                            }
                            return ""
                        },
                                     set: {
                            if var contract = contracts.current_selection {
                                contract.address = $0
                                contracts.current_selection = contract

                            }
                        }
                                   ),
                                   msg_sender: $msg_sender,
                                   msg_sender_eth_balance: $msg_sender_eth_balance,
                                   d: d)
                          .environmentObject(evm_run_controls)
                    }
                      .frame(maxWidth: .infinity, maxHeight: .infinity)
                      .sheet(isPresented: $present_load_contract_sheet,
                             onDismiss: {
                                 // something
                             },
                             content: {
                                 LoadContractFromChain(
                                   do_load: {
                                       name,
                                       addr,
                                       abi_json in
                                       if name.isEmpty || addr.isEmpty {
                                           return
                                       }
                                       
                                       d.load_contract(addr: addr, nickname: name, abi_json: abi_json)
                                   })
                             })
                      .sheet(isPresented: $present_load_db_sheet,
                             onDismiss: {
                                 //
                             }, content: {
                                    LoadExistingDB(d:d) { db_kind, chaindata_dir in
                                        withAnimation {
                                            chaindb.show_loading_db = true
                                        }
                                        
                                        d.load_chaindata(
                                          pathdir: chaindata_dir,
                                          db_kind: db_kind
                                        )
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
                          
                          // do {
                          //     new_addr = try d.create_new_contract(
                          //       code: new_contract_bytecode,
                          //       creator_addr: "0x00000000000000000000"
                          //     )
                          // } catch {
                          //     return
                          // }
                          // let loaded = LoadedContract(
                          //   name: new_contract_name,
                          //   bytecode: new_contract_bytecode,
                          //   address: new_addr,
                          //   contract: try? EthereumContract(new_contract_abi)
                          // )
                          // loaded_contracts.append(loaded)
                      } content: {
                          NewContractByteCode(
                            contract_name: $new_contract_name,
                            contract_bytecode: $new_contract_bytecode,
                            contract_abi: $new_contract_abi
                          )
                      }
                    
                      .tabItem { Text("Live Dev") }.tag(0)
                    StateInspector(d: d)
                      .tabItem { Text("Account/State Modification") }.tag(1)
                }).onAppear {
            // only needs to happen once
            let all = d.available_eips()
            for item in all {
                eips_used.append(EIP(num: item, enabled: true))
            }
        }
          .padding(10)
    }
}

struct StateAccount : Hashable,  Identifiable {
    let addr : String
    let code_hash: String
    let id = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct StateInspector: View {
    let d : EVMDriver
    @State private var loaded_accounts : [StateAccount] = [.init(addr: "0x0123", code_hash: "0x213123")]
    @State private var selected_account : StateAccount?
    
    var body : some View {
        VStack{
            HStack {
                NavigationStack {
                    VStack {
                        Text("Accounts")
                          .font(.title2)
                        List(loaded_accounts, id: \.id,
                             selection: $selected_account) { item in
                            Text(item.addr)
                        }
                        Button {
                            loaded_accounts.append(.init(addr: "more", code_hash: "more"))
                        } label: {
                            Text("Load Account")
                        }
                    }.frame(maxWidth: 300)
                }
                VStack {
                    Text("first")
                }
                Spacer()
            }.frame(maxWidth: .infinity)
        }
    }
}

struct StateDBDetails: View {
    @EnvironmentObject var current_head : CurrentBlockHeader
    @EnvironmentObject var db_backing : LoadChainModel
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Kind:")
                    Spacer()
                    Text(db_backing.db_kind.rawValue)
                }
                HStack {
                    let num = "\(current_head.block_number)"
                    Text("BlockNumber:").help(num)
                    Spacer()
                    Text(num)
                }
                HStack {
                    Text("State Root:").help(current_head.state_root)
                    Spacer()
                    Text(current_head.state_root)
                }
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
            HStack {
                Button { dismiss() } label: { Text("Cancel").padding(5).scaledToFit().frame(width: 120) }
                Button {
                    dismiss()
                } label: {
                    Text("Add")
                      .padding(5)
                      .scaledToFill()
                      .frame(width: 120)
                }
                Button {
                    contract_bytecode = sample_contract.bytecode
                    contract_name = "example local contract"
                    contract_abi = sample_contract_abi
                } label: {
                    Text("quick dev add contract")
                }
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
    @Environment(\.openURL) var openURL

    let base_url = "https://eips.ethereum.org/EIPS"

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
                    Button {
                        guard let url = URL(string: "\(base_url)/eip-\(d.num)") else {
                            return
                        }
                        openURL(url)
                    } label: {
                        Text(String(d.num))
                    }
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


struct ListRowView: View {
    @ObservedObject var item: Item

    var body: some View {
        HStack {
            Text("\(item.index)")
            Spacer()
            Text(item.name)
        }
    }
}

struct ABIEncode: View {
    let loaded_contract: LoadedContract?
    
    @State private var selected: String = ""
    @State private var encoded: String = ""
    @State private var decoded_input : String = ""
    @State private var decoded_output : [String: Any]? = [:]
    @State private var fields : [String: [String]] = [:]
    
    var body: some View {
        HStack {
            NavigationStack {
                Text("Method names")
                if let contract = loaded_contract,
                   let c = contract.contract {
                    let names = Array(c.methods.keys).filter { !$0.hasPrefix("0x") }.sorted()

                    List(names, id: \.self,
                         selection: $selected) { item in
                        Text(item)
                    }
                    Button {
                        if selected == "quoteExactInputSingle" {
                            
                            fields[selected] = [
                              // weth
                              "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
                              // usdc
                              "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                              // fee tier
                              "3000",
                              // amount
                              "1000000000000000000",
                              // sqrt thing
                              "0"
                            ]
                            
                        }
                    } label: {
                        Text("dev quick fill in params")
                    }.disabled(selected != "quoteExactInputSingle")
                }
            }
            VStack {
                VStack {
                    TabView {
                        VStack {
                            ScrollView {
                                if !selected.isEmpty {
                                    if let contract = loaded_contract,
                                       let c = contract.contract,
                                       let element = c.allMethods.first(where: { $0.name == selected }) {
                                        ForEach(Array(zip(element.inputs.indices, element.inputs)), id: \.1.name) {index, input in
                                            HStack {
                                                Text(input.name)
                                                TextField(input.name, text: Binding<String>(
                                                                        get: {
                                                    guard let method_name = element.name else {
                                                        return ""
                                                    }
                                                    
                                                    if let had_it = fields[method_name] {
                                                        return had_it[index]
                                                    }
                                                    
                                                    fields[method_name] = [String](repeating: "", count: element.inputs.count)
                                                    return ""
                                                },
                                                                        set: {
                                                    if let n = element.name {
                                                        fields[n]![index] = $0
                                                    }
                                                }
                                                                      ))
                                            }
                                        }
                                    }
                                } else {
                                    Text("select a method from list")
                                }
                            }
                            
                            HStack {
                                Button {
                                    guard let l = loaded_contract,
                                          let contract = l.contract else {
                                        encoded = ""
                                        print("exit first")
                                        return
                                    }
                                    
                                    // TODO handle encoding errors better,
                                    // recall that if you have a bool, it will fail encoding because "true" != true ha.
                                    guard
                                      let selected_params = fields[selected],
                                      let encoded_call = contract.method(selected, parameters: selected_params, extraData: nil) else {
                                        encoded = ""
                                        return
                                    }
                                    
                                    print("actually did get ", encoded_call)
                                    encoded = encoded_call.toHexString()
                                    
                                } label: {
                                    Text("encode")
                                }.disabled(selected.isEmpty || loaded_contract?.contract == nil)
                                TextField("Encoded...", text: $encoded)
                                  .textSelection(.enabled)
                            }
                        }.tabItem { Text("Encode") }.tag(1).padding()
                        VStack {
                            HStack {
                                Button {
                                    guard let l = loaded_contract,
                                          let contract = l.contract else {
                                        return
                                    }
                                    decoded_output = contract.decodeReturnData(selected, data: Data(hex:decoded_input))
                                } label: {
                                    Text("decode")
                                }.disabled(decoded_input.isEmpty || loaded_contract?.contract == nil)
                                TextField("return...", text: $decoded_input)
                            }
                            HStack {
                                Text("result(s)")
                                if var have = decoded_output {
                                    // TODO more elegant answer here
                                    //                                    have.removeValue(forKey: "_success")
                                    let _ = have.removeValue(forKey: "_success")
                                    let zipped = Array(zip(have.keys, have.values))
                                    List(zipped, id: \.0.self) {item in
                                        HStack {
                                            Text(item.0)
                                            Spacer()
                                            Text("\((item.1 as AnyObject).description)")
                                        }
                                    }
                                }
                                // TextField("", text: )
                            }
                        }.tabItem { Text("Decode") }.tag(0).padding()
                    }.frame(minHeight: 150)
                }
            }
        }
          .frame(maxWidth: .infinity, maxHeight: 200)
    }
}

#Preview("ABI encode table") {
    ABIEncode(
      loaded_contract: sample_contract
    ).frame(width: 700, height: 300)
}

struct LoadContractFromChain : View {
    let do_load: (String, String, String) -> Void
    @State private var contract_name = ""
    @State private var contract_addr = ""
    @State private var contract_abi = ""
    
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        VStack {
            HStack {
                Text("Contract Name")
                  .frame(width: 120)
                TextField("nickname", text: $contract_name)
            }
            HStack {
                Text("Contract Address")
                  .frame(width: 120)
                TextField("0x...", text: $contract_addr)
            }
            HStack {
                Text("Optional ABI")
                  .frame(width: 120)
                TextEditor(text: $contract_abi)
            }
            HStack {
                Button {
                    do_load(contract_name, contract_addr, contract_abi)
                    dismiss()
                } label: {
                    Text("Load Contract")
                      .help("could take a second please wait")
                }
                Button { dismiss() } label : { Text("Cancel") }
                Button {
                    contract_name = "uniswap quoter"
                    contract_addr = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6"
                    contract_abi = UNISWAP_QUOTER_ABI
                } label: {
                    Text("dev mode")
                }
            }
        }
          .padding()
          .frame(width: 490, height: 220)
    }
    
}

#Preview("load from chain") {
    LoadContractFromChain { _, _ , _ in
        //
    }
}

struct BreakpointView: View {
    @ObservedObject private var callbackmodel: OpcodeCallbackModel = OpcodeCallbackModel.shared
    @State private var use_modified_values = false
    @Environment(\.openURL) var openURL
    @State private var possible_signature_names : [String] = []
    @State private var selected : String?
    @State private var current_tab = 1


    var body: some View {
        VStack {
            Text("Suspended EVM")
              .font(.title2)
            TabView(selection: $current_tab,
                    content: {
                        VStack {
                            VStack {
                                HStack {
                                    Text("caller").frame(width: 75)
                                    TextField("", text: $callbackmodel.current_caller)
                                    Button {
                                        if !callbackmodel.current_caller.isEmpty {
                                            guard let link = URL(string: "https://etherscan.com/address/\(callbackmodel.current_caller)") else {
                                                return
                                            }
                                            openURL(link)
                                        }
                                    } label: {
                                        Text("etherscan")
                                    }
                                }
                                HStack {
                                    Text("callee").frame(width: 75)
                                    TextField("", text: $callbackmodel.current_callee)
                                    Button {
                                        if !callbackmodel.current_callee.isEmpty {
                                            guard let link = URL(string: "https://etherscan.com/address/\(callbackmodel.current_callee)") else {
                                                return
                                            }
                                            openURL(link)
                                        }
                                        
                                    } label: {
                                        Text("etherscan")
                                    }
                                }
                                HStack {
                                    Text("args").frame(width: 75)
                                    TextField("", text: $callbackmodel.current_args)
                                }
                                VStack {
                                    Button {
                                        if callbackmodel.current_args.count < 8 {
                                            return
                                        }
                                        let sig = callbackmodel.current_args.prefix(8)
                                        guard let url = URL(string:"\(SIG_DIR_URL)/api/v1/signatures/?format=json&hex_signature=0x\(sig)") else {
                                            return
                                        }
                                        
                                        Task {
                                            let (data, _) = try await URLSession.shared.data(from: url)
                                            let ptvResult = try JSONDecoder().decode(SignatureLookup.self, from: data)
                                            // print("swift pulled \(ptvResult) against url \(url)")
                                            //                            guard let query_result = ptvResult.results.first else {
                                            //                                return
                                            //                            }
                                            DispatchQueue.main.async {
                                                possible_signature_names = ptvResult.results.map({ $0.textSignature })
                                            }
                                        }
                                    } label: {
                                        Text("Lookup possible signature names")
                                          .help("powered by API request to 4byte")
                                    }.disabled(callbackmodel.current_args.count < 8)
                                    HStack {
                                        List(possible_signature_names, id:\.self, selection: $selected) { name in
                                            Text(name).textSelection(.enabled)
                                        }
                                          .frame(minHeight: 120, maxHeight: 240)
                                          .border(.black)
                                        //                        .background(.gray)
                                        // .foregroundStyle(.selection)
                                          .scrollContentBackground(.hidden)
                                        VStack {
                                            Button {
                                                // print
                                            } label : {
                                                Text("attempt decode")
                                            }
                                        }
                                    }
                                }.frame(minWidth: 80)
                                HStack {
                                    Toggle(isOn: $use_modified_values) {
                                        Text("Use modified values")
                                    }
                                    Button {
                                        //                                callbackmodel.current_opcode_continue_task = Task.detached {
                                        if let cb = callbackmodel.continue_evm_exec {
                                            print("calling continue on paused opcode", use_modified_values)
                                            cb(use_modified_values,
                                               callbackmodel.current_caller,
                                               callbackmodel.current_callee,
                                               callbackmodel.current_args
                                            )

                                            DispatchQueue.main.async {
                                                possible_signature_names = []
                                                callbackmodel.selected_stack_item = nil
                                            }
                                        }
                                        
                                        //                                }
                                    } label: {
                                        Text("Continue")
                                    }.disabled(!callbackmodel.hit_breakpoint)
                                }
                            }
                              .padding()
                        }.onReceive(EVMRunStateControls.shared.$contract_currently_running, perform: { current_running in
                                                                                                if !current_running {
                                                                                                    possible_signature_names = []
                                                                                                }
                                                                                            })
                          .tabItem { Text("CALL").help("contract calls") }.tag(0)
                          .frame(height: 280)
                        HStack {
                            VStack {
                                Text("Current Stack ")
                                Text("(bottom of list is latest value pushed to stack)")
                                List(Array(zip(callbackmodel.current_stack.indices, callbackmodel.current_stack)),
                                     id: \.1.self,
                                     selection: $callbackmodel.selected_stack_item) { index, item in
                                    ListRowView(item: item)
                                }
                            }
                            VStack {
                                HStack {
                                    Text("Opcode suspended on ")
                                    Spacer()
                                    Text("`\(callbackmodel.current_opcode_hit)`")
                                      .foregroundStyle(.gray)
                                }.padding([.trailing, .leading], 10)
                                Text("current memory")
                                TextEditor(text: $callbackmodel.current_memory)
                                  .scrollTargetLayout(isEnabled: true)
                                  .font(.system(size: 16))
                                  .disabled(false)
                                TextField("selected stack item", text: Binding<String>(
                                                                   get: {
                                    callbackmodel.selected_stack_item?.name ?? ""
                                },
                                                                   set: {
                                    // TODO more double checking work
                                    callbackmodel.selected_stack_item?.name = $0
                                }
                                                                 ))
                                Spacer()
                                HStack {
                                    Toggle("use modified values", isOn: $callbackmodel.use_modified_values)
                                    Button {
                                        Task {
                                            if let cb = callbackmodel.continue_evm_exec_break_on_opcode {
                                                cb(
                                                  callbackmodel.use_modified_values,
                                                  callbackmodel.current_stack,
                                                  callbackmodel.current_memory
                                                )
                                                callbackmodel.selected_stack_item = nil
                                            }
                                        }
                                    } label: {
                                        Text("Continue")
                                    }.disabled(!callbackmodel.hit_breakpoint)
                                }.padding([.bottom], 5)
                            }
                        }
                          .tabItem{ Text("OPCODE").help("internal transactions") }.tag(1)
                          .frame(height: 280)
                        VStack {
                            Text("slot keys used")
                        }.tabItem{ Text("Storage")}.tag(2)
                    })
        }
    }
}



#Preview("breakpoint view") {
    BreakpointView()
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

struct OPCodeEnable: Identifiable {
    let id = UUID()
    let name : String
    var enabled: Bool = false
}

struct BreakOnOpcodes: View {
    @Binding var known_ops: [OPCodeEnable]
    @State var break_on_all = false
    @Environment(\.dismiss) var dismiss
    let d : EVMDriver

    @ObservedObject private var controls = EVMRunStateControls.shared

    var body: some View {
        VStack {
            HStack {
                Text("\(known_ops.count) known opcodes")
                Toggle("all", isOn: $break_on_all)
                Toggle("hook", isOn: Binding<Bool>(
                                 get: {
                    controls.opcode_breakpoints_enabled
                },
                                 set: {
                    d.enable_breakpoint_on_opcode(yes_no: $0)
                    controls.opcode_breakpoints_enabled = $0
                }
                               ))
            }
            Table(known_ops) {
                TableColumn("name", value: \.name)
                TableColumn("enabled") { d in
                    Toggle("", isOn: Binding<Bool>(
                                 get: {
                        if break_on_all {
                            return true
                        }
                        return d.enabled
                    },
                                 set: {
                        if let index = known_ops.firstIndex(where: { $0.id == d.id }) {
                            known_ops[index].enabled = $0
                            self.d.enable_breakpoint_on_opcode(yes_no:$0, opcode_name:known_ops[index].name)
                        }
                    }
                               ))
                }
            }
            Button {
                dismiss()
            } label: {
                Text("Ok")
            }

        }
          .frame(minWidth: 450, minHeight: 450)
          .padding()
    }
}

struct RunningEVM<Driver: EVMDriver>: View {
    @State private var calldata = ""
    @State private var msg_value = "0"
    @State private var call_return_value = ""
    @State private var error_msg_evm = ""
    @State private var error_msg_contract_eval = ""
    // These can be updated from outside this view
    // as the EVM runs
    @Binding var target_addr: String
    @Binding var msg_sender: String
    @Binding var msg_sender_eth_balance: String
    let d : Driver
    @ObservedObject private var evm_run_controls = EVMRunStateControls.shared
    @ObservedObject private var load_chain_model = LoadChainModel.shared
    // opcode things
    @State private var present_opcode_select_sheet = false
    @Environment(\.dismiss) var dismiss
    @State private var opcodes_used : [OPCodeEnable] = []
    @State private var keccak_input = ""
    @State private var keccak_output = ""
    
    func dev_mode() {
        // entry_point(address,uint256)
        calldata = "f4bd333800000000000000000000000001010101010101010101010101010101010101010000000000000000000000000000000000000000000000004563918244f40000"
        msg_value = "6000000000000000000"
    }
    
    var body: some View {
        VStack {
            Text("Live Contract Interaction")
              .font(.title2)
            Button {
                dev_mode()
            }label: { Text("quick fill")}
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
                        TextField("0", text: $msg_value)
                    }
                    HStack {
                        Text("Target Addr")
                          .frame(width: 120, alignment: .leading)
                        TextField("target addr", text: $target_addr)
                    }
                    HStack {
                        Text("Return value")
                          .frame(width: 120, alignment: .leading)
                        TextField(call_return_value, text: $call_return_value)
                          .disabled(false)
                          .textSelection(.enabled)
                    }
                }
                VStack{
                    HStack {
                        Button {
                            keccak_output = d.keccak256(input: $keccak_input.wrappedValue)
                        } label: { Text("Keccak256") }
                        TextField("input...", text: $keccak_input)
                        TextField("output..", text: $keccak_output)
                    }
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
                    HStack {
                        Button {
                            print("calling run evm handler \(calldata)-\(msg_value)")
                            evm_run_controls.contract_currently_running = true
                            evm_run_controls.current_call_task = Task.detached {
                                let result = await d.call(
                                  calldata: calldata,
                                  target_addr: target_addr,
                                  msg_value: msg_value
                                )
                                
                                DispatchQueue.main.async {
                                    OpcodeCallbackModel.shared.hit_breakpoint = false
                                    evm_run_controls.contract_currently_running = false
                                    switch result {
                                    case .failure(reason: let r):
                                        error_msg_evm = r
                                    case .success(return_value: let r):
                                        error_msg_evm = ""
                                        call_return_value = r
                                    }
                                }
                            }
                            
                        } label: {
                            Text("Run contract").frame(width: 140)
                        }.disabled(evm_run_controls.contract_currently_running)
                          .frame(width: 160)
                        if evm_run_controls.contract_currently_running {
                            RotatingDotAnimation(param: .init(
                                                   inner_circle_width: 6,
                                                   inner_circle_height: 6,
                                                   inner_circle_offset: -12,
                                                   outer_circle_width: 20,
                                                   outer_circle_height: 20
                                                 ))
                        }
                    }
                    Button {
                        present_opcode_select_sheet.toggle()
                        print("ALL KNOWN OPCODES?", d.all_known_opcodes(), d.all_known_opcodes().count)
                    } label: {
                        Text("Break on OPCODE(s)").frame(width: 140)
                    }.frame(width: 160)
                    Button {
                        ExecutedOperations.shared.execed_operations = []
                        EVMRunStateControls.shared.contract_currently_running = false
                        OpcodeCallbackModel.shared.reset()

                        if let t = EVMRunStateControls.shared.current_call_task {
                            d.reset_evm(
                              enableOpCodeCallback: EVMRunStateControls.shared.breakpoint_on_call,
                              enableCallback: EVMRunStateControls.shared.record_executed_operations,
                              useStateInMemory: load_chain_model.db_kind == DBKind.InMemory
                            )
                            t.cancel()
                            EVMRunStateControls.shared.current_call_task = nil
                        }
                        
                        if let t = OpcodeCallbackModel.shared.current_opcode_continue_task {
                            t.cancel()
                            OpcodeCallbackModel.shared.current_opcode_continue_task = nil
                        }
                    } label : {
                        Text("Reset").frame(width: 140)
                    }.frame(width: 160)
                    Toggle(isOn: Binding<Bool>(
                             get: {
                        evm_run_controls.breakpoint_on_call
                    },
                             set: {
                        d.enable_opcode_call_callback(yes_no: $0)
                        evm_run_controls.breakpoint_on_call = $0
                    }
                           ), label: {
                                  Text("Break on CALL")
                              })
                    Toggle(isOn: Binding<Bool>(
                             get: {
                        evm_run_controls.record_executed_operations
                    },
                             set: {
                        d.enable_exec_callback(yes_no: $0)
                        evm_run_controls.record_executed_operations = $0
                    }
                           ), label: {
                                  Text("Record all Operations")
                              })
                }
            }
              .padding()
              .background()
        }.onAppear {
            var codes = d.all_known_opcodes()
            codes.sort()
            for c in codes {
                opcodes_used.append(.init(name: c))
            }
        }.sheet(isPresented: $present_opcode_select_sheet,
                onDismiss: {
                    for c in opcodes_used {
                        if c.enabled {
                            d.enable_breakpoint_on_opcode(yes_no:true)
                            return
                        }
                    }
                }, content: {
                       BreakOnOpcodes(known_ops: $opcodes_used, d: d)
                   })

    }
}


#Preview("dev center") {
    EVMDevCenter(driver: StubEVMDriver())
      .frame(width: 1224, height: 860)
      .onAppear {
          let dummy_items : [ExecutedEVMCode] = [
            .init(pc: "0x07c9", op_name: "DUP2", opcode: "0x81", gas: 20684, gas_cost: 3, depth: 3, refund: 0),
            .init(pc: "0x07c9", op_name: "JUMP", opcode: "0x56", gas: 20684, gas_cost: 8, depth: 3, refund: 0)
          ]
          ExecutedOperations.shared.execed_operations.append(contentsOf: dummy_items)
      }
}

//#Preview("load existing db") {
//    LoadExistingDB(d: StubEVMDriver(), finished: { _, _ in
//        //
//    })
//    .frame(width: 480, height: 380)
//}



#Preview("state inspect") {
    StateInspector(d: StubEVMDriver())
      .onAppear {
          
      }
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

//#Preview("enabled EIPs") {
//    KnownEIPs(known_eips: .constant([
//        EIP(num: 1223, enabled: false),
//        EIP(num: 1559, enabled: true),
//        EIP(num: 44, enabled: false)])
//    )
//}

//#Preview("New Contract bytecode") {
//    NewContractByteCode(
//        contract_name: .constant(""),
//        contract_bytecode: .constant(""),
//        contract_abi: .constant("")
//    )
//}

//#Preview("BlockContext") {
//    BlockContext()
//}
