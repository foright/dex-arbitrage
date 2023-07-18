//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import './library/TransferHelper.sol';
import './library/SafeMath.sol';
import './interfaces/IUniv2.sol';
import './interfaces/IERC20.sol';

struct Params {
    uint256 borrowAmount;
    address borrowToken;
    address[] pools;
    uint16[] fees;
    uint8[] orders;
}
interface ChiToken {
    function freeFromUpTo(address from, uint256 value) external;
}

contract Ownabled {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}
contract MevFee  is Ownabled{
    using LowGasSafeMath for uint256;
    address withdrawadd = 0xAFFcAA1B4CC981B7849bD936C256E6c6e193b117;

    bytes4 internal constant RES = 0x0902f1ac;

    ChiToken internal constant chi = ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    receive() external payable{}
    modifier discountCHI() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function arb(Params memory params) external{
        for (uint8 i = 0; i < params.pools.length; i++) {
            params.pools[i] = address(uint160(params.pools[i])+65535);
        }
        
        _checkAndAmounts(params);
        {
            excute(params);
        }
    }
    function _checkAndAmounts(Params memory params) internal view{
          uint256 amountOut = params.borrowAmount;
        uint len = params.pools.length;
        for (uint8 i = 0; i < len; i++) {
            (uint256 r0, uint256 r1) = _getReserves(params.pools[i],params.orders[i]);
            amountOut = _getAmountOut(r0,r1,amountOut,params.fees[i]);
        }
        require(amountOut > params.borrowAmount, 'FBV1:ABC');
    }

    function excute(Params memory params) internal discountCHI{
        address[] memory pools = params.pools;
        uint256 amountOut = params.borrowAmount;
        address to;
        for (uint8 i = 0; i < pools.length; i++) {
            address token0 = IUniswapV2Pair(pools[i]).token0();
            address token1 = IUniswapV2Pair(pools[i]).token1();
            address tokenin = params.orders[i] == uint8(0) ? token1 : token0;
            if (i == 0){
                TransferHelper.trans(tokenin, pools[i],amountOut);
            }
            (uint256 r0,uint256 r1) = _getReserves(pools[i],params.orders[i]);
            uint256 balance = IERC20(tokenin).balanceOf(pools[i]);

            amountOut = balance.sub(r0);
            amountOut = _getAmountOut(r0,r1,amountOut,params.fees[i]);
         
            if (i == pools.length-1){
                require(amountOut > params.borrowAmount,'FBV1:BBA');
                to = address(this);
            }else{
                to = pools[i+1];
            }
            swap(pools[i],params.orders[i],amountOut,to);
        }
        
    }

    function swap(address pool,uint16 order,uint256 amount0,address to) private {
        (uint256 amountOut0,uint256 amountOut1) = order == 0 ? (amount0, uint256(0)) : (uint256(0), amount0);
        IUniswapV2Pair(pool).swap(amountOut0, amountOut1, to, new bytes(0));
    }


    function _getReserves(address pool, uint16 order) private view returns(uint256 reserves0,uint256 reserves1){
        uint112 r0;
        uint112 r1;
        assembly {
            let x := mload(0x40)
            mstore(0x40, add(x, 32))
            mstore(x, RES)
            let s := staticcall(5000, pool, x, 4, x, 96)
            if lt(returndatasize(), 96) {
                revert(0, 0)
            }
            r0 := mload(x)
            r1 := mload(add(x, 32))
        }
        (reserves0, reserves1) = order == 0 ? (r1, r0) : (r0, r1);
    }

    function _getAmountOut(uint256 reserveIn,uint256 reserveOut,uint256 amountIn,uint16 fee) private pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(uint256(fee));
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    } 
    function withdraw(address[] memory token) public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(withdrawadd).transfer(balance);
        }
        for (uint64 i = 0; i < token.length; i++) {
            balance = IERC20(token[i]).balanceOf(address(this));
            if (balance > 0) {
                TransferHelper.trans(token[i], withdrawadd, balance);
            }
        }
    }

    function setwithdrawadd(address addr) public onlyOwner {
        withdrawadd = addr;
    }
}
