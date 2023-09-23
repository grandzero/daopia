import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import {config as dotenvConfig} from "dotenv";
dotenvConfig();
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const config: HardhatUserConfig = {
  solidity:{
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
        details: { yul: false },
      },
    },
  },
  networks: {
    // hardhat: {
    //   forking: {
    //     url: "https://polygon-testnet.public.blastapi.io",
    //   },
    //   chainId: 80001,
    // },
    
  calibrationnet: {
      chainId: 314159,
      url: "https://api.calibration.node.glif.io/rpc/v1",
      accounts: [PRIVATE_KEY],
  },
  filecoinmainnet: {
      chainId: 314,
      url: "https://api.node.glif.io",
      accounts: [PRIVATE_KEY],
  },
  },
};

export default config;
