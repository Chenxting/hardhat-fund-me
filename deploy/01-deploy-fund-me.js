// These're what hardhat or ethers to do for deploying a contract
// 1.import
// 2.main function
// 3.calling of main function

// What about hardhat-deploy-ethers?
// 1.just import and export these functions
// 2.Whenever we run a deploy scripts,
//   hardhat-deploy automatically calls this function
//   and pass the hre object into it.

const { network } = require("hardhat")
const { verify } = require("../utils/verify")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
// 以上语法相当于“提取“，也可像下面这样。(要export才能require)
// const helperConfig = require("../helper-hardhat-config")
// const networkConfig = helperConfig.networkConfig

// Method 1
// function deployFunc(hre) {
//     console.log("Hi!")
//     hre.getNamedAccounts()
//     hre.deployments
// }
// module.exports.default = deployFunc

// Method 2
// module.exports = async (hre) => {
//     const { getNamedAccounts, deployments } = hre
//     // hre.getNamedAccounts
//     // hre.depoyments
// }

module.exports = async ({ getNamedAccounts, deployments }) => {
    // 1.部署方法，日志方法
    const { deploy, log } = deployments
    // 2.部署者：在hardhat.config.js中的namedAccounts
    const { deployer } = await getNamedAccounts()
    // 3.chainId
    const chainId = network.config.chainId
    // 4.priceFeed
    // if chainId is X use address Y
    // if chainId is Z use address A
    // if the contract doesn't exist, we deploy a minimal version
    // of it for our local testing
    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    // what happens when we want to change chains?
    // when going for localhost or hardhat network we want to use a mock
    // baceuse hardhat network is a blank blockchain,
    // and it gets destoryed everytime we our scripts finish,
    // the same to localhost

    // 5.fundme
    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // put price feed address
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    // 6.verify
    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, args)
    }
    log("-------------------------------------------------")
}

module.exports.tags = ["all", "fundme"]
