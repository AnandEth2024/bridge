'use strict';

const chai = require('chai');

const {
    utils: { defaultAbiCoder },
    Contract,
    Wallet,
    getDefaultProvider,
} = require('ethers');

const { expect } = chai;
chai.use(require('chai-as-promised'));
const {
    utils: { deployContract },
    getNetwork,
    stopAll,
    relay,
    createAndExport,
    createNetwork,
} = require('@axelar-network/axelar-local-dev');

const { keccak256 } = require('ethers/lib/utils');



const IAxelarGateway = require('../artifacts/@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol/IAxelarGateway.json');
const IAxelarGasService = require('../artifacts/@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol/IAxelarGasService.json');
const { setLogger } = require('@axelar-network/axelar-local-dev/dist/utils.js');
const ERC1155crossChain  = require('../artifacts/contracts/ERC1155.sol/ERC1155CrossChain.json');


let contract, ERC1155_Eth_contract, ERC1155_Avalanche_contract;
let provider;
let wallet, Eth_gasReceiver, eth;
let chains, deployer_address;
let Eth_chain,Avalanche_chain;
let Eth_gateway,Avalanche_gateway;
let usdc;
const initialBalance = BigInt(1e18);


setLogger((...args) => {});


describe('XC20 Wrapper', () => {
    beforeEach(async () => {
        // const deployer_key = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
        eth = await createNetwork({
            name: 'Ethereum',
        });
        // console.log(eth);
        wallet = eth.userWallets[0];
        
        deployer_address = wallet.address;
        const toFund = [deployer_address];

        chains = require('../local.json');
        Eth_chain = chains[0];
        Avalanche_chain = chains[1];
        const Eth_provider = getDefaultProvider(Eth_chain.rpc);
        const Avalanche_provider = getDefaultProvider(Avalanche_chain.rpc);

        Eth_gateway = new ethers.Contract(Eth_chain.gateway, IAxelarGateway.abi, Eth_provider);
        Eth_gasReceiver=new ethers.Contract(Eth_chain.gasReceiver,IAxelarGasService.abi,Eth_provider);
        Avalanche_gateway = new ethers.Contract(Avalanche_chain.gateway, IAxelarGateway.abi, Avalanche_provider);
        const Avalanche_gasReceiver = new ethers.Contract(Avalanche_chain.gasReceiver, IAxelarGasService.abi, Avalanche_provider);


        // deploy ERC1155 cross-chain contract on ethereum
        ERC1155_Eth_contract = await deployContract(wallet, ERC1155crossChain, [
            Eth_gateway.address,
            Eth_gasReceiver.address,
            'www.realtoapps.com',
        ]);

        // deploy ERC1155 cross-chain contract on Avalanche
        ERC1155_Avalanche_contract = await deployContract(wallet, ERC1155crossChain, [
            Avalanche_gateway.address,
            Avalanche_gasReceiver.address,
            'www.realtoapps.com',
        ]);
        

    });

    afterEach(async () => {
        await stopAll();
    });
    it("should burn and mint ERC-1155 tokens on cross-chain", async function(){
        const [owner] = await ethers.getSigners();    
        console.log("ERC1155_Eth_contract", ERC1155_Eth_contract.address);
        console.log("ERC1155_Avalanche_contract", ERC1155_Avalanche_contract.address);
        console.log("ETH gateway address",Eth_gateway.address);
        console.log('balance before minting on ethereum', await ERC1155_Eth_contract.balanceOf(owner.address, 10));
        console.log('balance before minting on Avalanche', await ERC1155_Avalanche_contract.balanceOf(owner.address, 10));

        await ERC1155_Eth_contract.connect(wallet).giveMe(10,BigInt(10000e18));
        await ERC1155_Avalanche_contract.connect(wallet).giveMe(10, BigInt(10000e18));

        console.log('balance after minting on ethereum', await ERC1155_Eth_contract.balanceOf(wallet.address, 10));
        console.log('balance after minting on Avalanche', await ERC1155_Avalanche_contract.balanceOf(wallet.address, 10));

        console.log("cross-chain transaction from ethereum to Avalanche is in process......");
        await owner.sendTransaction({ to: deployer_address, value: ethers.utils.parseEther('50') });    
        console.log(await ethers.provider.getBalance(wallet.address));
        const payload = ethers.utils.defaultAbiCoder.encode(['address', 'uint256', 'uint256'], [deployer_address, 10, BigInt(100e18)]);
        const Tx = await ERC1155_Eth_contract.connect(wallet).transferRemote(
            'Avalanche',
            ERC1155_Avalanche_contract.address,
            10,
            BigInt(1000e18),
            { value: ethers.utils.parseEther('10'), gasLimit: 5000000 },
        );
        // console.log(Tx)
        
        await relay();
        // console.log("debug address on Avalanche after cross-chain:", await ERC1155_Avalanche_contract.Address());
        console.log('balance on ethereum after cross-chain transaction ', await ERC1155_Eth_contract.balanceOf(wallet.address, 10));
        console.log(
            'balance on Avalanche after cross-chain transaction ',
            await ERC1155_Avalanche_contract.balanceOf(wallet.address, 10),
        );



    })
})