const { ethers } = require("hardhat");

// using both key hash for local and sepolia
// for subscriptionId in local, we will get it after createSubscription
const networkConfig = {
    31337: {
        name: "localhost",
        vrfCoordinatorAddress: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
        keyHash:
            "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
        callbackGasLimit: "500000",
    },
    // VRF contract Address, values can be obtained at https://docs.chain.link/vrf/v2/subscription/supported-networks#sepolia-testnet
    11155111: {
        name: "sepolia",
        vrfCoordinatorAddress: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
        keyHash:
            "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
        callbackGasLimit: "500000",
        subscriptionId: "4648",
    },
};

const developmentChains = ["localhost", "hardhat"];

module.exports = {
    networkConfig,
    developmentChains,
};
