require('dotenv').config();
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require('./scripts/hardhat.tasks.js');

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            // loggingEnabled: true,
        },
        nitroDevnet: {
            accounts: [process.env.NITRODEVNET_PKEY],
            url: "https://nitro-devnet.arbitrum.io/rpc",
        },
        rinkArby: {
            accounts: [process.env.RINKARBY_PKEY],
            url: "https://rinkeby.arbitrum.io/rpc",
        }
        // arbOne: {
        //     accounts: [process.env.ARBONE_PKEY],
        //     url: "https://arbitrum.io/rpc",
        // }
    },
    paths: {
        sources: "./contracts",
        cache: "./build/cache",
        artifacts: "./build/artifacts",
        tests: "./test",
    },
    solidity: {
        compilers: [
            {
                version: "0.8.10",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000,
                    }
                }
            },
        ],
        overrides: {
            "contracts/MerkleTreeWithHistory.yul": {
                version: "0.8.10",
                settings: {}
            }
        },
    }
};
