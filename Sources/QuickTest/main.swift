import Foundation
import EVMBridge
import DevStationCommon
import BigInt

// just to make it link 
@_cdecl("evm_run_callback")
public func evm_run_callback(
  num: Int32,
  opcode_name: UnsafeMutablePointer<CChar>,
  opcode_hex: UnsafeMutablePointer<CChar>,
  gas_cost: Int
) {

}


let name = "router"

EVMBridge.AddABI(GoInt(0), UNISWAP_ROUTER_ABI.to_go_string2())
let methods_result = EVMBridge.MethodsForABI(GoInt(0))
// print("pulled out \(methods_result.r1)")

var method_names = [String]()
let buffer = UnsafeBufferPointer(start: methods_result.r0, count: Int(methods_result.r1))

let wrapped = Array(buffer)
// print("total count is \(wrapped.count)")

for i in wrapped {
    let method = String(cString: i!)
    free(i!)
    method_names.append(method)
    // print("pulled out! \(method)")
}

free(methods_result.r0)

for i in method_names {
    // print("pulled out -> \(i)")
}


let jsonData = UNISWAP_ROUTER_ABI.data(using: .utf8)
// let abi = try JSONDecoder().decode([ABI.Record].self, from: jsonData!)
let contract = try EthereumContract(UNISWAP_ROUTER_ABI)
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

print("sending over", collect)
for i in collect {
    EVMBridge.TestSendingInt(i.test_4())
}
