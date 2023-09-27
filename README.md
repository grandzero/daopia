# **Daopia: Decentralized Autonomous Organization Financing Platform**

## Contracts

Cid address: **[0x3eE691d2D3630e092F0400A8373dD405Ef971442](https://filfox.info/en/address/0x3eE691d2D3630e092F0400A8373dD405Ef971442)**

Proof address: **[0xC985C830993921eC059EB191dA48076B1859c092](https://filfox.info/en/address/0xC985C830993921eC059EB191dA48076B1859c092)**

Daopia address: **[0x2F3e38b0772E8077Bba1884Ee3f286F72369b35C](https://filfox.info/en/address/0x2F3e38b0772E8077Bba1884Ee3f286F72369b35C)**

Deal status address : **[0x404d49b3c515f7506F3274C0280cf65fA294D0ef](https://filfox.info/en/address/0x404d49b3c515f7506F3274C0280cf65fA294D0ef)**

## **Overview**

Daopia is a robust platform designed to facilitate the creation and management of Decentralized Autonomous Organizations (DAOs). It offers a comprehensive suite of features that allow DAOs to define their operational parameters, manage memberships, handle payments, and more. The platform is built on the Ethereum blockchain, leveraging smart contracts to ensure transparency, security, and efficiency.

## **Features**

### **Register DAO**

### Deal Details

DAOs can predefine the details for replicating, renewing, and repairing the files they will support and hold within their structure. This ensures that datasets and uploads from contributors adhere to these rules and are properly maintained on Filecoin.

### DAO Details

- **Period**: DAOs can request payments at flexible intervals for access to their files or datasets. The period is determined by the DAOs and can be as granular as seconds.
- **Price**: The amount payable at the end of each period, denominated in Wei and of type uint256.
- **isBalanceLocked**: DAOs can use the Daopia contract as a vault or request direct payments to their addresses. If true, the Daopia contract acts as a vault; otherwise, payments are directly transferred to the DAO’s account.
- **PaymentType**: DAOs can request payments in native coin or ERC20 tokens. Future versions will also support contributions or support requests. The current Daopia contract supports both native coin and token payments.
- **Vault**: The address where payments will be sent or withdrawn. It must be the same as the DAO’s address.
- **RegistrationStatus**: DAOs can open or close registrations. If registration is closed, payments are not accepted, and no new members are admitted.

### DAO Frontend

- **Name**: The name of the DAO is recorded for display on the frontend.
- **Description**: A brief description of the DAO.
- **LogoUrl**: A link to the DAO’s logo, if available.
- **Communication**: Contact information such as a Discord link or email can be provided.
- **DAO**: The address of the DAO is re-added for access purposes from the frontend.

### **Change DAO Details**

DAOs can update information such as price, period, etc., later. Only wallets with DAO registration can perform this.

### **Make Payment**

Any user can register with a listed DAO by making a payment. Users make payments for the specified periods, thereby registering with the DAO. The **`getUser`** function of this contract is then executed by Lighthouse to determine whether the user has access to the file.

### **Apply Discount**

DAOs can assign monthly discounts to users who contribute significantly to the community. The applied discount is deducted from the payment.

### **Make Proposal to DAO**

Any user, whether registered with a DAO or not, can submit a contribution request to an active DAO with open registration. A brief description and the address of the DAO to which the contribution will be made are required. The proposal is recorded on Tableland, and once the file is uploaded, the CID is updated and presented to the DAO. If the contribution is accepted, it is approved by the DAO, triggering automatic replication/renewal processes.

### **Approve Proposal**

When a DAO approves a proposal, the status of that proposal is updated on Tableland. Subsequently, a function in the DealStatus contract deployed by the Daopia contract is called. The backend captures this call, creates a job for the corresponding CID, and performs replication and renewal processes for that file.

## **Deployment Details**

Before deploying, ensure to add your **`PRIVATE_KEY`** to the **`.env`** file for secure environment variable management.

### **Testing on Mumbai Local Fork**

Tests are executed on a Mumbai local fork to verify the proper functioning of Tableland. To run Tableland local tests, comment out the local Hardhat configuration in the Hardhat config file.

### **Deployment Commands**

- **Deploy**:

```jsx
npx hardhat run --network calibrationnet scripts/deploy.ts
```

- **Test**:

```jsx
npx hardhat test
```

- **Operations**:

```jsx
npx hardhat run --network calibrationnet scripts/op.ts
```

- **Tableland Local Test**:

```jsx
npx local-tableland
```

Follow the above commands for deploying, testing, and performing operations on the Daopia platform. Ensure to have the necessary configurations set up and dependencies installed before running these commands.

## **Communication**

For any inquiries or further information, please reach out to us through our **[Discord](https://discord.com/users/GrandZero#9005)** or via **[Email](bayramutkuuzunlar@gmail.com)**.

## **Contributing**

We welcome contributions from the community. If you’d like to contribute, please make a proposal to our DAO. We appreciate your support in making Daopia a more robust and versatile platform for decentralized organizations.

## **License**

Daopia is open-source and licensed under the **[MIT License](https://opensource.org/license/mit/)**.
