// SPDX-License-Identifier: GPL
pragma solidity ^0.8.10;

import "./ProofLib.sol";

contract WithdrawVerifier {
    using ProofLib for ProofLib.G1Point;
    using ProofLib for ProofLib.G2Point;

    function withdrawVerifyingKey() internal pure returns (ProofLib.VerifyingKey memory vk) {
        vk.alfa1 = ProofLib.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = ProofLib.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = ProofLib.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = ProofLib.G2Point(
            [19193272194706276187521500824362629915031461306031031296712053014549944183297,
             14430439587109426575967232109453731571877836825295631306768690933652558777703],
            [1823222001677550174832938863195527484289924125705326358556979573784397422694,
             18369538238932145100194646353527617099403833598464911365429172078401265942890]
        );
        vk.IC = new ProofLib.G1Point[](7);

        vk.IC[0] = ProofLib.G1Point( 
            18543506737722477051394616837320212013164685340795257118729781415395877592198,
            17385891634477316595226486029796246440352943620911309829530957782460472897622
        );                                      
        
        vk.IC[1] = ProofLib.G1Point( 
            12064859534410046677554588112231217499875025487951406025776534518550567594307,
            19775437667915626172615296180633297916699925716144734778678748014222281717057
        );                                      
        
        vk.IC[2] = ProofLib.G1Point( 
            3783393677704792396401280480640167984757198487124275648205818944300261544832,
            5995188698125589751764229729874276144934920013933576435711063010488080638765
        );                                      
        
        vk.IC[3] = ProofLib.G1Point( 
            6340276539332831609102164128425264162921395398561493355683411423690065402969,
            11307002893955882287925979707412919436854813453140922075558141226361667108944
        );                                      
        
        vk.IC[4] = ProofLib.G1Point( 
            7602482576964108713643981298186027533827359383054086960422050128134958238848,
            2822570549127543103403630233832282108287353320916026863565212838988507921375
        );                                      
        
        vk.IC[5] = ProofLib.G1Point( 
            14939231819634047512008745198184904306885217559684189639090665827878853466588,
            18216420235997802029916889176516234362244278133341054167566617882219069280133
        );                                      
        
        vk.IC[6] = ProofLib.G1Point( 
            8755918516834282039718817195032392758496155999611493652197787920224096169841,
            10867346897675654953749409845852526373785691671713367598296085442862477136964
        );                                     

    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[8] calldata p,
            uint root,
            uint nullifierHash,
            uint recipient,
            uint relayer,
            uint fee,
            uint refund
    ) internal view returns (bool r) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        if (root >= snark_scalar_field
            || nullifierHash >= snark_scalar_field
            || recipient >= snark_scalar_field
            || relayer >= snark_scalar_field
            || fee >= snark_scalar_field
            || refund >= snark_scalar_field
        )
            revert GteSnarkScalarField();
        ProofLib.Proof memory proof;
        proof.A = ProofLib.G1Point(p[0], p[1]);
        proof.B = ProofLib.G2Point([p[2], p[3]], [p[4], p[5]]);
        proof.C = ProofLib.G1Point(p[6], p[7]);
        ProofLib.VerifyingKey memory vk = withdrawVerifyingKey();
        // Compute the linear combination vk_x
        ProofLib.G1Point memory vk_x = ProofLib.G1Point(0, 0);
        vk_x = vk_x.addition(vk.IC[1].scalar_mul(root));
        vk_x = vk_x.addition(vk.IC[2].scalar_mul(nullifierHash));
        vk_x = vk_x.addition(vk.IC[3].scalar_mul(recipient));
        vk_x = vk_x.addition(vk.IC[4].scalar_mul(relayer));
        vk_x = vk_x.addition(vk.IC[5].scalar_mul(fee));
        vk_x = vk_x.addition(vk.IC[6].scalar_mul(refund));
        vk_x = vk_x.addition(vk.IC[0]);
        return proof.A.negate().pairingProd4(
            proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        );
    }

    error GteSnarkScalarField();
}