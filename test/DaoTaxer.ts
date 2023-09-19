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
      const [owner, otherAccount] = await ethers.getSigners();
  
      const DaoTaxer = await ethers.getContractFactory("Lock");
      const daoTaxer = await DaoTaxer.deploy();
  
      return { daoTaxer, owner, otherAccount };
    }
  
    describe("Deployment", function () {
      it("Should register a dao", async function () {
        const { daoTaxer, owner  } = await loadFixture(deployOneYearLockFixture);
        const registrationDetails = {
            period: 3600,
            price: 100000000000000000,
            isBalanceLocked: false,
            paymentType: 1, // PaymentType.Ether
            paymentContract: "0x0", // This is for Ether payment
            vault: owner, // Owner should be the vault for this test
            registrationStatus: 0, // RegistrationStatus.Open
          };
        // Ensure the owner (accounts[0]) is calling the function
        await daoTaxer.registerDao(registrationDetails, { from: owner });
        const daoDetails = await daoTaxer.daoDetails(owner);
        expect(daoDetails.vault).to.equal(owner);
      });
  
     
  
     
    });
  
    
  });
  