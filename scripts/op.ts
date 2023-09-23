import { ethers } from "hardhat";
import { Database } from "@tableland/sdk";
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY || "", ethers.provider)
async function main() {
  //const daopia = await ethers.getContractAt("Daopia", "0x9f0107446A47b2D56e4572301cE29679b02dd146");
  //let tableId = await daopia.proposalsTableId();
 // console.log("Table ID is : ", tableId.toString());
  // const accounts = await ethers.getSigners();
//   const registrationDetails = {
//     period: 3600,
//     price: ethers.utils.parseEther("0.1"),
//     isBalanceLocked: false,
//     paymentType: 1, // PaymentType.Ether
//     paymentContract: ethers.constants.AddressZero, // This is for Ether payment
//     vault: wallet.address, // Owner should be the vault for this test
//     registrationStatus: 0, // RegistrationStatus.Open
//   };

//   const dealDetails = {
//     num_copies:1,
//     repair_treshold: 28800,
//     renew_treshold: 28800,
//   }
// // Ensure the owner (accounts[0]) is calling the function
//  await daopia.registerDao(registrationDetails, dealDetails);
// const daoDetails = await daopia.daoDetails(wallet.address);
//     console.log(daoDetails.vault, wallet.address);
  //await daopia.makeProposalToDao(wallet.address, "Proposal 17");

  //let num = Number(tableId);
  // const tableName = "daopia"+"_31337_" + num; 
  //await daopia.approveProposal("Proposal1",1);
  const tableName = "daopia_314159_369" //+num; // Our pre-defined health check table

  const db = new Database({autoWait: false, signer: wallet});

  const { results } = await db.prepare(`SELECT * FROM ${tableName};`).all();
  console.log(results);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
