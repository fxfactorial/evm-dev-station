//
//  SwiftUIView.swift
//  
//
//  Created by Edgar Aroutiounian on 10/24/23.
//

import SwiftUI

struct BlockContext : View {
    @State fileprivate var coinbase: String = "0x..."
    
    var body : some View {
        VStack {
            TextField("Coinbase", text: $coinbase)
        }
    }
}

public struct EVMDevCenter: View {

    @State private var bytecode_add = false

    public init() {

    }

    public var body: some View {
        VStack {
            Text("Hello, Wormore")
            Text("hello evm dever!")
            Button {
                bytecode_add.toggle()
            } label: {
                Text("add contract bytecode")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $bytecode_add) {
            print("sheet dismissed")
        } content: {
            NewContractByteCode()
        }
    }
}

struct NewContractByteCode: View {
    @State private var contract_name = ""
    @State private var contract_bytecode = ""
    
    var body: some View {
        VStack {
            TextField("new contract name...", text:$contract_name)
            TextField("contract bytecode...", text: $contract_bytecode, axis: .vertical)
                .lineLimit(20, reservesSpace: true)
        }.padding()
        .frame(width: 500, height: 400)
    }
}

#Preview("dev center") {
        EVMDevCenter()
}

#Preview("New Contract bytecode") {
    NewContractByteCode()
}

#Preview("BlockContext") {
    BlockContext()
}
