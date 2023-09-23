import { ethers } from "hardhat";
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", ethers.provider)
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
      "Deploying the contracts with the account:",
      await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const accounts = await ethers.getSigners();
  //console.log(accounts[0])

  console.log("Wallet Ethereum Address:", wallet.address);

  //deploy DealStatus
  const Cid = await ethers.getContractFactory('Cid', accounts[0]);
  console.log('Deploying Cid...');
  const cid = await Cid.deploy();
  await cid.deployed()
  console.log('Cid deployed to:', cid.address);

  //deploy DealStatus
  const Proof = await ethers.getContractFactory('Proof', {
      libraries: {
          Cid: cid.address,
      },
  });
  console.log('Deploying Proof...');
  const proof = await Proof.deploy();
  await proof.deployed()
  console.log('Proof deployed to:', proof.address);

  //deploy DealStatus
  const Daopia = await ethers.getContractFactory('Daopia', {
      libraries: {
          Cid: cid.address,
      },
  });
  console.log('Deploying Daopia...');
  const daopia = await Daopia.deploy();
  await daopia.deployed();
  console.log('Daopia deployed to:', daopia.address);
  console.log("Deal status address is : ", await daopia.dealStatus());
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
