require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@openzeppelin/contracts-upgradeable");
require("hardhat-deploy");
require("dotenv").config();

const {
  PRIVATE_KEY,
  RPC_SEPOLIA,
  RPC_GOERLI
} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
   namedAccounts: {
    deployer:0,
    user1:1,
    user2:2,
  },
  networks: {
    hardhat: {},
    sepolia: {
      url: RPC_SEPOLIA || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    },
    goerli: {
      url: RPC_GOERLI || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    }
  }
};
