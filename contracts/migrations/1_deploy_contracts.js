const CoffeeBatchNFT = artifacts.require("CoffeeBatchNFT");
module.exports = function (deployer) {
    deployer.deploy(CoffeeBatchNFT);
};