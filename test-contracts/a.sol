// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.9.0;

import "./ierc20.sol";

interface Quoter {
  function quoteExactInputSingle(
    address,
    address,
    uint24,
    uint256,
    uint160
  ) external view returns (uint256);
}

contract EntryPoint {
  uint256 simple_storage_one = 22;
  uint256 simple_storage_two = 1;
  mapping(address => uint256) items;

  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  Quoter constant V3Quoter = Quoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

  function check_my_balance() external view returns (uint256) {
    return IERC20(USDC).balanceOf(address(this));
  }

  function do_quote() external view returns (uint256) {
    uint256 how_much_out = V3Quoter.quoteExactInputSingle(
      WETH,
      USDC,
      3000,
      2000000000000000000,
      0
    );
    return how_much_out;
  }

  function entry_point(
    address sender,
    uint256 amount
  ) external returns (uint256) {
    address otherwise_copied = sender;
    address copied = sender;
    address more_copied = copied;
    address amt_bigger3 = sender;
    uint256 amt_bigger = amount + 123;
    uint256 handle = simple_storage_one;
    amt_bigger = internal_work(amt_bigger + handle);
    simple_storage_one = amt_bigger;
    return amt_bigger;
  }

  function storage_checking(uint256 input_amount) external returns (uint256) {
    uint256 copied_from_storage1 = simple_storage_one;
    return copied_from_storage1 + input_amount;
  }

  function internal_work(uint256 more_work) internal pure returns (uint256) {
    uint256 force_it = more_work + 10;
    return force_it + 10;
  }

  function do_work_no_parameters()
    external
    view
    returns (uint256, uint256, uint256)
  {
    uint256 copy_1 = simple_storage_one;
    uint256 copy_2 = simple_storage_two;
    return (copy_1 + copy_2, copy_1, copy_2);
  }

  function simple_handler(address has) external returns (uint256) {
    items[has] = 123;

    uint256 added = 123;
    return 456;
  }

  function check_require() external view {
    require(10 > 2, "ooops");
  }

  function more_Deploy() external view {
    //
  }
}
