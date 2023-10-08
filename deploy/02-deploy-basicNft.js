const { network, ethers } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    // deploy the contract
    const basicNft = await deploy("BasicNft", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    // verify the contract if we are on testnet
    if (!developmentChains.includes(network.name)) {
        log("Verifing...");
        await verify(basicNft.address, []);
    }
};

module.exports.tags = ["all", "basicNft"];
