const { network } = require("hardhat");

function sleep(timeInMs) {
    return new Promise((resolve) => setTimeout(resolve, timeInMs));
}

// move "amount" of blocks and wait for "sleepAmount"
async function moveBlocks(amount, sleepAmount = 0) {
    console.log("Moving blocks...");
    for (let index = 0; index < amount; index++) {
        await network.provider.request({
            method: "evm_mine",
            params: [],
        });
        if (sleepAmount) {
            console.log(`Sleeping for ${sleepAmount}`);
            await sleep(sleepAmount);
        }
    }
    console.log(`Moved ${amount} blocks`);
}

module.exports = {
    moveBlocks,
    sleep,
};
