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
    @EnvironmentObject var current_head : CurrentBlockHeader

    var body : some View {
        VStack {
            VStack {
                HStack {
                    Text("Coinbase").frame(width: 80, alignment: .leading)
                    TextField("0x..", text: $model.coinbase)
                }
                HStack {
                    Text("Base Gas Price").frame(width: 80, alignment: .leading)
                    TextField("base gas", text: $model.base_gas)
                }
                HStack {
                    Text("Time").frame(width: 80, alignment: .leading)
                    TextField("time", text: $model.time)
                }
                HStack {
                    let num = "\(current_head.block_number)"
                    Text("Number").frame(width: 80, alignment: .leading)
                    TextField("block number",
                              text: Binding<String>(
                                get: {current_head.block_number == 0 ? "" : num},
                                set: {_ = $0})
                    )
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

struct CustomDisclosureGroupStyle<Label: View>: DisclosureGroupStyle {
    let button: Label
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            button
                .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                configuration.isExpanded.toggle()
            }
        }
        if configuration.isExpanded {
            configuration.content
                .padding(.leading, 30)
                .disclosureGroupStyle(self)
        }
    }
}


public struct EVMDevCenter<Driver: EVMDriver> : View {
    let d : Driver
    
    @State private var bytecode_add = false
    @State private var current_code_running = ""
    @State private var present_eips_sheet = false
    @State private var present_load_db_sheet = false
    @State private var current_contract_detail_tab = 0
    
    @AppStorage("show_first_load_help") private var show_first_load_help = true
    
    // NOTE Use observedobject on singletons
    @ObservedObject private var chaindb = LoadChainModel.shared
    @ObservedObject private var evm_run_controls = EVMRunStateControls.shared
    @ObservedObject private var execed_ops = ExecutedOperations.shared
    @ObservedObject private var current_block_header = CurrentBlockHeader.shared
    @ObservedObject private var contracts = LoadedContracts.shared
    @ObservedObject private var error_model = RuntimeError.shared
    
    @State private var present_load_contract_sheet = false
    
    public init(driver : Driver) {
        d = driver
    }
    
    @State var eips_used : [EIP] = []
    @State private var current_tab_runtime_eval = 0
    
    public var body: some View {
        VStack {
            VSplitView {
                HStack {
                    NavigationStack {
                        VStack {
                            Text("Contracts")
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
                    HSplitView {
                        TabView(selection: $current_contract_detail_tab) {
                            VStack {
                                if let c = contracts.current_selection {
                                    VStack {
                                        HStack {
                                            Text("Creator Address").frame(width: 100, alignment: .leading)
                                            TextField(c.deployer_address, text: Binding<String>(
                                                get: { c.deployer_address },
                                                set: { c.deployer_address = $0 }
                                            ))
                                        }
                                        HStack {
                                            Text("Gas limit").frame(width: 100, alignment: .leading)
                                            TextField(c.gas_limit_deployment, text: Binding<String>(
                                                get: { c.gas_limit_deployment },
                                                set: { c.gas_limit_deployment = $0 }
                                            ))
                                        }
                                        HStack {
                                            Text("Eth Balance").frame(width: 100, alignment: .leading)
                                            TextField(c.eth_balance, text: Binding<String>(
                                                get: { c.eth_balance },
                                                set: { c.eth_balance = $0 }
                                            ))
                                        }
                                        HStack {
                                            Text("Deployed Address").frame(width: 100, alignment: .leading)
                                            TextField(c.address, text: Binding<String>(
                                                get: { c.address },
                                                set: { _ = $0 }
                                            )).disabled(true)
                                        }
                                        HStack {
                                            Text("Deployed Gas Cost").frame(width: 100, alignment: .leading)
                                            TextField("\(Int(c.gas_limit_deployment)! - c.deployment_gas_cost)", text: Binding<String>(
                                                get: { "\(Int(c.gas_limit_deployment)! - c.deployment_gas_cost)" },
                                                set: { _ = $0 }
                                            )).disabled(true)
                                        }
                                        Button {
                                            d.create_new_contract(
                                                code: c.bytecode,
                                                creator_addr: c.deployer_address,
                                                contract_nickname: c.name,
                                                gas_amount: c.gas_limit_deployment,
                                                initial_gas: c.eth_balance
                                            )
                                        } label: {
                                            Text("Deploy contract to state")
                                        }
                                    }
                                } else {
                                    Text("select a contract from sidebar ")
                                }
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                            .background()
                            .tabItem{ Text("Deployment") }.tag(0)
                            VStack {
                                Text("TODO Show state of contract (eth balance, nonce, blah) ")
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background()
                            .tabItem{ Text("Contract State") }.tag(1)
                            VStack {
                                if let contract = contracts.current_selection {
                                    VStack {
                                        ScrollView {
                                            Text(contract.bytecode)
                                                .lineLimit(nil)
                                                .frame(maxWidth:.infinity, maxHeight:.infinity)
                                                .background()
                                        }
                                    }
                                } else {
                                    Text("select a contract from sidebar")
                                }
                            }.tabItem { Text("Raw Bytecode") }.tag(2)
                            VStack {
                                if let c = contracts.current_selection {
                                    EditState(driver: d,
                                              c: Binding<LoadedContract>(get: {c}, set: { _ in ()}),
                                              overrides: c.state_overrides
                                    )
                                } else {
                                    Text("select a contract from sidebar")
                                }
                            }
                            .padding()
                            .tabItem{ Text("Edit State") }.tag(3)
                        }
                        TabView {
                            VStack {
                                BlockContext()
                                    .environmentObject(current_block_header)
                                    .frame(maxWidth: .infinity)
                                HStack {
                                    Button {
                                        present_load_db_sheet.toggle()
                                    } label: {
                                        Text("Load Database")
                                    }.disabled(chaindb.is_chain_loaded)
                                    Button {
                                        d.close_chaindata()
                                    } label: {
                                        Text("Close Database")
                                    }.disabled(!chaindb.is_chain_loaded)
                                }
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
                                .padding()
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
                            CommonABIs().tabItem { Text("Common ABIs") }.tag(3)
                        }
                    }
                }.frame(minHeight: 125, maxHeight: 275)
                HSplitView {
                    TabView(selection: $current_tab_runtime_eval) {
                        VStack {
                            ScrollViewReader { (proxy: ScrollViewProxy) in
                                HStack {
                                    Text("\(execed_ops.execed_operations.count) Executed Operations")
                                        .font(.title2)
                                }.padding([.leading, .trailing], 10)
                                Table(execed_ops.execed_operations) {
                                    TableColumn("PC", value: \.pc)
                                    TableColumn("OPNAME", value: \.op_name)
                                    TableColumn("OPCODE", value: \.opcode)
                                    TableColumn("GAS", value: \.gas_cost)
                                }
                                .frame(maxHeight: .infinity)
                                .onReceive(execed_ops.$execed_operations,
                                           perform: { item in
                                    let id = item.last
                                    proxy.scrollTo(id)
                                })
                                HStack {
                                    Text("\(execed_ops.total_gas_cost_so_far) total gas cost")
                                        .font(.title2)
                                    Spacer()
                                    Text("\(execed_ops.total_static_gas_cost_so_far) static gas")
                                        .font(.title2)
                                    Spacer()
                                    Text("\(execed_ops.total_dynamic_gas_cost_so_far) dynamic gas")
                                        .font(.title2)
                                }
                                .padding([.leading, .trailing], 10)
                                .frame(maxWidth: .infinity)
                            }
                            
                        }.tabItem { Text("Execution Table") }.tag(0)
                        VStack {
                            if let contract = contracts.current_selection {
                                ABIEncode(loaded_contract: contract)
                                    .padding()
                                    .background()
                            } else {
                                Text("no contract selected")
                            }
                        }.tabItem { Text("ABI")}.tag(1)
                        CallTree().tabItem {
                            Text("CALL tree")
                        }.tag(2)
                        JumpTree().tabItem {
                            Text("JUMP tree")
                        }.tag(3)
                    }
                    BreakpointView(d: d).frame(maxWidth: .infinity)
                }.padding(10).frame(maxHeight: .infinity)
                RunningEVM(d: d, target_addr: Binding<String>(
                    get: {
                        if let contract = contracts.current_selection {
                            return contract.address
                        }
                        return ""
                    },
                    set: {
                        if let contract = contracts.current_selection {
                            contract.address = $0
                            contracts.current_selection = contract
                        }
                    }
                ))
                .environmentObject(evm_run_controls)
            }
            .frame(maxWidth: .infinity)
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
            .sheet(isPresented: $show_first_load_help) {
                VStack {
                    Text("welcome to evm-dev-station")
                    Text("load a chain database or work directly against an in-memory state db")
                    Button {
                        show_first_load_help.toggle()
                    } label: {
                        Text("dont show this again")
                    }
                }.frame(width: 400, height: 300)
            }
            .sheet(isPresented: $present_load_db_sheet,
                   onDismiss: {
                if !chaindb.is_chain_loaded &&
                    !chaindb.chaindata_directory.isEmpty {
                    withAnimation {
                        chaindb.show_loading_db = true
                    }
                    
                    d.load_chaindata(
                        chaindb_pathdir: chaindb.chaindata_directory,
                        db_kind: chaindb.db_kind.rawValue,
                        ancientdb_pathdir: chaindb.ancientdb_dir,
                        at_block: Int(chaindb.at_block_number)
                    )
                }
            }, content: {
                LoadExistingDB(d:d)
            })
            .sheet(isPresented: $present_eips_sheet,
                   onDismiss: {
                // just hold onto it
            }, content: { KnownEIPs() })
            .sheet(isPresented: $error_model.show_error,
                   content: {
                VStack {
                    TextField(error_model.error_reason, text: $error_model.error_reason)
                        .textSelection(.enabled)
                        .disabled(true)
                        .lineLimit(5, reservesSpace: true)
                    Button {
                        error_model.show_error.toggle()
                    } label: {
                        Text("dismiss")
                    }
                }.frame(width: 400, height: 300)
            })
            .sheet(isPresented: $bytecode_add) {
            } content: {
                NewContractFromInput()
            }
        }
        .padding(10)
    }
}

struct JumpTree: View {
    var body: some View {
        Text("temp")
    }
}

struct CallTree : View {
    @ObservedObject private var evm_execed = ExecutedOperations.shared
    
    var body: some View {
        HStack {
            List(evm_execed.call_tree, children: \.Children) { item in
                HStack {
                    Image(systemName: item.icon)
                    Text(item.Kind)
                    HStack {
                        Text("FROM")
                        Text(item.Caller)
                    }
                    HStack {
                        Text("TO")
                        Text(item.Target)
                    }
                }
            }
        }.frame(maxHeight: .infinity)
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

struct NewContractFromInput: View {
    @State private var contract_name : String = ""
    @State private var contract_bytecode : String = ""
    @State private var contract_abi: String = ""
    
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
                    let already_have = LoadedContracts.shared.contracts.filter({$0.name == contract_name})
                    if already_have.count > 0 {
                        dismiss()
                        RuntimeError.shared.error_reason = "Already have contract loaded with name `\(contract_name)`"
                        RuntimeError.shared.show_error = true
                        return
                    }
                    
                    LoadedContracts.shared.contracts.append(sample_contract)
                    LoadedContracts.shared.current_selection = LoadedContracts.shared.contracts.last
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


struct KnownEIPs: View {
    @State var enable_all = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @ObservedObject private var evm_run_state = EVMRunStateControls.shared
    
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
            Table(evm_run_state.eips_used) {
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
                            if let index = evm_run_state.eips_used.firstIndex(where: { $0.id == d.id }) {
                                evm_run_state.eips_used[index].enabled = $0
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

struct StackListRowView: View {
    @ObservedObject var item: StackItem
    
    var body: some View {
        HStack {
            Text("\(item.index)")
            Spacer()
            Text(item.name).help("formatted decimal: \(item.pretty)")
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
                    let names = Array(c.methods.keys)
                        .filter { !$0.hasPrefix("0x") }
                        .filter { $0.hasSuffix(")") }
                        .sorted()
                    
                    List(names, id: \.self,
                         selection: $selected) { item in
                        Text(item)
                    }
                    Button {
                        if selected == "quoteExactInputSingle(address,address,uint24,uint256,uint160)" {
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
                        } else {
                            print(selected)
                        }
                    } label: {
                        Text("dev quick fill in params")
                    }.disabled(selected != "quoteExactInputSingle(address,address,uint24,uint256,uint160)")
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
                                       let element = c.allMethods.first(where: { $0.signature == selected }) {
                                        // TODO This is wrong because if inputs is 0, then the ForEach never goes off
                                        ForEach(Array(zip(element.inputs.indices, element.inputs)), id: \.1.name) {index, input in
                                            HStack {
                                                Text(input.name)
                                                TextField(input.name, text: Binding<String>(
                                                    get: {
                                                        let method_name = element.signature
                                                        if let had_it = fields[method_name] {
                                                            return had_it[index]
                                                        }
                                                        
                                                        fields[method_name] = [String](repeating: "", count: element.inputs.count)
                                                        return ""
                                                    },
                                                    set: {
                                                        let n = element.signature
                                                        fields[n]![index] = $0
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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


struct BreakpointView: View {
    @ObservedObject private var callbackmodel: OpcodeCallbackModel = OpcodeCallbackModel.shared
    @ObservedObject private var execed = ExecutedOperations.shared
    @State private var use_modified_values = false
    @Environment(\.openURL) var openURL
    @State private var possible_signature_names : [String] = []
    @State private var selected : String?
    @State private var current_tab = 1
    let d : EVMDriver
    
    var body: some View {
        VStack {
            TabView(selection: $current_tab,
                    content: {
                VStack {
                    VStack {
                        HStack {
                            Text("caller").frame(width: 75)
                            TextField("", text: $callbackmodel.current_caller)
                            Button {
                                if !callbackmodel.current_caller.isEmpty {
                                    let s = "https://etherscan.com/address/\(callbackmodel.current_caller)"
                                    guard let link = URL(string: s) else {
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
                                    let s = "https://etherscan.com/address/\(callbackmodel.current_callee)"
                                    guard let link = URL(string: s) else {
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
                                let s = "\(SIG_DIR_URL)/api/v1/signatures/?format=json&hex_signature=0x\(sig)"
                                guard let url = URL(string:s) else {
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
                                d.continue_evm_exec_break_on_call(
                                    yes_no: use_modified_values,
                                    caller: callbackmodel.current_caller,
                                    callee: callbackmodel.current_callee,
                                    payload:callbackmodel.current_args
                                )
                                
                                DispatchQueue.main.async {
                                    possible_signature_names = []
                                    callbackmodel.selected_stack_item = nil
                                }
                                
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
                //                          .frame(height: 280)
                HStack {
                    VStack {
                        Text("Current Stack ")
                        Text("(bottom of list is latest value pushed to stack)")
                        List(Array(zip(callbackmodel.current_stack.indices, callbackmodel.current_stack)),
                             id: \.1.self,
                             selection: $callbackmodel.selected_stack_item) { index, item in
                            StackListRowView(item: item)
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
                                d.continue_evm_exec_break_on_opcode(
                                    yes_no: callbackmodel.use_modified_values,
                                    stack: callbackmodel.current_stack,
                                    mem: callbackmodel.current_memory
                                )
                                callbackmodel.selected_stack_item = nil
                            } label: {
                                Text("Continue")
                            }.disabled(!callbackmodel.hit_breakpoint)
                        }.padding([.bottom], 5)
                    }
                }
                .tabItem{ Text("Stack & Memory").help("live stack and memory") }.tag(1)
                //                          .frame(height: 280)
                VStack {
                    Text("\(execed.state_records.count) total state loads/stores")
                    Table(execed.state_records) {
                        TableColumn("Kind", value: \.Kind).width(min: 55, ideal: 55, max: 90)
                        TableColumn("Storage") { st in
                            VStack {
                                HStack {
                                    Text("Contract Address")
                                    Button {
                                        let s = "https://etherscan.com/address/\(st.Address)"
                                        guard let link = URL(string: s) else {
                                            return
                                        }
                                        openURL(link)
                                    } label : {
                                        Text(st.Address)
                                    }
                                }.frame(alignment: .leading)
                                if st.Kind == "SLOAD" {
                                    VStack {
                                        HStack {
                                            Text("Key")
                                            Spacer()
                                            Text(st.Key).textSelection(.enabled)
                                        }
                                        HStack {
                                            Text("Value")
                                            Spacer()
                                            Text(st.BeforeValue).textSelection(.enabled)
                                        }
                                    }
                                    
                                } else if st.Kind == "SSTORE" {
                                    VStack {
                                        HStack {
                                            Text("Key")
                                            Spacer()
                                            Text(st.Key).textSelection(.enabled)
                                        }
                                        HStack {
                                            Text("Prior Value")
                                            Spacer()
                                            Text(st.BeforeValue).textSelection(.enabled)
                                        }
                                        HStack {
                                            Text("After Update")
                                            Spacer()
                                            Text(st.AfterValue).textSelection(.enabled)
                                        }
                                    }
                                }
                            }
                        }
                        // TableColumn("Key", value: \.Key)
                        // TableColumn("Value", value:\.Value)
                    }
                }.tabItem{ Text("Storage") }.tag(2)
                SideEVM(d:d).tabItem { Text("Quick Side EVM") }.tag(3)
            })
        }
    }
}



struct SideEVM : View {
    let d : EVMDriver
    @State private var use_current_state = true
    @State private var target_addr = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    @ObservedObject private var side_evm_model = SideEVMResult.shared
    
    var body: some View {
        VStack {
            Toggle(isOn: $use_current_state) {
                Text("use current state")
            }
            HStack {
                Text("Target addr (USDC) example")
                TextField("", text: $target_addr)
            }
            HStack {
                Text("call input")
                TextField("..input", text: $side_evm_model.call_input)
            }
            HStack {
                Text("Call result")
                TextField("..result", text: $side_evm_model.call_result, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .disabled(false)
                    .textSelection(.enabled)
            }
            Button {
                d.evm_side_run(param: BridgeCmdEVMSideRun(
                    use_current_state: true,
                    callparams: BridgeCmdRunContract(
                        calldata: side_evm_model.call_input,
                        caller_addr: EMPTY_ADDR,
                        target_addr: target_addr,
                        msg_value: "0",
                        gas_price: "1",
                        gas_limit: 900_000)))
            } label: { Text("Run side EVM") }
        }
    }
}

#Preview("side evm") {
    SideEVM(d: StubEVMDriver()).frame(width: 600, height: 400)
}

#Preview("breakpoint view") {
    BreakpointView(d : StubEVMDriver())
}

#Preview("Common ABIs") {
    CommonABIs().frame(width: 600, height: 400)
}

struct CommonABIs : View {
    @ObservedObject private var abis = CommonABIsModel.shared
    @State private var selected : String?
    @State private var present_add_abi_sheet = false
    @State private var fields : [String: [String]] = [:]
    @State private var encoded = ""
    @State private var decode_input = ""
    @State private var decoded_output : [String: Any]? = [:]
    
    var body: some View {
        HStack {
            List(Array(abis.abis.keys).sorted(), id: \.self, selection: $selected) {item in
                Text(item.description)
            }.frame(maxWidth: 325)
            TabView {
                VStack {
                    // TODO This doesn't work right yet
                    if let s = selected,
                       let element = abis.all_methods.first(where: {$0.signature == s}) {
                        VStack {
                            if element.inputs.count == 0 {
                                Spacer()
                                    .frame(height: 1)
                            } else {
                                ForEach(Array(zip(element.inputs.indices, element.inputs)), id: \.1.name) { index, input in
                                    HStack {
                                        Text(input.name)
                                        TextField(input.name, text: Binding<String>(
                                            get: {
                                                return fields[element.signature]![index]
                                            },
                                            set: {
                                                fields[element.signature]![index] = $0
                                            }
                                        ))
                                    }
                                }
                            }
                            HStack {
                                Button {
                                    if let result = element.encodeParameters(fields[s]!) {
                                        encoded = result.toHexString()
                                    }
                                } label: { Text("Encode") }
                                TextField("...", text:$encoded)
                            }
                        }
                    } else {
                        Button {
                            present_add_abi_sheet.toggle()
                        } label: { Text("Add ABI") }
                    }
                }
                .tabItem { Text("Encode") }.tag(0)
                VStack {
                    // TODO This doesn't work right yet
                    if let s = selected,
                       let element = abis.all_methods.first(where: {$0.signature == s}) {
                        HStack {
                            Button {
                                decoded_output = element.decodeReturnData(Data(hex: decode_input))
                            } label: {
                                Text("decode")
                            }.disabled(decode_input.isEmpty)
                            TextField("return...", text: $decode_input)
                        }
                        HStack {
                            Text("results(s)")
                            if var have = decoded_output {
                                let _ = have.removeValue(forKey: "_success")
                                let zipped = Array(zip(have.keys, have.values))
                                List(zipped, id:\.0.self) { item in
                                    HStack {
                                        Text(item.0)
                                        Spacer()
                                        Text("\((item.1 as AnyObject).description)")
                                    }
                                }
                            }
                        }
                    } else {
                        Button {
                            present_add_abi_sheet.toggle()
                        } label: { Text("Add ABI") }
                    }
                }
                .tabItem{ Text("Decode") }.tag(1)
            }
        }.sheet(isPresented: $present_add_abi_sheet, content: {
            VStack {
                Text("some ABI input thing")
            }.frame(width: 400, height: 300)
        })
        .onAppear {
            for i in abis.all_methods {
                fields[i.signature] = [String](repeating: "", count: i.inputs.count)
            }
        }
    }
}

struct LoadExistingDB : View {
    let d : EVMDriver
    @Environment(\.dismiss) var dismiss
    @State private var options = ["pebble", "leveldb"]
    @State private var selected_option = "pebble"
    @State private var present_fileimporter = false
    @State private var present_fileimporter_ancient = false
    @State private var at_block_number = ""
    @ObservedObject private var chain = LoadChainModel.shared
    
    var body: some View {
        VStack {
            Picker(selection: $selected_option,
                   label: Text("Database Kind").frame(width: 100, alignment: .center)) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
                   .tint(.black)
                   .pickerStyle(.segmented)
            HStack {
                Button {
                    present_fileimporter.toggle()
                } label: {
                    Text("Chaindata").frame(width: 84, alignment: .center)
                }
                .fileImporter(isPresented: $present_fileimporter,
                              allowedContentTypes: [.directory]) { result in
                    switch result {
                    case .success(let directory):
                        chain.chaindata_directory = directory.path()
                        // gain access to the directory
                    case .failure(let error):
                        // how would this even happen?
                        RuntimeError.shared.error_reason = error.localizedDescription
                        RuntimeError.shared.show_error = true
                    }
                }
                TextField("directory", text: $chain.chaindata_directory)
            }
            HStack {
                Button {
                    present_fileimporter_ancient.toggle()
                } label: {
                    Text("AncientDB").frame(width: 84, alignment: .center)
                }
                .fileImporter(isPresented: $present_fileimporter_ancient,
                              allowedContentTypes: [.directory]) { result in
                    switch result {
                    case .success(let directory):
                        chain.ancientdb_dir = directory.path()
                        // gain access to the directory
                    case .failure(let error):
                        // how would this even happen?
                        RuntimeError.shared.error_reason = error.localizedDescription
                        RuntimeError.shared.show_error = true
                    }
                }
                TextField("optional directory but might need it", text: $chain.ancientdb_dir)
            }
            HStack {
                Text("BlockNumber").frame(width: 100, alignment: .center)
                TextField("defaults to latest block if none given", text: $chain.at_block_number)
            }
            HStack {
                Spacer()
                Button {
                    if selected_option == "pebble" {
                        chain.db_kind = .GethDBPebble
                    } else {
                        chain.db_kind = .GethDBLevelDB
                    }
                    dismiss()
                } label: {
                    Text("Ok")
                }
            }
        }
        .padding()
        .frame(width: 500, height: 300)
    }
}

struct BreakOnOpcodes: View {
    @ObservedObject var evm_run_state = EVMRunStateControls.shared
    @State var break_on_all = false
    @Environment(\.dismiss) var dismiss
    let d : EVMDriver
    
    @ObservedObject private var controls = EVMRunStateControls.shared
    
    var body: some View {
        VStack {
            HStack {
                Text("\(evm_run_state.opcodes_used.count) known opcodes")
                Toggle("all", isOn: $break_on_all)
            }
            Table(evm_run_state.opcodes_used) {
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
                            if let index = evm_run_state.opcodes_used.firstIndex(where: { $0.id == d.id }) {
                                evm_run_state.opcodes_used[index].enabled = $0
                                self.d.enable_breakpoint_on_opcode(yes_no:$0,
                                                                   opcode_name:evm_run_state.opcodes_used[index].name)
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

struct InitialHelpView : View {
    var body: some View {
        VStack {
            Text("Welcome to EVM Dev station")
        }
    }
}

struct RunningEVM<Driver: EVMDriver>: View {
    let d : Driver
    @Binding var target_addr : String
    @ObservedObject private var evm_run_controls = EVMRunStateControls.shared
    @ObservedObject private var call_params = EVMRunStateControls.shared.current_call_params
    @ObservedObject private var load_chain_model = LoadChainModel.shared
    @State private var present_opcode_select_sheet = false
    @Environment(\.dismiss) var dismiss
    @State private var keccak_input = ""
    @State private var keccak_output = ""
    private let text_width : CGFloat = 75
    
    var body: some View {
        VStack {
            HStack {
                TabView {
                    HStack {
                        VStack {
                            HStack {
                                Text("Input")
                                    .frame(width: text_width, alignment: .leading)
                                TextField("calldata", text: $call_params.calldata)
                            }
                            HStack {
                                Text("Value")
                                    .frame(width: text_width, alignment: .leading)
                                TextField("0", text: $call_params.msg_value)
                            }
                            HStack {
                                Text("Target Addr")
                                    .frame(width: text_width, alignment: .leading)
                                TextField("target addr", text: $target_addr)
                            }
                            HStack {
                                Text("Gas Price").frame(width: text_width, alignment: .leading)
                                TextField("gas price", text: $call_params.gas_price)
                            }
                            HStack {
                                Text("Gas limit").frame(width: text_width, alignment: .leading)
                                TextField("900000", text: $call_params.gas_limit)
                            }
                        }
                        VStack {
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
                                TextField("msg.sender", text: $call_params.caller_addr)
                            }
                            HStack {
                                Text("Sender eth balance")
                                    .frame(width: 120, alignment: .leading)
                                TextField("eth balance", text: $call_params.caller_eth_bal)
                            }
                            HStack {
                                Text("Return value")
                                    .frame(width: 120, alignment: .leading)
                                TextField(evm_run_controls.call_return_value,
                                          text: $evm_run_controls.call_return_value)
                                .disabled(false)
                                .textSelection(.enabled)
                            }
                            HStack {
                                Text("EVM Error")
                                    .frame(width: 120, alignment: .leading)
                                TextField("last failure message", text: $evm_run_controls.evm_error)
                            }
                        }

                    }.tabItem { Text("Fresh run") }.tag(0)
                    VStack { Text("something")}.tabItem { Text("History") }.tag(1)
                }
                .padding([.leading, .trailing], 5)
                .frame(height: 200)
                VStack {
                    HStack {
                        Button {
                            withAnimation {
                                evm_run_controls.contract_currently_running = true
                            }
                            // TODO come back validations
                            call_params.target_addr = target_addr
                            if call_params.caller_addr.isEmpty {
                                call_params.caller_addr = EMPTY_ADDR
                            }
                            d.call(
                                calldata: call_params.calldata,
                                caller_addr: call_params.caller_addr,
                                target_addr: call_params.target_addr,
                                msg_value: call_params.msg_value,
                                gas_price: call_params.gas_price,
                                gas_limit: Int(call_params.gas_limit) ?? 900_000
                            )
                        } label: {
                            HStack {
                                Text("Run contract").frame(width: evm_run_controls.contract_currently_running ? 110 : 140, height: 25)
                                if evm_run_controls.contract_currently_running {
                                    RotatingDotAnimation(param: .init(
                                        inner_circle_width: 5,
                                        inner_circle_height: 5,
                                        inner_circle_offset: -5,
                                        outer_circle_width: 20,
                                        outer_circle_height: 20
                                    ))
                                }
                            }
                        }.disabled(evm_run_controls.contract_currently_running)
                            .frame(width: evm_run_controls.contract_currently_running ? 110 : 160)
                    }
                    Button { d.step_forward_one() } label: { Text("Step").frame(width: 140) }
                        .disabled(!evm_run_controls.step_each_op)
                        .frame(width: 160)
                    Button {
                        present_opcode_select_sheet.toggle()
                    } label: {
                        Text("Break on OPCODE(s)").frame(width: 140)
                    }.frame(width: 160)
                    Button {
                        ExecutedOperations.shared.reset()
                        EVMRunStateControls.shared.reset()
                        OpcodeCallbackModel.shared.reset()
                        RuntimeError.shared.reset()
                    } label : {
                        Text("Reset").frame(width: 140)
                    }.frame(width: 160)
                    Toggle(isOn: Binding<Bool>(
                        get: { evm_run_controls.breakpoint_on_call },
                        set: {
                            d.enable_opcode_call_callback(yes_no: $0)
                            evm_run_controls.breakpoint_on_call = $0
                        }
                    ), label: {
                        Text("Break on CALL")
                    })
                    Toggle(isOn: Binding<Bool>(
                        get: { evm_run_controls.step_each_op },
                        set: {
                            d.enable_step_each_op(yes_no: $0)
                            evm_run_controls.step_each_op = $0
                        }
                    ), label: {
                        Text("Step OPCODE one by one")
                    })
                }
            }
            .padding()
            .background()
        }
        .sheet(isPresented: $present_opcode_select_sheet,
               onDismiss: {
            for c in evm_run_controls.opcodes_used {
                if c.enabled {
                    d.enable_breakpoint_on_opcode(yes_no:true, opcode_name: c.name)
                }
            }
        }, content: {
            BreakOnOpcodes(d: d)
        }
        )
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
            LoadedContracts.shared.contracts = [sample_contract]
            
        }
}

#Preview("load existing db") {
    LoadExistingDB(d: StubEVMDriver())
        .frame(width: 480, height: 380)
}



#Preview("state inspect") {
    StateInspector(d: StubEVMDriver())
        .onAppear {
            
        }
        .frame(width: 768, height: 480)
}

#Preview("running EVM") {
    RunningEVM(
        d: StubEVMDriver(),
        target_addr: .constant("")
    ).frame(width: 768)
}

struct EditState<Driver: EVMDriver> : View {
    let driver : Driver
    @Binding var c : LoadedContract
    @State private var select: StateChange?
    @State private var new_item_lookup_name = ""
    @ObservedObject var overrides: StateChanges
    
    var body: some View {
        VStack {
            HStack {
                List($overrides.overrides,
                     id: \.self,
                     selection: $select) {row in
                    Text(row.nice_name.wrappedValue).help(row.key.wrappedValue)
                }.frame(maxWidth: 150)
                VStack {
                    if let st = select {
                        VStack {
                            VStack {
                                HStack {
                                    Text("Key").frame(width: 120, alignment: .leading)
                                    TextField("state key", text: Binding<String>(
                                        get: { st.key },
                                        set: { st.key = $0 }
                                    ), axis: .vertical).lineLimit(2, reservesSpace: true)
                                }
                                HStack {
                                    Text("Original Value").frame(width: 120, alignment: .leading)
                                    TextField("..",
                                              text: .constant(st.original_value),
                                              axis: .vertical)
                                    .textSelection(.enabled)
                                    .disabled(true)
                                    .lineLimit(2, reservesSpace: true)
                                }
                                HStack {
                                    Text("Modified Value").frame(width: 120, alignment: .leading)
                                    TextField("..", text: Binding<String>(
                                        get: { st.new_value },
                                        set: { st.new_value = $0 }
                                    ), axis: .vertical).lineLimit(2, reservesSpace: true)
                                }
                            }
                            HStack {
                                Button {
                                    driver.write_contract_state(addr: c.address, key: st.key, value: st.new_value)
                                } label: { Text("Update value to state")}
                            }
                        }
                    } else {
                        VStack {
                            HStack {
                                Text("Helper copy paste for 0")
                                Text(EMPTY_HASH).textSelection(.enabled)
                            }
                            HStack {
                                Button {
                                    driver.read_contract_state(addr: c.address, key: c.state_overrides.temp_key)
                                } label: { Text("Do State Lookup") }
                                    .frame(width: 120, alignment: .leading)
                                TextField("state key", text: $c.state_overrides.temp_key, axis: .vertical)
                                    .lineLimit(2, reservesSpace: true)
                            }
                            HStack {
                                Text("Value")
                                    .frame(width: 120, alignment: .leading)
                                TextField("...",
                                          text: Binding<String>(
                                            get: { c.state_overrides.temp_value },
                                            set: { c.state_overrides.temp_value = $0 }
                                          ), axis: .vertical)
                                .lineLimit(2, reservesSpace: true)
                            }
                            HStack {
                                Button {
                                    if new_item_lookup_name.isEmpty {
                                        return
                                    }
                                    let new_record = StateChange(
                                        nice_name: new_item_lookup_name,
                                        key: c.state_overrides.temp_key,
                                        original_value: c.state_overrides.temp_value,
                                        new_value: ""
                                    )
                                    c.state_overrides.overrides.append(new_record)
                                    c.state_overrides.temp_key = ""
                                    c.state_overrides.temp_value = ""
                                    new_item_lookup_name = ""
                                } label : { Text("Save to list")  }
                                    .frame(width: 120, alignment: .leading)
                                TextField("some name", text: $new_item_lookup_name)
                            }
                        }.frame(maxHeight: .infinity)
                    }
                }.frame(maxWidth: .infinity)
            }
        }
    }
}


#Preview("Edit State") {
    EditState(driver: StubEVMDriver(),
              c: .constant(sample_contract),
              overrides: sample_contract.state_overrides)
    .frame(width: 600, height: 300)
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
