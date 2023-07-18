// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.2;

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);

    function token1() external view returns (address);
}
