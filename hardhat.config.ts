import '@nomicfoundation/hardhat-ignition-ethers';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-verify';
import dotenv from 'dotenv';
import type { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

const config: HardhatUserConfig = {
  networks: {
    // for mainnet
    base_mainnet: {
      url: process.env.ALCHEMY_BASE_MAINNET_RPC_URL as string,
      accounts: [process.env.PRIVATE_KEY as string],
    },
    // for testnet
    base_sepolia: {
      url: process.env.ALCHEMY_BASE_SEPOLIA_RPC_URL as string,
      accounts: [process.env.PRIVATE_KEY as string],
    },
    // for degen mainnet
    degen_mainnet: {
      url: process.env.DEGEN_RPC_URL as string,
      accounts: [process.env.PRIVATE_KEY as string],
    },
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY ?? '',
      baseGoerli: process.env.BASESCAN_API_KEY ?? '',
      baseSepolia: process.env.BASESCAN_API_KEY ?? '',
      degen: 'abc',
    },
    customChains: [
      {
        network: 'baseSepolia',
        chainId: 84532,
        urls: {
          apiURL: 'https://api-sepolia.basescan.org/api',
          browserURL: 'https://sepolia.basescan.org',
        },
      },
      {
        network: 'degen',
        chainId: 666666666,
        urls: {
          apiURL: 'https://explorer.degen.tips/api',
          browserURL: 'https://explorer.degen.tips/',
        },
      },
    ],
  },
  solidity: {
    version: '0.8.20',
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999,
      },
    },
  },
  sourcify: {
    enabled: true,
  },
};

export default config;
