const { expect } = require('chai');
const { ethers } = require('hardhat');
const {
    generateMerkleProof,
    generateZeroKnowledgeProof,
    zkUtils
} = require('twister-js');
const {
    deploy,
    deployBytes,
} = require('../scripts/hardhat.utils.js');
const MerkleTreeWithHistory = require('../build/MerkleTreeWithHistory.json');

const {
    createDeposit,
    padHexString
} = zkUtils;
const {
    getCommitmentsFromChain,
    generateMerkleProofFromTree
} = generateMerkleProof;

function toDecimalsBN(val, decimals=18) {
    return ethers.utils.parseUnits(val, decimals);
};

describe('[START] - TwisterZero.test.js', function() {
    before(async () => {
        this.signer = await ethers.getSigner();
        this.account = this.signer.address;

        this.frax = await deploy('ArbitrumFRAX');
        this.totalSupply = toDecimalsBN('1000000'); // 1m
        this.denomination = toDecimalsBN('10000'); // 10k
        await this.frax.mint(this.account, this.totalSupply);

        this.merkleTree = await deployBytes(
            'MerkleTreeWithHistory',
            [],
            MerkleTreeWithHistory.bytecode
        );

        const factory = await ethers.getContractFactory('TwisterZero', {
            libraries: {
                MerkleTreeWithHistory: this.merkleTree.address
            }
        });
        this.twisterZero = await factory.deploy(
            this.frax.address, this.denomination
        );

        this.numDeposits = 5;
    });

    describe(" -------- Successful Calls -------- ", () => {
        describe('Deposits && Withdrawals', () => {
            it('should successfully deposit', async () => {
                await this.frax.approve(
                    this.twisterZero.address,
                    ethers.constants.MaxUint256
                );

                this.deposit = createDeposit({
                    currency: 'frax',
                    denomination: 10000,
                    netId: 31337
                });

                await this.twisterZero.deposit(
                    padHexString(this.deposit.commitmentHex)
                );

                expect(await this.frax.balanceOf(this.twisterZero.address))
                    .to.be.equal(toDecimalsBN('10000'));
                expect(await this.frax.balanceOf(this.account))
                    .to.be.equal(toDecimalsBN('990000'));
            });

            it('should submit many deposits', async () => {
                this.deposits = [];
                for (let i = 0; i < this.numDeposits; i++) {
                    this.deposits.push(createDeposit({
                        currency: 'frax',
                        denomination: 10000,
                        netId: 31337
                    }));
                    await this.twisterZero.deposit(
                        padHexString(this.deposits[i].commitmentHex)
                    );
                }

                expect(await this.frax.balanceOf(this.twisterZero.address))
                    .to.be.equal(
                        this.denomination
                            .add(this.denomination.mul(this.numDeposits))
                    );
            }).timeout(120000);

            it('should successfully withdraw many times', async () => {
                (function shuffleArray(array) {
                    // https://stackoverflow.com/questions/2450954/
                    // how-to-randomize-shuffle-a-javascript-array
                    for (var i = array.length - 1; i > 0; i--) {
                        var j = Math.floor(Math.random() * (i + 1));
                        [array[i], array[j]] = [array[j], array[i]]
                    }
                })(this.deposits);

                const leaves = await getCommitmentsFromChain({
                    provider: this.signer.provider,
                    fromBlock: 0,
                    twisterAddress: this.twisterZero.address,
                });

                for (let i = 0; i < this.numDeposits; i++) {

                    const merkleProof = await generateMerkleProofFromTree({
                        leaves,
                        commitment: this.deposits[i].commitmentHex.toHexString()
                    });

                    const zkProof = await generateZeroKnowledgeProof({
                        merkleProof,
                        nullifier: this.deposits[i].nullifier,
                        secret: this.deposits[i].secret,
                        nullifierHash: this.deposits[i].nullifierHex,
                        recipient: this.account
                    });

                    await this.twisterZero.withdraw(
                        zkProof.solidityInput.proof,
                        zkProof.solidityInput.root,
                        zkProof.solidityInput.nullifierHash,
                        zkProof.solidityInput.recipient,
                        zkProof.solidityInput.relayer,
                        zkProof.solidityInput.fee,
                        zkProof.solidityInput.refund
                    );
                }

                expect(await this.frax.balanceOf(this.twisterZero.address))
                    .to.be.equal(this.denomination);

                expect(await this.frax.balanceOf(this.account))
                    .to.be.equal(this.totalSupply.sub(this.denomination));
            }).timeout(300000);

            it('should successfully withdraw', async () => {
                const leaves = await getCommitmentsFromChain({
                    provider: this.signer.provider,
                    fromBlock: 0,
                    twisterAddress: this.twisterZero.address,
                });

                const merkleProof = await generateMerkleProofFromTree({
                    leaves,
                    commitment: this.deposit.commitmentHex.toHexString()
                });

                const zkProof = await generateZeroKnowledgeProof({
                    merkleProof,
                    nullifier: this.deposit.nullifier,
                    secret: this.deposit.secret,
                    nullifierHash: this.deposit.nullifierHex,
                    recipient: this.account
                });

                await this.twisterZero.withdraw(
                    zkProof.solidityInput.proof,
                    zkProof.solidityInput.root,
                    zkProof.solidityInput.nullifierHash,
                    zkProof.solidityInput.recipient,
                    zkProof.solidityInput.relayer,
                    zkProof.solidityInput.fee,
                    zkProof.solidityInput.refund
                );

                expect(await this.frax.balanceOf(this.twisterZero.address))
                    .to.be.equal(0);

                expect(await this.frax.balanceOf(this.account))
                    .to.be.equal(this.totalSupply);
            }).timeout(60000);
        });
    });
});