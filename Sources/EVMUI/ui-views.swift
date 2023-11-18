//
//  SwiftUIView.swift
//
//
//  Created by Edgar Aroutiounian on 10/24/23.
//

import SwiftUI
import DevStationCommon
import Charts
import SwiftData
// for withObservationTracking but it doesn't work with continuous firing, so dont need it
//import Observation

public struct PreferencesView: View {
    public init() {
        
    }
    public var body: some View {
        VStack {
            Text("TODO toggle App logging")
        }
        .frame(width: 500, height: 400)
    }
}

#Preview("Preferences Control") {
    PreferencesView()
}

struct LackingInput: View {
    @Environment(\.dismiss) var dismiss
    let reason : String
    var body: some View {
        VStack {
            Text("Cant do it because \(reason)")
            Button("OK") {
                dismiss()
            }
        }.frame(width: 300, height: 250)
    }
}

struct WatchCompileDeploy: View {
    @Bindable private var compiler = SolidityCompileHelper.shared
    @Environment(\.dismiss) var dismiss
    @State private var present_fileimporter = false
    @State private var present_bad_input_sheet = false
    @State private var bad_input_reason = ""
    
    var body: some View {
        VStack {
            Form {
                Section("Paths to Helper Programs") {
                    TextField("Solidity Compiler", text: Binding<String>(
                        get: { compiler.solc_path.path() },
                        set: { compiler.solc_path = URL(fileURLWithPath: $0) }
                    ))
                    TextField("jq utility", text: Binding<String>(
                        get: { compiler.jq_path.path() },
                        set: { compiler.jq_path = URL(fileURLWithPath: $0 )}
                    ))
                }
                Divider()
                Section("Contract Details") {
                    TextField(text: Binding<String>(
                        get : { compiler.watch_source?.path() ?? "" },
                        set: { compiler.watch_source = URL(string: $0) }
                    ), label: {
                        Button {
                            present_fileimporter.toggle()
                        } label : {
                            Text("Solidity Contract")
                        }
                        .fileImporter(isPresented: $present_fileimporter,
                                      allowedContentTypes: [.init(filenameExtension: "sol")!]) { result in
                            switch result {
                            case .success(let file_path):
                                compiler.watch_source = file_path
                                // gain access to the directory
                            case .failure(let error):
                                // how would this even happen?
                                RuntimeError.shared.error_reason = error.localizedDescription
                                RuntimeError.shared.show_error = true
                            }
                        }
                    })
                    
                    
                    
                    TextField("Contract Name", text: $compiler.contract_name)
                    TextField("Deploy to Address", text: $compiler.deploy_to_addr)
                }
            }
            Divider()
            Button {
                if compiler.contract_name.isEmpty {
                    present_bad_input_sheet = true
                    return
                }
                compiler.do_hot_reload = true
                dismiss()
            } label: {
                Text("Start Hot Reload").frame(maxWidth: .infinity, minHeight: 25)
            }
            Button {
                compiler.reset()
                dismiss()
            } label: {
                Text("Cancel").frame(maxWidth: .infinity, minHeight: 25)
            }
        }
        .padding(10)
        .sheet(isPresented: $present_bad_input_sheet, onDismiss: {
            
        }, content: {
            LackingInput(reason: bad_input_reason)
        })
    }
}

#Preview("Watch compile deploy") {
    WatchCompileDeploy().frame(width: 500, height: 300)
}

struct BlockContext : View {
    @Bindable private var model = BlockContextModel.shared
    @Bindable var current_head : CurrentBlockHeader
    
    var body : some View {
        TabView {
            ScrollView {
                Form {
                    Section("Block info") {
                        TextField("Coinbase", text: $model.coinbase)
                        TextField("Creation time", text: $model.time)
                        TextField("Number", text: $current_head.block_number)
                    }
                    Section("Gas Fields") {
                        TextField("Base Gas", text: $model.base_gas)
                        TextField("Gas Used", text: $model.gas_used)
                        TextField("Block Gas Limit", text: $model.gas_limit)
                    }
                }
            }.tabItem { Text("􀽽 HEAD Block") }.tag(0)
            ScrollView { VStack {
                Text("custom something")
            }}.tabItem { Text("Prior Block") }.tag(1)
        }
        .padding()
        .background()
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
    @Environment(\.modelContext) private var context
    @State private var bytecode_add = false
    @State private var current_code_running = ""
    @State private var current_contract_detail_tab = 0
    
    @AppStorage("show_first_load_help") private var show_first_load_help = true
    private var chaindb = LoadChainModel.shared
    private var evm_run_controls = EVMRunStateControls.shared
    private var execed_ops = ExecutedOperations.shared
    private var current_block_header = CurrentBlockHeader.shared
    @Bindable private var contracts = LoadedContracts.shared
    @Bindable private var error_model = RuntimeError.shared
    
    @State private var present_load_contract_sheet = false
    @State private var present_watch_compile_deploy_solidity_sheet = false
    @State private var present_eips_sheet = false
    @State private var present_load_db_sheet = false
    
    public init(driver : Driver) {
        d = driver
    }
    
    @State var eips_used : [EIP] = []
    @State private var current_tab_runtime_eval = 0
    @State private var op_selected : ExecutedEVMCode.ID?
    @State private var scroller : ScrollViewProxy?
    
    public var body: some View {
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
                            Text("Add Directly").frame(maxWidth: 150)
                        }
                        Button {
                            present_watch_compile_deploy_solidity_sheet.toggle()
                        } label: {
                            Text("Watch, compile, deploy").frame(width: 150)
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
                                Form {
                                    // Come back to this field because it doesn't
                                    // always make sense, aka when we load from chain
                                    // instead of direct deploy
                                    TextField("Creator Address", text: Binding<String>(
                                        get: { c.deployer_address },
                                        set: { c.deployer_address = $0 }
                                    ))
                                    TextField("Gas Limit", text: Binding<String>(
                                        get: { c.gas_limit_deployment },
                                        set: { c.gas_limit_deployment = $0 }
                                    ))
                                    TextField("Eth Balance", text: Binding<String>(
                                        get: { c.eth_balance },
                                        set: { c.eth_balance = $0 }
                                    ))
                                    TextField("Deployed Address", text: Binding<String>(
                                        get: { c.address },
                                        set: { _ = $0 }
                                    )).disabled(true)
                                    TextField("Deployed Gas Cost", text: Binding<String>(
                                        get: { "\(Int(c.gas_limit_deployment)! - c.deployment_gas_cost)" },
                                        set: { _ = $0 }
                                    )).disabled(true)
                                    
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
                        .tabItem{ Text("􁾨 Deployment") }.tag(0)
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
                            BlockContext(current_head: current_block_header)
                                .frame(maxWidth: .infinity)
                            HStack {
                                Button {
                                    present_load_db_sheet.toggle()
                                } label: {
                                    Text("Load Database")
                                }.disabled(chaindb.is_chain_loaded)
                                if chaindb.show_loading_db {
                                    RotatingDotAnimation(param: .init(
                                        inner_circle_width: 12,
                                        inner_circle_height: 12,
                                        inner_circle_offset: -9,
                                        outer_circle_width: 35,
                                        outer_circle_height: 35)
                                    ).frame(width: 35, height: 35)
                                } else {
                                    Spacer().frame(width: 35, height: 35)
                                }
                                Button {
                                    d.close_chaindata()
                                    BlockContextModel.shared.reset()
                                } label: {
                                    Text("Close Database")
                                }.disabled(!chaindb.is_chain_loaded)
                            }.padding([.bottom], 10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background()
                        .tabItem { Text("􁽇 Blockchain") }.tag(0)
                        StateDBDetails(current_head: current_block_header)
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
                        LookupTx(d: d).tabItem { Text("Lookup Tx") }.tag(4)
                    }
                }
            }.frame(minHeight: 150, maxHeight: 275).padding([.bottom], 10)
            HSplitView {
                TabView(selection: $current_tab_runtime_eval) {
                    VStack {
                        // TODO not working
                        HStack {
                            Text("\(execed_ops.execed_operations.count) Executed Operations")
                                .font(.title2)
                            //                                Spacer()
                            //                                Button {
                            //                                    withAnimation {
                            //                                        print(scroller, execed_ops.last_record?.id)
                            //                                        scroller?.scrollTo(op_selected, anchor: .bottom)
                            //                                    }
                            //                                } label: { Text("Go To Bottom").padding(10) }
                        }.padding([.leading, .trailing], 10)
                        ScrollViewReader { (proxy: ScrollViewProxy) in
                            Table(of: ExecutedEVMCode.self,
                                  selection: $op_selected) {
                                TableColumn("PC") { word in
                                    Text(word.pc).id(word.id)
                                }
                                TableColumn("OPNAME") {word in
                                    Text(word.op_name).id(word.id)
                                }
                                TableColumn("OPCODE") {word in
                                    Text(word.opcode).id(word.id)
                                }
                                TableColumn("GAS") { word in
                                    Text(word.gas_cost).id(word.id)
                                }
                            } rows: {
                                ForEach(execed_ops.execed_operations) {op in
                                    TableRow(op)
                                }
                            }
                            .onAppear {
                                scroller = proxy
                            }
                            .onChange(of: execed_ops.execed_operations) {
                                //                                    print("WHY NOT SCROLLING")
                                op_selected = execed_ops.execed_operations.last?.id
                                proxy.scrollTo(op_selected, anchor: .bottom)
                                //                                    op_selected = execed_ops.last_record?.id
                            }
                            .frame(maxHeight: .infinity)
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
                        
                    }.tabItem { Text("􀏣 EVM Execution") }.tag(0)
                    VStack {
                        if let contract = contracts.current_selection {
                            ABIEncode(loaded_contract: contract)
                                .padding()
                                .background()
                        } else {
                            Text("no contract selected")
                        }
                    }.tabItem { Text("􀎕 ABI")}.tag(1)
                    CallTree().tabItem { Text("􁝯 CALL tree") }.tag(2)
                    OPCodeChart().tabItem { Text("􀐾 OPCode Charts") }.tag(3)
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
                    ancientdb_pathdir: chaindb.ancientdb_dir
                )
            }
        }, content: {
            LoadExistingDB(d:d)
        })
        .sheet(isPresented: $present_watch_compile_deploy_solidity_sheet, 
               onDismiss: {
            let name = SolidityCompileHelper.shared.contract_name
            let already_have = LoadedContracts.shared.contracts.filter({$0.name == name})
            if already_have.count > 0 {
                RuntimeError.shared.error_reason = "Already have contract loaded with name `\(name)`"
                RuntimeError.shared.show_error = true
                return
            }
            
            if SolidityCompileHelper.shared.do_hot_reload {
                let contract = LoadedContract(
                    name: name,
                    bytecode: "",
                    address: SolidityCompileHelper.shared.deploy_to_addr
                )
                contract.enable_hot_reload = true
                LoadedContracts.shared.contracts.append(contract)
                LoadedContracts.shared.current_selection = contract
                
                SolidityCompileHelper.shared.on_compiled_contract = { contract_name in
                    let code = SolidityCompileHelper.shared.current_bytecode
                    let abi = SolidityCompileHelper.shared.current_abi
                    let contract = LoadedContracts.shared.contracts.first(where: { $0.name == contract_name })
                    // already have it, nothing changed so dont load
                    if contract?.bytecode == code {
                        return
                    }
                    contract?.bytecode = code
                    contract?.contract = try? EthereumContract(abi)
                    let c = contract!
                    d.create_new_contract(
                        code: c.bytecode,
                        creator_addr: c.deployer_address,
                        contract_nickname: c.name,
                        gas_amount: c.gas_limit_deployment,
                        initial_gas: c.eth_balance
                    )
                }
                
                SolidityCompileHelper.shared.start_folder_monitor()
            }
        }, content: {
            WatchCompileDeploy()
                .frame(width: 600, height: 450)
        })
        .sheet(isPresented: $present_eips_sheet,
               onDismiss: {
            // just hold onto it
        }, content: { KnownEIPs() })
        .sheet(isPresented: $error_model.show_error,
               content: {
            VStack {
                TextField(error_model.error_reason, 
                          text: $error_model.error_reason,
                          axis: .vertical)
                .textSelection(.enabled)
                .disabled(false)
                .lineLimit(10, reservesSpace: true)
                Button {
                    error_model.show_error.toggle()
                } label: {
                    Text("Ok")
                }
            }
            .padding()
            .frame(width: 500, height: 400)
        })
        .sheet(isPresented: $bytecode_add) {
        } content: {
            LoadContractFromInput()
        }
        .padding(10)
        .toolbar {
            HStack {
                Text("Something")
            }
        }
    }
}


struct OPCodeChart: View {
    @State private var selected_opcode : String?
    private var s = ExecutedOperations.shared
    
    var body: some View {
        VStack(alignment: .leading, content: {
            HStack {
                Text("OPCode analysis").font(.headline)
                Spacer()
                Button {
                    withAnimation {
                        ExecutedOperations.shared.opcode_freq = ExecutedOperations.shared.opcode_freq_temp
                    }
                } label: {
                    Text("Refresh").font(.headline)
                }
            }
            ScrollView(.horizontal) {
                Chart {
                    ForEach(Array(s.opcode_freq.enumerated()).sorted(by: { a, b in
                        a.element.value.count > b.element.value.count
                    }),
                            id: \.0.self) { opcode_usage in
                        BarMark(
                            x: .value("opcode", opcode_usage.element.key),
                            y: .value("count", opcode_usage.element.value.count),
                            width: 20
                            // width: s.opcode_freq.count < 30 ? 50 : 20
                            // width: min(20, s.opcode_freq.count < 30 ? 50 : 20)
                        )
                        .position(by: .value("opcode", opcode_usage.element.key))
                        .foregroundStyle(by: .value("opcode", opcode_usage.element.key))
                    }
                    if let selected_opcode,
                       let opcode_index_num = Array(s.opcode_freq.enumerated())
                        .sorted(by: {a, b in a.element.value.count > b.element.value.count})
                        .firstIndex(where: {$0.element.key == selected_opcode}),
                       let record = s.opcode_freq[selected_opcode] {
                        RectangleMark(x: .value("opcode", selected_opcode))
                            .foregroundStyle(.primary.opacity(0.2))
                            .annotation(
                                position: opcode_index_num < s.opcode_freq.count / 2 ? .trailing : .leading,
                                alignment: .center, spacing: 0
                            ) {
                                VStack(alignment: .leading) {
                                    Text("callers").font(.headline)
                                    Divider()
                                    ForEach(Array(record.invokers.enumerated()), id: \.0.self) { caller in
                                        HStack {
                                            Text(caller.element.key)
                                            Text("\(caller.element.value) times")
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.annotationBackground)
                            }
                            .accessibilityHidden(true)
                    }
                }.frame(
                    minWidth: s.opcode_freq.count < 30 ? CGFloat(175 * s.opcode_freq.count) : CGFloat(80 * s.opcode_freq.count),
                    maxWidth: .infinity, alignment: .center)
                //                .frame(maxWidth: .infinity, maxHeight: .infinity)
                //                .chartXVisibleDomain(length: 200)
                .chartOverlay { (chartProxy: ChartProxy) in
                    Color.clear
                        .onContinuousHover { hoverPhase in
                            switch hoverPhase {
                            case .active(let hoverLocation):
                                selected_opcode = chartProxy.value(
                                    atX: hoverLocation.x, as: String.self
                                )
                            case .ended:
                                selected_opcode = nil
                            }
                        }
                }
            }
        }).padding(3)
    }
}

extension Color {
    static var annotationBackground: Color {
#if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
#else
        return Color(uiColor: .secondarySystemBackground)
#endif
    }
}

struct CallTree : View {
    private var evm_execed = ExecutedOperations.shared
    @Environment(\.openURL) var openURL
    
    var body: some View {
        HStack {
            List(evm_execed.call_tree, children: \.Children) { item in
                HStack {
                    Image(systemName: item.icon)
                    Text(item.Kind)
                    HStack {
                        Text("FROM")
                        Button {
                            let s = "https://etherscan.com/address/\(item.Caller)"
                            guard let link = URL(string: s) else {
                                return
                            }
                            openURL(link)
                        } label: {
                            Text(item.Caller)
                        }
                    }
                    HStack {
                        Text("TO")
                        Button {
                            let s = "https://etherscan.com/address/\(item.Target)"
                            guard let link = URL(string: s) else {
                                return
                            }
                            openURL(link)
                        } label: {
                            Text(item.Target)
                        }
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

// TODO this isn't used atm
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
    var current_head : CurrentBlockHeader
    var db_backing  = LoadChainModel.shared
    
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

struct LoadContractFromInput: View {
    @State private var contract_name : String = ""
    @State private var contract_bytecode : String = ""
    @State private var contract_abi: String = ""
    @State private var deploy_to_address: String = ""
    @State private var picked_common_abi = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section ("Contract") {
                TextField("Name", text:$contract_name)
                Divider()
                TextField("Deploy To Address", text: $deploy_to_address)
                Section("Contract Bytecode") {
                    TextField("Hex Encoded", text: $contract_bytecode, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                }
                Divider()
                Section {
                    TextField("Optional JSON ABI",
                              text: picked_common_abi.isEmpty ? $contract_abi : .constant(CommonABIsModel.shared.abis_raw[picked_common_abi]!),
                              axis: .vertical)
                    .lineLimit(5, reservesSpace: true)
                    .scrollDisabled(false)
                } header: {
                    Picker("common ABIs", selection: $picked_common_abi) {
                        ForEach(Array(CommonABIsModel.shared.abis_raw.keys), id: \.self) {
                            Text($0)
                        }
                    }
                    
                } footer: {
                    Divider()
                }
            }
            HStack {
                Button { dismiss() } label: { Text("Cancel").padding(5).scaledToFit().frame(width: 120) }
                Button {
                    let already_have = LoadedContracts.shared.contracts.filter({$0.name == contract_name})
                    if already_have.count > 0 {
                        RuntimeError.shared.error_reason = "Already have contract loaded with name `\(contract_name)`"
                        RuntimeError.shared.show_error = true
                        dismiss()
                        return
                    }
                    if !picked_common_abi.isEmpty {
                        contract_abi = CommonABIsModel.shared.abis_raw[picked_common_abi]!
                    }
                    
                    let contract = LoadedContract(
                        name: contract_name,
                        bytecode: contract_bytecode,
                        address: deploy_to_address,
                        contract: contract_abi.count > 0 ? try? EthereumContract(contract_abi) : nil
                    )
                    LoadedContracts.shared.contracts.append(contract)
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
                    Text("Sample Contract")
                        .padding(5)
                        .scaledToFill()
                        .frame(width: 120)
                }
            }
        }
        .padding()
        .frame(width: 600, height: 450)
    }
}


struct KnownEIPs: View {
    @State var enable_all = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    private var evm_run_state = EVMRunStateControls.shared
    
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
    @State var item: StackItem
    
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
                                        Form {
                                            ForEach(Array(zip(element.inputs.indices, element.inputs)), id: \.1.name) {index, input in
                                                TextField(input.name, text: Binding<String>(
                                                    get: {
                                                        return fields[element.signature]![index]
                                                    },
                                                    set: {
                                                        fields[element.signature]![index] = $0
                                                    }
                                                )).help(input.type.abiRepresentation)
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
                            }
                        }.tabItem { Text("Decode") }.tag(0).padding()
                    }.frame(minHeight: 150)
                }
            }
        }
        .onAppear {
            if let contract = loaded_contract,
               let c = contract.contract {
                for i in c.allMethods {
                    fields[i.signature] = [String](repeating: "", count: i.inputs.count)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//#Preview("ABI encode table") {
//    
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: LoadedContract.self, configurations: config)
//
//    return ABIEncode(loaded_contract: sample_contract)
//        .frame(width: 700, height: 300)
//        .modelContainer(container)
//}

//#Preview("Load Contract from Chain") {
//    LoadContractFromChain(do_load: {_, _, _ in })
//}

struct LoadContractFromChain : View {
    let do_load: (String, String, String) -> Void
    @State private var contract_name = ""
    @State private var contract_addr = ""
    @State private var contract_abi = ""
    @State private var picked_common_abi = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Form {
                Section("Contract") {
                    TextField("Name", text: $contract_name)
                }
                Divider()
                Section("Address") {
                    TextField("0x...", text: $contract_addr)
                }
                Divider()
                Section {
                    TextField("Optional JSON ABI",
                              text: picked_common_abi.isEmpty ? $contract_abi : .constant(CommonABIsModel.shared.abis_raw[picked_common_abi]!),
                              axis: .vertical)
                    .lineLimit(5, reservesSpace: true)
                    .scrollDisabled(false)
                } header: {
                    Picker("common ABIs", selection: $picked_common_abi) {
                        ForEach(Array(CommonABIsModel.shared.abis_raw.keys), id: \.self) {
                            Text($0)
                        }
                    }
                } footer: {
                    Divider()
                }
                HStack {
                    Button { dismiss() } label : { Text("Cancel")
                            .padding(5)
                            .scaledToFill()
                            .frame(width: 120)
                    }
                    Button {
                        if !picked_common_abi.isEmpty {
                            contract_abi = CommonABIsModel.shared.abis_raw[picked_common_abi]!
                        }
                        do_load(contract_name, contract_addr, contract_abi)
                        dismiss()
                    } label: {
                        Text("Load")
                            .padding(5)
                            .scaledToFill()
                            .frame(width: 120)
                            .help("could take a second please wait")
                    }
                    Button {
                        contract_name = "uniswap quoter"
                        contract_addr = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6"
                        contract_abi = UNISWAP_QUOTER_ABI
                    } label: {
                        Text("uniswap quoter")
                            .padding(5)
                            .scaledToFill()
                            .frame(width: 120)
                    }
                }
            }.padding(2)
        }
        .padding()
        .frame(width: 600, height: 350)
    }
}


struct BreakpointView: View {
    @Bindable private var callbackmodel: OpcodeCallbackModel = OpcodeCallbackModel.shared
    @Bindable private var execed = ExecutedOperations.shared
    @State private var use_modified_values = false
    @State private var possible_signature_names : [String] = []
    @State private var selected : String?
    @State private var current_tab = 1
    @Environment(\.openURL) var openURL
    
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
                }
                // TODO Not sure about this since moving to @Observable
                //                .onReceive(EVMRunStateControls.shared.$contract_currently_running, perform: { current_running in
                //                    if !current_running {
                //                        possible_signature_names = []
                //                    }
                //                })
                .tabItem { Text("􀅮 Call").help("contract calls") }.tag(0)
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
                .tabItem{ Text("􀐞 Stack & Memory").help("live stack and memory") }.tag(1)
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
                }.tabItem{ Text("􁽇 Storage") }.tag(2)
                SideEVM(d:d).tabItem { Text("􀍿 Quick Side EVM") }.tag(3)
            })
        }
    }
}

struct SideEVM : View {
    let d : EVMDriver
    @State private var use_current_state = true
    @State private var target_addr = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    @Bindable private var side_evm_model = SideEVMResult.shared
    
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

//#Preview("side evm") {
//    SideEVM(d: StubEVMDriver()).frame(width: 600, height: 400)
//}
//
//#Preview("breakpoint view") {
//    BreakpointView(d : StubEVMDriver())
//}
//
//#Preview("Common ABIs") {
//    CommonABIs().frame(width: 600, height: 400)
//}

struct LookupTx: View {
    let d : EVMDriver
    @State private var tx_hash = ""
    var chaindb = LoadChainModel.shared
    @Bindable private var tx_lookup = TransactionLookupModel.shared
    func dev_mode () {
        tx_lookup.from_addr = "0x6f93428716dbc41bda6069fcca98ec105cb98168"
        tx_lookup.to_addr = "0x000000000dfde7deaf24138722987c9a6991e2d4"
        tx_hash = "0x8c520512305891b8164a3b6f326edfbb1152573a8487cb4845521f9b83136b87"
        tx_lookup.input_calldata = "0xc18a84bc0000000000000000000000006117fa34dcf2ee19af49cfca95e7e39bce136dde000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001243f3e37e4000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000553d694de05094000000000000000000000000000000000000000000000000000143dbde76ce5c12c0000000000000000000000000000000000000000000000000000000000000005000000000000000000000000a0246c9032bc3a600820415ae600c6388619a14d0000000000000000000000004ba657a5086dfa3698884d82a94564629885b7d60000000000000000000000001f573d6fb3f13d689ff844b4ce37794d79a7ff1c000000000000000000000000b1cd6e4153b2a390cf00a6556b0fc1458c4a5533000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000"
    }
    
    func clear() {
        tx_lookup.from_addr = ""
        tx_lookup.to_addr = ""
        tx_hash = ""
        tx_lookup.input_calldata = ""
    }
    
    var body: some View {
        VStack {
            if chaindb.is_chain_loaded {
                ScrollView {
                    Form {
                        Section("Transaction") {
                            TextField("Hash", text: $tx_hash)
                            Divider()
                            TextField("From Address", text: $tx_lookup.from_addr)
                            Divider()
                            TextField("To Address", text: $tx_lookup.to_addr)
                            Divider()
                            TextField("Calldata", text: $tx_lookup.input_calldata, axis: .vertical)
                                .lineLimit(5, reservesSpace: true)
                        }
                    }
                }
                .frame(maxHeight: 250)
                HStack {
                    Button {
                        d.lookup_tx_by_hash(hsh: tx_hash)
                    } label : {
                        Text("Lookup Hash")
                    }.frame(alignment: .bottomTrailing)
                    Button { clear() } label: { Text("Clear") }
                    Button {
                        dev_mode()
                    } label: { Text("Dev mode some MEV bot") }
                }
            } else {
                Text("Please load a blockchain database first")
            }
        }
        .padding(5)
        .frame(maxHeight:.infinity)
    }
}

//#Preview("Lookup Txs") {
//    LookupTx(d: StubEVMDriver()).frame(width: 600, height: 300)
//}

struct CommonABIs : View {
    private var abis = CommonABIsModel.shared
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
                    if let s = selected,
                       let element = abis.all_methods.first(where: {$0.signature == s}) {
                        VStack {
                            if element.inputs.count == 0 {
                                Spacer().frame(height: 1)
                            } else {
                                Form {
                                    ForEach(Array(zip(element.inputs.indices, element.inputs)), id: \.1.name) { index, input in
                                        TextField(input.name, text: Binding<String>(
                                            get: {
                                                return fields[element.signature]![index]
                                            },
                                            set: {
                                                fields[element.signature]![index] = $0
                                            }
                                        )).help(input.type.abiRepresentation)
                                    }
                                }.padding(10)
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
    @Bindable private var chain = LoadChainModel.shared
    
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
    var evm_run_state = EVMRunStateControls.shared
    @State var break_on_all = false
    @Environment(\.dismiss) var dismiss
    let d : EVMDriver
    
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
    @Bindable private var evm_run_controls = EVMRunStateControls.shared
    @Bindable private var call_params = EVMRunStateControls.shared.current_call_params
    var load_chain_model = LoadChainModel.shared
    @State private var present_opcode_select_sheet = false
    @Environment(\.dismiss) var dismiss
    @State private var keccak_input = ""
    @State private var keccak_output = ""
    @State private var use_head_state = true
    @State private var specific_state = ""
    
    var body: some View {
        VStack {
            HStack {
                TabView {
                    HStack {
                        Form {
                            Section("Input Parameters") {
                                TextField("Calldata", text: $call_params.calldata)
                                TextField("Value", text: $call_params.msg_value)
                                TextField("To Address", text: $target_addr)
                                TextField("Gas Price", text: $call_params.gas_price)
                                TextField("Gas Limit", text: $call_params.gas_limit)
                            }
                        }
                        Form {
                            //                            HStack {
                            //                                Button {
                            //                                    keccak_output = d.keccak256(input: $keccak_input.wrappedValue)
                            //                                } label: { Text("Keccak256") }
                            //                                TextField("input...", text: $keccak_input)
                            //                                TextField("output..", text: $keccak_output)
                            //                            }
                            Section("Sender Overrides") {
                                TextField("Sender Address", text: $call_params.caller_addr)
                                TextField("Sender ETH balance", text: $call_params.caller_eth_bal)
                            }
                            Section("Call Result") {
                                TextField("Return Value",
                                          text: $evm_run_controls.call_return_value)
                                .disabled(false)
                                .textSelection(.enabled)
                                TextField("EVM Error", text: $evm_run_controls.evm_error)
                            }
                        }
                    }
                    .padding(5)
                    .tabItem { Text("Fresh Run") }.tag(0)
                    VStack { Text("something")}.tabItem { Text("Run History") }.tag(1)
                    VStack { Text("Replay") }.tabItem { Text("Replay the Chain") }.tag(2)
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
                                Text("Run Contract")
                                    .frame(width: evm_run_controls.contract_currently_running ? 110 : 140, height: 25)
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
                    Button { d.cancel_running_evm() } label: { Text("Cancel EVM").frame(width: 140) }
                        .disabled(!evm_run_controls.contract_currently_running)
                        .frame(width: 160)
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
                        d.enable_opcode_call_callback(yes_no: false)
                        d.enable_step_each_op(yes_no: false)
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
                        Text("Break on CALL").frame(maxWidth: .infinity, alignment: .leading)
                    }).frame(alignment: .leading)
                    Toggle(isOn: Binding<Bool>(
                        get: { evm_run_controls.step_each_op },
                        set: {
                            d.enable_step_each_op(yes_no: $0)
                            evm_run_controls.step_each_op = $0
                        }
                    ), label: {
                        Text("Step each OPCODE").frame(maxWidth: .infinity, alignment: .leading)
                    })
                    Toggle(isOn: $use_head_state) {
                        HStack {
                            Text("Latest State")
                            TextField("custom block", text: $specific_state)
                                .disabled(use_head_state)
                        }
                    }
                }.frame(maxWidth: 185)
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


#Preview("Main App") {
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
        .modelContainer(for: [LoadedContract.self])
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
    @State var overrides: StateChanges
    
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
                        Form {
                            Section("Storage") {
                                TextField("Key", text: Binding<String>(
                                    get: { st.key },
                                    set: { st.key = $0 }
                                ), axis: .vertical).lineLimit(2, reservesSpace: true)
                                TextField("Original Value",
                                          text: .constant(st.original_value),
                                          axis: .vertical)
                                .textSelection(.enabled)
                                .lineLimit(3, reservesSpace: true)
                                TextField("Modified Value", text: Binding<String>(
                                    get: { st.new_value },
                                    set: { st.new_value = $0 }
                                ), axis: .vertical).lineLimit(3, reservesSpace: true)
                            }
                            Button {
                                driver.write_contract_state(addr: c.address, key: st.key, value: st.new_value)
                            } label: { Text("Save Modified Storage Value") }
                        }
                    } else {
                        Form {
                            Section("Storage Lookup") {
                                Button {
                                    driver.read_contract_state(addr: c.address, key: c.state_overrides.temp_key)
                                } label: {
                                    TextField("Key",
                                              text: $c.state_overrides.temp_key,
                                              axis: .vertical)
                                    .lineLimit(3, reservesSpace: true)
                                }
                                TextField("Value",
                                          text: Binding<String>(
                                            get: { c.state_overrides.temp_value },
                                            set: { c.state_overrides.temp_value = $0 }
                                          ), axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                            }
                            Divider()
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
                            } label : {
                                TextField("Save With Name", text: $new_item_lookup_name).foregroundStyle(.primary)
                            }.padding([.top], 15)
                        }.padding(5)
                    }
                }.frame(maxWidth: .infinity)
            }
        }
    }
}


#Preview("Edit State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LoadedContract.self, configurations: config)
    
    return EditState(driver: StubEVMDriver(),
                     c: .constant(sample_contract),
                     overrides: sample_contract.state_overrides)
    .modelContainer(container)
    .frame(width: 600, height: 300)
}

//#Preview("enabled EIPs") {
//    KnownEIPs(known_eips: .constant([
//        EIP(num: 1223, enabled: false),
//        EIP(num: 1559, enabled: true),
//        EIP(num: 44, enabled: false)])
//    )
//}

#Preview("Load Contract From Input") {
    LoadContractFromInput()
}

//#Preview("BlockContext") {
//    BlockContext(current_head: CurrentBlockHeader())
//}
