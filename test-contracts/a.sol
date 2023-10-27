pragma solidity >=0.4.0 <0.9.0;

contract EntryPoint {
    function entry_point(address sender, uint256 amount) external returns (uint256){
	address otherwise_copied = sender;
	uint256 amt_bigger = amount + 123;
	amt_bigger = internal_work(amt_bigger);
	return amt_bigger;
    }

    function internal_work(uint256 more_work) internal returns (uint256) {
	uint256 force_it = more_work + 10;
	return force_it + 10;
    }
}
