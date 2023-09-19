import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    hardhat: {
      forking: {
        url: "https://polygon-testnet.public.blastapi.io",
      },
      chainId: 80001,
    },
  },
};

export default config;
