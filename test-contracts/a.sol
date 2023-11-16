pragma solidity >=0.4.0 <0.9.0;

contract EntryPoint {
  uint256 simple_storage_one = 10;
  uint256 simple_storage_two = 12;
  mapping(address => uint256) items;

  function entry_point(
    address sender,
    uint256 amount
  ) external returns (uint256) {
    address otherwise_copied = sender;
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
