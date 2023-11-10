import Foundation
import EVMBridge
import DevStationCommon
import BigInt
import AsyncAlgorithms



// just to make it link 
@_cdecl("evm_run_callback")
public func evm_run_callback(
  num: Int32,
  opcode_name: UnsafeMutablePointer<CChar>,
  opcode_hex: UnsafeMutablePointer<CChar>,
  gas_cost: Int
) {

}

@_cdecl("evm_opcall_callback")
public func evm_opcall_callback(
    caller_: UnsafeMutablePointer<CChar>,
    callee_: UnsafeMutablePointer<CChar>,
    args_: UnsafeMutablePointer<CChar>
) {

}

let name = "router"

// EVMBridge.AddABI(GoInt(0), UNISWAP_QUOTER_ABI.to_go_string2())
// let methods_result = EVMBridge.MethodsForABI(GoInt(0))
// print("pulled out \(methods_result.r1)")

// var method_names = [String]()
// let buffer = UnsafeBufferPointer(start: methods_result.r0, count: Int(methods_result.r1))

// let wrapped = Array(buffer)
// print("total count is \(wrapped.count)")

// for i in wrapped {
//     let method = String(cString: i!)
//     free(i!)
//     method_names.append(method)
//     // print("pulled out! \(method)")
// }

// free(methods_result.r0)

// for i in method_names {
//     // print("pulled out -> \(i)")
// }


let jsonData = UNISWAP_QUOTER_ABI.data(using: .utf8)
// let abi = try JSONDecoder().decode([ABI.Record].self, from: jsonData!)
let contract = try! EthereumContract(UNISWAP_QUOTER_ABI)
let weth = EthereumAddress("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")!
let usdc = EthereumAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")!
let fee_tier = BigUInt(3000)
let amount_out = BigUInt.init("1", .ether)
let sqrt_param = BigUInt(0)

// let contract = EthereumContract(abi: abi)
// print(contract, usdc, weth)
let encoded = contract.method(
  "quoteExactInputSingle",
  parameters: [
    weth, usdc, fee_tier, amount_out!, sqrt_param
  ],
  extraData: nil
)

let should_be = "f7729d43000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000000000bb80000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000000000000000000".lowercased()

let as_hex = encoded!.toHexString().lowercased()

let ui_made = "f7729d43000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000000000bb80000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000000000000000000"

// print("from swift abi", as_hex, "\nfrom geth abi", should_be, "\n are same? ",should_be == as_hex, "did the UI do it right", ui_made == should_be)
// let abi_native = try abi.map({ record -> ABI.Element in return try record.parse() })
// let funcs = try! abi_native.getFunctions()
// print(funcs)

// let msg = "00000000".toHexEncodedString()
// let msg_value = msg.to_go_string2()
// let len_count = EVMBridge.TestReceiveGoString(msg_value)
// print("was the size the same?", msg.count, "received", len_count, "as hex", msg)

let num_1 = "0000000"
let num_2 = "2000000000123123"
let num_3 = "999129213123123123123"
let collect = [num_1, num_2, num_3]

// print("sending over", collect)
// for i in collect {
//     EVMBridge.TestSendingInt(i.test_4())
// }


let payload = "128acb08000000000000000000000000b27308f9f90d607463bb33ea1bebb41c27ce5ab600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000fffd8963efd1fc6a506488495d951d5263988d2500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000002bc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000bb8a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000"

let sig = "swap(address,bool,int256,uint160,bytes)"
// actually does work on payload if you remove the first four bytes of payload
let result = ABIDecoder.decode(types: [
                                 .address, .bool, .int(bits:256), .uint(bits:160), .dynamicBytes,
                               ],
                               data: Data(hex: payload[8...]))

// print(result)

let result2 = try? ABITypeParser.parseTypeString(sig)
// print(result2)


let time_stamp =  "0x653aa2ef"
  // guard let timestampInt = UInt(stripedHexString, radix: 16) else { return nil }
  //   149         self = Date(timeIntervalSince1970: TimeInterval(timestampInt))
// let ts = Data(hex: time_stamp).withUnsafeBytes({ $0.load(as: UInt64.self)})
// let date = Date(timeIntervalSince1970: TimeInterval(ts))
// print(date)

let result3 = UInt(time_stamp[2...], radix: 16)!
let ts = Date(timeIntervalSince1970: TimeInterval(result3))
// print(result3, ts)



// func long_time() async -> String? {
//     var start_with = 0
//     return await { () async -> String in
//         try? await Task.sleep(for: .seconds(2))
//         start_with += 1
//         return "\(start_with) \(Date.now)"
//     }()
// }


// let channel = AsyncChannel<String>()

// Task {
//   while let result = await long_time() {
//     await channel.send(result)
//   }

//   channel.finish()
// }

// for await calculationResult in channel {
//   print(calculationResult)
// }

let comm_channel = AsyncChannel<Data>()

Task.detached {
    EVMBridge.MakeChannelAndListenThread(true.to_go_bool())
    EVMBridge.MakeChannelAndReplyThread(true.to_go_bool())

    for await msg in comm_channel {
        String(data: msg, encoding: .utf8)!.withCString {
            $0.withMemoryRebound(to: CChar.self, capacity: msg.count) {
                EVMBridge.UISendCmd(GoString(p: $0, n: msg.count))
            }
        }
    }
}


let msg1 = try! JSONEncoder().encode(EVMBridgeMessage<Int>(c: .CMD_NEW_EVM, p: 0))

await comm_channel.send(msg1)

let db_kind_pebble = "pebble"
let db_kind_leveldb = "leveldb"
let pathdir_pebble = "/Users/edgararoutiounian/repos/mainnet-chaindata/"
let pathdir_leveldb = "/Volumes/photos-media-backup/eth-mainnet-backup-11-07-23/chaindata"

let db_kind = db_kind_leveldb
let pathdir = pathdir_leveldb

let msg2 = try! JSONEncoder().encode(
  EVMBridgeMessage(c: .CMD_LOAD_CHAIN,
                   p: BridgeCmdLoadChain(kind: db_kind, directory: pathdir))
)
await comm_channel.send(msg2)

// quoter
let target_addr = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6"
// quote encoded
let calldata = "f7729d43000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000000000bb80000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000000000000000000"

let msg3 = try! JSONEncoder().encode(
  EVMBridgeMessage(
    c: .CMD_RUN_CONTRACT, p: BridgeCmdRunContract(calldata, target_addr, "0")
  )
)
await comm_channel.send(msg3)


try await Task.sleep(for: .seconds(40))

@_cdecl("send_cmd_back")
public func send_cmd_back(reply: UnsafeMutablePointer<CChar>) {
    let rpy = String(cString: reply)
    free(reply)
    let decoded = try! JSONDecoder().decode(EVMBridgeMessage<AnyDecodable>.self, from: rpy.data(using: .utf8)!)
    switch decoded.Cmd {
    case .CMD_RUN_CONTRACT:
        let call_result = decoded.Payload!.value as! Dictionary<String, AnyDecodable>
        let tree = call_result["CallTreeJSON"]?.value as! CallEvaled
        let other = call_result["State"]?.value as! [StateRecord]
        print("HERE",other)

//        print(tree)


    default:
        print("SWIFT RECEIVE", decoded)
    }
    // Task {
    //     await channel.send(rpy)
    // }
}

@_cdecl("send_error_back")
public func send_error_back(reply: UnsafeMutablePointer<CChar>) {
    let rpy = String(cString: reply)
    free(reply)
    print("ERROR ", rpy)
}
