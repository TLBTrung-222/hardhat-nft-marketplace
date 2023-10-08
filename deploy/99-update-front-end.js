// update the marketplace address and abi to front-end (correspond to each chainId)
const { ethers, network } = require("hardhat");
const fs = require("fs");

const CONTRACT_ADDRESS_PATH =
    "../nextjs-nft-marketplace/constants/ContractAddresses.json";
const MARKETPLACE_ABI_PATH =
    "../nextjs-nft-marketplace/constants/NftMarketplace.json";
const NFT_ABI_PATH = "../nextjs-nft-marketplace/constants/BasicNft.json";

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = network.config.chainId;

    const nftMarketplace = await ethers.getContract("NftMarketplace");
    const basicNft = await ethers.getContract("BasicNft");

    console.log("Updating contract information to front-end...");
    await updateAddress(nftMarketplace.address, chainId);
    await updateAbi(nftMarketplace, basicNft, chainId);
    console.log("Update success!!");
};

async function updateAddress(nftMarketplaceAddress, chainId) {
    //* get the object need to update
    let contractAddresses = JSON.parse(fs.readFileSync(CONTRACT_ADDRESS_PATH));
    //* update the object
    // if the object[chainId] is empty -> the network doesn't appear -> replace with new array
    // if the object[chainId] have value -> the network appear -> add
    if (!contractAddresses[chainId]) {
        // if the network is empty, we add new object contains array
        contractAddresses[chainId] = {
            NftMarketplace: [nftMarketplaceAddress],
        };
    } else {
        // if that address exist, no need to write
        if (
            contractAddresses[chainId].NftMarketplace !== nftMarketplaceAddress
        ) {
            contractAddresses[chainId].NftMarketplace.push(
                nftMarketplaceAddress
            );
        }
    }

    //* write new object back to the file
    fs.writeFileSync(CONTRACT_ADDRESS_PATH, JSON.stringify(contractAddresses));
}

async function updateAbi(nftMarketplace, basicNft, chainId) {
    //* create the abi object
    const nftMarketplaceAbi = nftMarketplace.interface.format(
        ethers.utils.FormatTypes.json
    );
    const basicNftAbi = basicNft.interface.format(
        ethers.utils.FormatTypes.json
    );

    //* write back to file
    fs.writeFileSync(MARKETPLACE_ABI_PATH, nftMarketplaceAbi);
    fs.writeFileSync(NFT_ABI_PATH, basicNftAbi);
}

module.exports.tags = ["all", "updateUI"];
