pragma solidity >=0.4.0 <0.9.0;


contract EntryPoint {

    uint256 simple_storage_one = 10;
    uint256 simple_storage_two = 12;

    function entry_point(address sender, uint256 amount) external returns (uint256){
	address otherwise_copied = sender;
	uint256 amt_bigger = amount + 123;
	uint256 handle = simple_storage_one;
	amt_bigger = internal_work(amt_bigger + handle);
	simple_storage_one = amt_bigger;
	return amt_bigger;
    }

    function storage_checking(uint256 input_amount, bool use_first) external returns (uint256) {
	uint256 copied_from_storage1 = simple_storage_one;
	uint256 copied_from_storage2 = simple_storage_two;
	return input_amount + copied_from_storage1;
    }
    
    function internal_work(uint256 more_work) internal pure returns (uint256) {
	uint256 force_it = more_work + 10;
	return force_it + 10;
    }
}
