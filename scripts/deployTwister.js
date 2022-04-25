require('dotenv').config();
const { ethers } = require('hardhat');

async function main() {
    const factory = await ethers.getContractFactory('TwisterZero', {
        libraries: {
            MerkleTreeWithHistory: process.env.MERKLE_ADDRESS
        }
    });

    this.twisterZero = await factory.deploy(
        process.env.ARBFRAX_ADDRESS,
        ethers.utils.parseUnits('10000')
    );
    console.log(this.twisterZero.address);
};

main().then(() => process.exit());