import { ethers, run  } from 'hardhat';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

let signer: SignerWithAddress;
async function main() {
  await run('compile');

  [signer] = await ethers.getSigners();

  const FlashBot12 = await ethers.getContractFactory('MevFee',signer);

  const flashBot12 = await FlashBot12.deploy();

  await flashBot12.deployed();

  console.log(`FlashBot deployed to MevBsc ${flashBot12.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
