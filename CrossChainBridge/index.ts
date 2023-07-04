import {
    createAndExport,
    createNetwork,
    relay
} from "@axelar-network/axelar-local-dev"
import { network } from "hardhat";

async function useCreateNetwork(){
    const eth=await createNetwork({
        name:'Ethereum'
    })
    const ethWallet=eth.userWallets[0];
    await eth.deployToken('USDC', 'aUSDC', 8, BigInt(100_00_00e6));
    await eth.giveToken(ethWallet.address, "aUSDC", BigInt(1000e6));
    const TokenAddress=await eth.getTokenContract('aUSDC');
    console.log("Balance usdc before transfer on ethereum", await TokenAddress.balanceOf(ethWallet.address))
    const ganache = await createNetwork({
        name: 'ganache'
    })
    const ganacheWallet = ganache.userWallets[0];
    await ganache.deployToken('USDC', 'aUSDC', 8, BigInt(100_00_00e6));
    await ganache.giveToken(ganacheWallet.address, "aUSDC", BigInt(1000e6));
    const TokenAddress2 = await ganache.getTokenContract('aUSDC');
    console.log("Balance usdc before transfer on ganache", await TokenAddress2.balanceOf(ganacheWallet.address))

    const Tx=await TokenAddress.connect(ethWallet).approve(eth.gateway.address,BigInt(1000e6));
    await Tx.wait();
    // console.log(Tx);

    const gatewayTx= await eth.gateway.connect(ethWallet).sendToken(ganache.name,ganacheWallet.address,'aUSDC',BigInt(1000e6));
    await gatewayTx.wait();
    await relay();
    // console.log("gateway transaction of usdc from ethereum to ganache", gatewayTx) 
    console.log("Balance usdc after transfer from ethereum to ganache", await TokenAddress.balanceOf(ethWallet.address))
    console.log("Balance usdc after transfer on ganache from ethereum", await TokenAddress2.balanceOf(ganacheWallet.address))

}
useCreateNetwork()
async function useCreatenetwork() {
    await createAndExport({
        chains: ["Ethereum", "Avalanche", "ganache"],
        callback: async (network, info): Promise<null> => {
            const userwallet = network.userWallets[0];
            await network.deployToken('USDC', 'aUSDC', 8, BigInt(100_00_00e6));
            // console.log("account of userwallet", userwallet);
            await network.giveToken(userwallet.address, "aUSDC", BigInt(1000e6));
            return null;
        },
    });
}


useCreatenetwork()