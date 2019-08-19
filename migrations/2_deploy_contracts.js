const IdentityRegistry = artifacts.require("IdentityRegistry");
const EthereumDIDRegistry = artifacts.require("EthereumDIDRegistry");
const AddressSet = artifacts.require("AddressSet");
const ERC1056Resolver = artifacts.require("ERC1056");

module.exports = function(deployer) {
	deployer.deploy(AddressSet);
	deployer.link(AddressSet, IdentityRegistry);
    deployer.deploy(IdentityRegistry);
    deployer.deploy(EthereumDIDRegistry);
    deployer.deploy(ERC1056Resolver, IdentityRegistry.address, EthereumDIDRegistry.address);
};
