const { deployBytes } = require('../scripts/hardhat.utils.js');
const MerkleTreeWithHistory = require('../build/MerkleTreeWithHistory.json');

async function main() {
    const merkleTree = await deployBytes(
        'MerkleTreeWithHistory',
        [],
        MerkleTreeWithHistory.bytecode
    );
    console.log(merkleTree.address);
};

main().then(() => process.exit());