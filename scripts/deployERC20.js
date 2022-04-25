const { ethers } = require('hardhat');

async function main() {
    const factory = await ethers.getContractFactory('ArbitrumFRAX');
    const frax = await factory.deploy();
    console.log(frax.address);
    const signer = await ethers.getSigner();
    await frax.mint(signer.address, ethers.utils.parseUnits('1000000', 18));
};

main().then(() => process.exit());