//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "hardhat/console.sol";

contract REXSuperSwap {
    address private sushiV2Factory;

    constructor(address sushiFactory) {
        // sushiv2Factory - 0xc35DADB65012eC5796536bD9864eD8773aBc74C4
        sushiV2Factory = sushiFactory;
    }

    function _performApprovals(
        ISuperToken _from,
        ISuperToken _to,
        IERC20 fromBase,
        IERC20 toBase,
        IUniswapV2Router02 pair
    ) private {
        if (_from.allowance(address(this), address(pair)) == 0) {
            _from.approve(address(pair), 2**256 - 1);
        }

        if (_to.allowance(address(this), address(pair)) == 0) {
            _to.approve(address(pair), 2**256 - 1);
        }

        if (fromBase.allowance(address(this), address(_from)) == 0) {
            fromBase.approve(address(_from), 2**256 - 1);
        }

        if (toBase.allowance(address(this), address(_to)) == 0) {
            toBase.approve(address(_to), 2**256 - 1);
        }
    }

    // TODO: - Builds a path for swap with each pair existing and having liquidity
    function _buildPath() private {}

    function swap(
        ISuperToken _from,
        ISuperToken _to,
        uint256 amountIn,
        uint256 amountOutMin
    ) public payable {
        require(amountIn > 0, "Amount cannot be 0");

        // Step 1: Transfer
        bool success = _from.transferFrom(msg.sender, address(this), amountIn);
        require(success, "Transfer to contract failed");

        // Step 2: Downgrade
        _from.downgrade(amountIn);

        // Step 3: Get underlying tokens and Sushi pair contract
        IERC20 fromBase = IERC20(_from.getUnderlyingToken());
        IERC20 toBase = IERC20(_to.getUnderlyingToken());

        IUniswapV2Router02 pair = IUniswapV2Router02(
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                sushiV2Factory,
                                keccak256(
                                    abi.encodePacked(
                                        address(fromBase),
                                        address(toBase)
                                    )
                                ),
                                hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                            )
                        )
                    )
                )
            )
        );

        // Step 4: Approve and swap
        _performApprovals(_from, _to, fromBase, toBase, pair);
        address[] memory path = new address[](2);
        path[0] = address(fromBase);
        path[1] = address(toBase);
        uint256[] memory swapAmounts;
        swapAmounts = pair.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 300
        );

        // Step 5: Upgrade and send tokens back
        uint256 outAmount = swapAmounts[swapAmounts.length - 1];
        _to.upgrade(outAmount);
        _to.approve(msg.sender, outAmount);
        _to.transfer(msg.sender, outAmount);
    }
}

// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-01#swaptokensforexacttokens
