const { ethers, network } = require("hardhat");
const { moveBlocks } = require("../utils/move-blocks");

const TOKEN_ID = 3;

async function buyItem() {
    // create contract instance
    const nftMarketplace = await ethers.getContract("NftMarketplace");
    const basicNft = await ethers.getContract("BasicNft");

    // get the price of that NFT
    const listingItem = await nftMarketplace.getListingItem(
        basicNft.address,
        TOKEN_ID
    );
    const price = listingItem.price.toString();
    console.log(`The price to buy NFT: ${price}`);

    // conduct to buy
    const tx = await nftMarketplace.buyItem(basicNft.address, TOKEN_ID, {
        value: price,
    });
    await tx.wait(1);
    console.log(`NFT with tokenId: ${TOKEN_ID} has been bought!`);

    if (network.config.chainId == "31337") {
        await moveBlocks(2, (sleepAmount = 1000));
    }
}

buyItem()
    .then(() => process.exit(0))
    .catch((err) => {
        console.log(err);
        process.exit(1);
    });
