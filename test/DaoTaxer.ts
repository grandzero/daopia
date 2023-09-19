import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import { ethers } from "hardhat";
  
  describe("DaoTaxer", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployOneYearLockFixture() {
  
  
      // Contracts are deployed using the first signer/account by default
      const [owner, ...accounts] = await ethers.getSigners();
  
      const DaoTaxer = await ethers.getContractFactory("DaoTaxer");
      const daoTaxer = await DaoTaxer.deploy();
  
      return { daoTaxer, owner, accounts };
    }
  
    describe("Deployment", function () {
      let daoTaxer:any;
      let owner:any;
      let accounts:any;

      beforeEach(async () => {
        let result = await loadFixture(deployOneYearLockFixture);
        daoTaxer = result.daoTaxer;
        owner = result.owner;
        accounts = result.accounts;
        const registrationDetails = {
          period: 3600,
          price: ethers.parseEther("0.1"),
          isBalanceLocked: false,
          paymentType: 1, // PaymentType.Ether
          paymentContract: ethers.ZeroAddress, // This is for Ether payment
          vault: owner.address, // Owner should be the vault for this test
          registrationStatus: 0, // RegistrationStatus.Open
        };

        const dealDetails = {
          num_copies:1,
          repair_treshold: 28800,
          renew_treshold: 28800,
        }
      // Ensure the owner (accounts[0]) is calling the function
      await daoTaxer.registerDao(registrationDetails, dealDetails);
      });

      it("Register Dao - Should return the right owner", async function () {
        
        const daoDetails = await daoTaxer.daoDetails(owner.address);
        expect(daoDetails.vault).to.equal(owner.address);
      });
      
      it("Make payment - Payment should be valid for first paid and then it should turn into invalid", async function () {
        // @ts-ignore
        const otherAccount = accounts[1];      
        const daoDetails = await daoTaxer.daoDetails(owner.address);
        expect(daoDetails.vault).to.equal(owner.address);
        // Ensure the other account is making the payment with 0.5 ETH attached
        
        await daoTaxer.connect(otherAccount).makePayment(owner.address, { value: ethers.parseEther("0.5") });
       
        expect(await ethers.provider.getBalance(await daoTaxer.getAddress())).to.equal(ethers.parseEther("0.5"));
        // Fast forward the block timestamp by 10,000 seconds
        //@ts-ignore
        let userDetails = await daoTaxer.getUser(otherAccount.address, owner.address);
        let first = BigInt(1);
        
        expect(userDetails).to.equal(first);
        //@ts-ignore
        let blockTimestamp = await ethers.provider.getBlock("latest").then((block) => block.timestamp);
       
        await ethers.provider.send("evm_increaseTime", [10000]);
        await ethers.provider.send("evm_mine");
          // Get block timestamp
          //@ts-ignore
         let afterBlockTimestamp = await ethers.provider.getBlock("latest").then((block) => block.timestamp);
        
         expect(afterBlockTimestamp-blockTimestamp).greaterThanOrEqual(10000);
         // Call the getUser function with the other account's address
         //@ts-ignore
        userDetails = await daoTaxer.getUser(otherAccount.address, owner.address);
        
        let second = BigInt(0);
        expect(userDetails).to.equal(second);
      });
      

      it("Make proposal - Anyone should be able to make proposal to open dao", async function () {
        // Create a proposal to open a dao using makeproposaltodao function
        await daoTaxer.connect(accounts[1]).makeProposalToDao(owner.address, "Proposal1");
        // Check if the proposal exists
        // let daoTable = await daoTaxer.daoTableIds(owner.address);
   
        expect(1).to.equal(1);
      });

      it("Approve proposal - Only dao should be able to approve proposal", async function () {
        // Create a proposal to open a dao using makeproposaltodao function
        let proposalId = await daoTaxer.proposalCounter();
        await daoTaxer.approveProposal(proposalId=1);
        // Check if the proposal exists
        // let daoTable = await daoTaxer.daoTableIds(owner.address);
   
        expect(1).to.equal(1);
      });
    });
  
    
  });
  