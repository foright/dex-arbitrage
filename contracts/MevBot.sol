//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import '../library/TransferHelper.sol';
import '../library/SafeMath.sol';
import '../interfaces/IUniv3.sol';
import '../interfaces/IUniv2.sol';

struct Params {
    uint256 borrowAmount;
    uint256 feeAmount;
    address borrowToken;
    address[] pools;
    uint16[] fees;
    uint16[] orders;
    uint16[] dexes;
}
struct FlashCall {
    Params params;
    uint256[] amountOuts;
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
contract MevBot is Ownabled,IUniswapV3SwapCallback{
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    uint160  constant MIN_SQRT_RATIO = 4295128740;
    uint160  constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970341;
    address constant withdrawadd = 0xAFFcAA1B4CC981B7849bD936C256E6c6e193b117;

    bytes4 internal constant RES = 0x0902f1ac;

    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address private IQUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    ChiToken public constant chi = ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    fallback() external payable {
        (address sender, uint256 amount0, uint256 amount1, bytes memory data) = abi.decode(
            msg.data[4:],
            (address, uint256, uint256, bytes)
        );
        uniswapV2Call(sender, amount0, amount1, data);
    }

    modifier discountCHI() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }
    constructor() {}

    function arb(Params memory params) external discountCHI{
        uint256 amountOut = params.borrowAmount;
        uint len = params.pools.length;
        uint256[] memory amountOuts = new uint256[](len);
        for (uint8 i = 0; i < len; i++) {
            if (params.dexes[i] == 0){
                amountOut = getAmountOut(params.pools[i],params.orders[i],amountOut,params.fees[i]);
            }else{
                amountOut = getAmountOutV3(params.pools[i],params.orders[i],amountOut,params.fees[i]);
            }
            amountOuts[i] = amountOut;
        }
        require(amountOut > params.borrowAmount.add(params.feeAmount), 'FBV1:ABC');
        {
            FlashCall memory fb = FlashCall({params:params,amountOuts:amountOuts});
            delete amountOuts;

            if (params.dexes[0] == 0){
                flash(fb);
            }else{
                flashV3(fb);
            }
        }
        uint256 profit = amountOut.sub(params.borrowAmount);
        if (profit > 0) {
            TransferHelper.trans(params.borrowToken, withdrawadd, profit);
        }
    } 
    
    function excute(bytes calldata data) public{
        FlashCall memory fb = abi.decode(data,(FlashCall));
        address[] memory pools = fb.params.pools;
        for (uint8 i = 1; i < pools.length; i++) {
            if (fb.params.dexes[i] == 0){
                address token0 = IUniswapV2Pair(fb.params.pools[i-1]).token0();
                address token1 = IUniswapV2Pair(fb.params.pools[i-1]).token1();
                address out = fb.params.orders[i-1] == uint8(0) ? token0 : token1;
                TransferHelper.trans(out, fb.params.pools[i], fb.amountOuts[i-1]);
            
                swap(pools[i],fb.params.fees[i],fb.params.orders[i],fb.amountOuts[i],address(this));
            }else{
                swapV3(pools[i],fb.params.fees[i],fb.params.orders[i],fb.amountOuts[i],address(this));
            }
        }
        TransferHelper.trans(fb.params.borrowToken, pools[0], fb.params.borrowAmount);
        
    }
    
    function flash(FlashCall memory fb) private  {
        (uint256 amount0Out,uint256 amount1Out) = fb.params.orders[0] == 0 ? (fb.amountOuts[0], uint256(0)) : (uint256(0), fb.amountOuts[0]);
        IUniswapV2Pair(fb.params.pools[0]).swap(amount0Out, amount1Out, address(this), abi.encode(fb));
    }

    function swap(address pool,uint16 fee,uint16 order,uint256 amount0,address to) private  returns (uint256 amount){
        (uint256 amountOut0,uint256 amountOut1) = order == 0 ? (amount0, uint256(0)) : (uint256(0), amount0);
        IUniswapV2Pair(pool).swap(amountOut0, amountOut1, to, new bytes(0));
    }

    function getAmountOut(address pool, uint16 order, uint256 amountIn, uint16 fee) public view returns (uint256 amount0){
            uint112 reserves0;
            uint112 reserves1;
            assembly {
                let x := mload(0x40)
                mstore(0x40, add(x, 32))
                mstore(x, RES)
                let s := staticcall(5000, pool, x, 4, x, 96)
                if lt(returndatasize(), 96) {
                    revert(0, 0)
                }
                reserves0 := mload(x)
                reserves1 := mload(add(x, 32))
            }
            (reserves0, reserves1) = order == 0 ? (reserves1, reserves0) : (reserves0, reserves1);
            amount0 = _getAmountOut(amountIn, fee, reserves0, reserves1);
    }
    function _getAmountOut(uint256 amountIn,uint16 fee,uint256 reserveIn,uint256 reserveOut ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'FBV1: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'FBV1: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(uint256(fee));
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    } 

    function uniswapV2Call(address sender,uint256 amount0,uint256 amount1,bytes memory data) public {
        require(sender == address(this), 'FBV1: SA');
        (bool success,) = address(this).call(abi.encodeWithSignature("excute(bytes)", data));
        require(success,"FBV1:UC");
    }
    
    function flashV3(FlashCall memory fb) private {
        IUniswapV3Pool borrowpool = IUniswapV3Pool(fb.params.pools[0]);
        address token0 = borrowpool.token0();
        address token1 = borrowpool.token1(); 
        (address inputToken, address outputToken) = fb.params.orders[0] == 1 ? (token0, token1) : (token1, token0);
        
        bool zeroForOne =inputToken < outputToken;
        uint160 sqrtX96 = zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO;
       
        borrowpool.swap(address(this), zeroForOne, int256(fb.params.borrowAmount), sqrtX96, abi.encode(fb));
    }

    function swapV3(address pool,uint16 fee,uint16 out,uint256 amount0,address to) private  returns (uint256 amount) {
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        (address inputToken, address outputToken) = out == 1 ? (token0, token1) : (token1, token0);

        TransferHelper.tokenApprove(inputToken, address(swapRouter), MAX_SQRT_RATIO);
       uint160 sqrtX96 = inputToken<outputToken ? MIN_SQRT_RATIO : MAX_SQRT_RATIO;
        amount = swapRouter.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: inputToken,
                tokenOut: outputToken,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 120,
                amountOut: amount0,
                amountInMaximum: MAX_SQRT_RATIO,
                sqrtPriceLimitX96: sqrtX96
            })
        );
    }
    
    function uniswapV3SwapCallback(int256 amount0Delta,int256 amount1Delta,bytes calldata data) external override {
       (bool success,) = address(this).call(abi.encodeWithSignature("excute(bytes)", data));
       require(success,"FBV1:UC");
    }

    function getAmountOutV3(address pool, uint16 order,uint256 amountIn,uint16 fee) public returns(uint256 amount){
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        (address inToken, address outToken) = order == uint16(0) ? (token1,token0) : (token0,token1);
        uint160 sqrtX96 = inToken<outToken ? MIN_SQRT_RATIO : MAX_SQRT_RATIO;
        amount = IQuoter(IQUOTER).quoteExactInputSingle(inToken, outToken,fee,amountIn,sqrtX96);
    }
}
