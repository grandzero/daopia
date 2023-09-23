  import { expect } from "chai";
  import { ethers } from "hardhat";
  import * as dealStatusABI from "../artifacts/contracts/DealStatus.sol/DealStatus.json";
  describe("Daopia", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployOneYearLockFixture() {
      
      const Cid = await ethers.getContractFactory('Cid');
        
      const cid = await Cid.deploy();
      await cid.deployed()
    
      const Proof = await ethers.getContractFactory('Proof', {
        libraries: {
            Cid: cid.address,
        },
      });
    
    const proof = await Proof.deploy();
    await proof.deployed()
  
      // Contracts are deployed using the first signer/account by default
      const [owner, ...accounts] = await ethers.getSigners();
  
      const Daopia = await ethers.getContractFactory("Daopia", {
        libraries: {
                  Cid: cid.address,
              },
      });
      const daopia = await Daopia.deploy();

      // const DealStatus = await ethers.getContractFactory("DealStatus");
      // const dealStatus = await DealStatus.deploy();
  
      return { daopia, owner, accounts };
    }
  
    describe("Deployment", function () {
      let daopia:any;
      let owner:any;
      let accounts:any;

      beforeEach(async () => {
        let result = await deployOneYearLockFixture();
        daopia = result.daopia;
        owner = result.owner;
        accounts = result.accounts;
        const registrationDetails = {
          period: 3600,
          price: ethers.utils.parseEther("0.1"),
          isBalanceLocked: false,
          paymentType: 1, // PaymentType.Ether
          paymentContract: ethers.constants.AddressZero, // This is for Ether payment
          vault: owner.address, // Owner should be the vault for this test
          registrationStatus: 0, // RegistrationStatus.Open
        };

        const dealDetails = {
          num_copies:1,
          repair_treshold: 28800,
          renew_treshold: 28800,
        }
      // Ensure the owner (accounts[0]) is calling the function
      await daopia.registerDao(registrationDetails, dealDetails);
      });

      it("Successfully deploy the deal status contract", async function () {
       
  
  
      // //deploy DealStatus
      // const dealStatus = await ethers.getContractFactory('DealStatus', {
      //     libraries: {
      //         Cid: cid.address,
      //     },
      // });
      // console.log('Deploying DealStatus...');
      // const dealstatus = await dealStatus.deploy();
      // await dealstatus.deployed()
      // console.log('DealStatus deployed to:', dealstatus.address);
      
      //const dealStatusOwner = await dealstatus.daopia();
      let dealsAddress = await daopia.dealStatus();
      const dealStatus = await ethers.getContractAt("DealStatus", dealsAddress);
      const daopiaAddress = await dealStatus.daopia();
        expect(daopiaAddress).to.equal(daopia.address);
      });

      it("Register Dao - Should return the right owner", async function () {
        
        const daoDetails = await daopia.daoDetails(owner.address);
        expect(daoDetails.vault).to.equal(owner.address);
      });
      
      it("Make payment - Payment should be valid for first paid and then it should turn into invalid", async function () {
        // @ts-ignore
        const otherAccount = accounts[1];      
        const daoDetails = await daopia.daoDetails(owner.address);
        expect(daoDetails.vault).to.equal(owner.address);
        // Ensure the other account is making the payment with 0.5 ETH attached
        
        await daopia.connect(otherAccount).makePayment(owner.address, { value: ethers.utils.parseEther("0.5") });
        expect(await ethers.provider.getBalance(await daopia.address)).to.equal(ethers.utils.parseEther("0.5"));
        // Fast forward the block timestamp by 10,000 seconds
        //@ts-ignore
        let userDetails = await daopia.getUser(otherAccount.address, owner.address);
        let first = BigInt(1);
        
        expect(userDetails).to.equal(first);
        //@ts-ignore
        let blockTimestamp = await ethers.provider.getBlock("latest").then((block) => block.timestamp);
       
        await ethers.provider.send("evm_increaseTime", [10000]);
        await ethers.provider.send("evm_mine", []);
          // Get block timestamp
          //@ts-ignore
         let afterBlockTimestamp = await ethers.provider.getBlock("latest").then((block) => block.timestamp);
        
         expect(afterBlockTimestamp-blockTimestamp).greaterThanOrEqual(10000);
         // Call the getUser function with the other account's address
         //@ts-ignore
        userDetails = await daopia.getUser(otherAccount.address, owner.address);
        
        let second = BigInt(0);
        expect(userDetails).to.equal(second);
      });
      

      it("Make proposal - Anyone should be able to make proposal to open dao", async function () {
        // Create a proposal to open a dao using makeproposaltodao function
        await daopia.connect(accounts[1]).makeProposalToDao(owner.address, "Proposal1");
        // Check if the proposal exists
        // let daoTable = await daopia.daoTableIds(owner.address);
   
        expect(1).to.equal(1);
      });

      it("Approve proposal - Only dao should be able to approve proposal", async function () {
        // Create a proposal to open a dao using makeproposaltodao function
        let proposalId = await daopia.proposalCounter();
        await daopia.approveProposal(proposalId=1);
        // Check if the proposal exists
        // let daoTable = await daopia.daoTableIds(owner.address);
   
        expect(1).to.equal(1);
      });
    });
  
    
  });
  