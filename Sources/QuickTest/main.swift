import Foundation
import EVMBridge
import DevStationCommon

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
print("pulled out \(methods_result.r1)")

var method_names = [String]()
let buffer = UnsafeBufferPointer(start: methods_result.r0, count: Int(methods_result.r1))

let wrapped = Array(buffer)
print("total count is \(wrapped.count)")

for i in wrapped {
    let method = String(cString: i!)
    free(i!)
    method_names.append(method)
    // print("pulled out! \(method)")
}

free(methods_result.r0)

for i in method_names {
    print("pulled out -> \(i)")
}
