import { ethers } from "hardhat";
import { Database } from "@tableland/sdk";

async function testDb(account:any){
    const tableName = "daopia"+"_31337_1"
    const db = new Database({autoWait: false,signer: account});
 
    const { results } = await db.prepare(`SELECT * FROM ${tableName};`).all();
    console.log(results);
}
//const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", ethers.provider)
async function main() {
 
  const [deployer] = await ethers.getSigners();
  console.log(
      "Deploying the contracts with the account:",
      await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const accounts = await ethers.getSigners();
  //console.log(accounts[0])
//   testDb(accounts[0]);
//   return;
  //console.log("Wallet Ethereum Address:", wallet.address);

// //   deploy DealStatus
//   const Cid = await ethers.getContractFactory('Cid', accounts[0]);
//   console.log('Deploying Cid...');
//   const cid = await Cid.deploy();
//   await cid.deployed()
//   console.log('Cid deployed to:', cid.address);

//   //deploy DealStatus
//   const Proof = await ethers.getContractFactory('Proof', {
//       libraries: {
//           Cid: cid.address,
//       },
//   });
//   console.log('Deploying Proof...');
//   const proof = await Proof.deploy();
//   await proof.deployed()
//   console.log('Proof deployed to:', proof.address);

//   //deploy DealStatus
//   const Daopia = await ethers.getContractFactory('Daopia', {
//       libraries: {
//           Cid: cid.address,
//       },
//   });
//   console.log('Deploying Daopia...');
//   const daopia = await Daopia.deploy();
//   await daopia.deployed();
//   console.log('Daopia deployed to:', daopia.address);
//   console.log("Deal status address is : ", await daopia.dealStatus());




 const daopia = await ethers.getContractAt("Daopia", "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c");
  let tableId = await daopia.proposalsTableId();
  console.log("Table ID is : ", tableId.toString());
  
 // let tablePrefix = await daopia._TABLE_PREFIX();
  //console.log("Table ID is : ", tablePrefix);
  let num = Number(tableId);
  const tableName = "daopia"+"_31337_" + num; // Our pre-defined health check table
  
  const registrationDetails = {
    period: 3600,
    price: ethers.utils.parseEther("0.1"),
    isBalanceLocked: false,
    paymentType: 1, // PaymentType.Ether
    paymentContract: ethers.constants.AddressZero, // This is for Ether payment
    vault: accounts[0].address, // Owner should be the vault for this test
    registrationStatus: 0, // RegistrationStatus.Open
  };

  const dealDetails = {
    num_copies:1,
    repair_treshold: 28800,
    renew_treshold: 28800,
  }
// Ensure the owner (accounts[0]) is calling the function
    //await daopia.registerDao(registrationDetails, dealDetails);

  //await daopia.connect(accounts[1]).makeProposalToDao(accounts[0].address, "Proposal1");
  //await daopia.changeCidOnProposalTable(accounts[0].address, "New Cid Changed", 1);
  const db = new Database({autoWait: false,signer: accounts[0]});
  //await daopia.approveProposal("New Cid Changed",1);
  const { results } = await db.prepare(`SELECT * FROM ${tableName};`).all();
  console.log(results);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
