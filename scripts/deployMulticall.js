const { ethers } = require('hardhat');

async function main() {
    const factory = await ethers.getContractFactory('Multicall');
    const multicall = await factory.deploy();
    console.log(multicall.address);
};

main().then(() => process.exit());