
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from '@ethersproject/bignumber';
import { ethers, waffle } from 'hardhat';
import { FlashBot } from '../typechain/FlashBot';
import { getArbParams } from '../arb/api';
import { arbParam } from '../arb';
import config from '../config';

describe('Flash-arb', () => {
  let flashBot: FlashBot;

  let token0: string;
  let token1: string;
  let token2: string;
  let signer: SignerWithAddress;
  let flashAddr: string;
  let params: arbParam[];
  let amountInt: BigNumber;

  beforeEach(async () => {

    flashAddr = config.contractAddr;
    flashBot = (await ethers.getContractAt("FlashBot", flashAddr, signer)) as FlashBot;
    token0 = "0x2674AAf32fD5bFa62Ad62143CBF1e239bFe26D92";
    token1 = "0xe5f43218B4Cb92Ceb46EA21320DC02DA7815446B";
    token2 = "0xf479bD71aA06FC63BB06c905f758bba31dcf4fEd";
    params = await getArbParams();
    amountInt = ethers.utils.parseEther('1');

  });

  describe('flash arbitrage', () => {
    const uniFactoryAddr = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
    const uniRouteAddrv2 = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
    const uniFactoryAbi = ['function getPair(address, address) view returns (address pair)'];
    const uniPair = new ethers.Contract(uniFactoryAddr, uniFactoryAbi, waffle.provider);



    it('swap univ2 token0', async () => {
      const IERCToken0 = await ethers.getContractAt("ERC20Mock", token0);
      const pair = await uniPair.getPair(token0, token1);
      const IUniswapV2Pair = await ethers.getContractAt("IUniswapV2Pair", pair);
      const IUniswapV2Router01 = await ethers.getContractAt("IUniswapV2Router02", uniRouteAddrv2);

      await IERCToken0.transfer(pair, amountInt);

      const reserves = await IUniswapV2Pair.getReserves();
      const amountOut = await IUniswapV2Router01.getAmountOut(amountInt, reserves.reserve0, reserves.reserve1);
      const buf = Buffer.alloc(0)
      const result = await IUniswapV2Pair.swap(0, amountOut, "0xf506414dEb5b578c85d273E94E98FCcF6812d202", buf);

      await result.wait();
    });
    it('swap univ2 token1', async () => {
      const IERCToken0 = await ethers.getContractAt("ERC20Mock", token1);
      const pair = await uniPair.getPair(token1, token2);
      const IUniswapV2Pair = await ethers.getContractAt("IUniswapV2Pair", pair);
      const IUniswapV2Router01 = await ethers.getContractAt("IUniswapV2Router02", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");

      await IERCToken0.transfer(pair, amountInt);

      const reserves = await IUniswapV2Pair.getReserves();
      const amountOut = await IUniswapV2Router01.getAmountOut(amountInt, reserves.reserve0, reserves.reserve1);
      console.log(amountOut);
      const buf = Buffer.alloc(0)
      const result = await IUniswapV2Pair.swap(0, amountOut, "0xf506414dEb5b578c85d273E94E98FCcF6812d202", buf);

      await result.wait();
    });
    it('swap univ2 token2', async () => {
      const IERCToken0 = await ethers.getContractAt("ERC20Mock", token2);
      const pair = await uniPair.getPair(token2, token0);
      const IUniswapV2Pair = await ethers.getContractAt("IUniswapV2Pair", pair);
      const IUniswapV2Router01 = await ethers.getContractAt("IUniswapV2Router01", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");

      await IERCToken0.transfer(pair, amountInt);

      const reserves = await IUniswapV2Pair.getReserves();
      const amountOut = await IUniswapV2Router01.getAmountOut(amountInt, reserves.reserve0, reserves.reserve1);
      const buf = Buffer.alloc(0)
      const result = await IUniswapV2Pair.swap(0, amountOut, "0xf506414dEb5b578c85d273E94E98FCcF6812d202", buf);

      await result.wait();
    });
    it('check has profit', async () => {
      const IUniswapV2Router01 = await ethers.getContractAt("IUniswapV2Router01", uniRouteAddrv2);

      const amountInt = params[0]['borrowAmount'];
      const outs = params[0]['outs']

      const amountOut3 = await IUniswapV2Router01.getAmountsOut(amountInt, [params[0]['borrowToken'], outs[0], outs[1], outs[2]]);
      console.log(amountOut3);
    });

    it('swap univ2 contract', async () => {
      const IERCToken0 = await ethers.getContractAt("ERC20Mock", token0);
      const pair = await uniPair.getPair(token0, token1);
      await IERCToken0.transfer(pair, amountInt);

      const amount = await flashBot.swapUniV2(pair, token1, amountInt);

      await amount.wait();

    });

    it('flash uni v2', async () => {
      const arb = (await flashBot.arb(params[0]));
      const result = await arb.wait();
      console.log(result);
    });
  });
});

