const IdentityRegistry = artifacts.require("IdentityRegistry");
const EthereumDIDRegistry = artifacts.require("EthereumDIDRegistry");

module.exports = function(deployer) {
    deployer.deploy(IdentityRegistry);
    deployer.deploy(EthereumDIDRegistry);
};
