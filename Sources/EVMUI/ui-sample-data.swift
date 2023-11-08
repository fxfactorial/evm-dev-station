import DevStationCommon
import SwiftUI

let sample_contract = LoadedContract(
    name: "local-compiled",
    bytecode: "6080604052600a5f55600c600155348015610018575f80fd5b506102d2806100265f395ff3fe608060405234801561000f575f80fd5b5060043610610034575f3560e01c8063d288a24c14610038578063f4bd333814610068575b5f80fd5b610052600480360381019061004d9190610151565b610098565b60405161005f919061018b565b60405180910390f35b610082600480360381019061007d91906101fe565b6100b2565b60405161008f919061018b565b60405180910390f35b5f805f54905082816100aa9190610269565b915050919050565b5f808390505f607b846100c59190610269565b90505f805490506100e081836100db9190610269565b6100f4565b9150815f8190555081935050505092915050565b5f80600a836101039190610269565b9050600a816101129190610269565b915050919050565b5f80fd5b5f819050919050565b6101308161011e565b811461013a575f80fd5b50565b5f8135905061014b81610127565b92915050565b5f602082840312156101665761016561011a565b5b5f6101738482850161013d565b91505092915050565b6101858161011e565b82525050565b5f60208201905061019e5f83018461017c565b92915050565b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f6101cd826101a4565b9050919050565b6101dd816101c3565b81146101e7575f80fd5b50565b5f813590506101f8816101d4565b92915050565b5f80604083850312156102145761021361011a565b5b5f610221858286016101ea565b92505060206102328582860161013d565b9150509250929050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f6102738261011e565b915061027e8361011e565b92508282019050808211156102965761029561023c565b5b9291505056fea264697066735822122038b985afa9e86ee51579bce03667914174c1d7d37912bb27ed15097a0ef79b7664736f6c63430008160033",
    address: "",
    contract: try? EthereumContract(sample_contract_abi)
)


let sample_contract_abi = """
[
  {
    "inputs": [
      { "internalType": "address", "name": "sender", "type": "address" },
      { "internalType": "uint256", "name": "amount", "type": "uint256" }
    ],
    "name": "entry_point",
    "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "input_amount", "type": "uint256" }
    ],
    "name": "storage_checking",
    "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]

"""


let items = [
    File(name: "Documents", children: [
        File(name: "Work", children: [
            File(name: "Revision 1.doc", children: nil),
            File(name: "Revision 2.doc", children: nil),
        ]),
        File(name: "Sheet 1.pdf", children: nil),
        File(name: "Sheet 2.pdf", children: nil)
    ]),
    File(name: "Photos", children: [
        File(name: "Photo 1.jpg", children: nil),
        File(name: "Photo 2.jpg", children: nil)
    ]),
    File(name: "Empty folder", children: []),
    File(name: "sys.info", children: nil)
]
