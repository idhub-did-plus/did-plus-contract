const IdentityRegistry = artifacts.require("IdentityRegistry");
const EthereumDIDRegistry = artifacts.require("EthereumDIDRegistry");
const AddressSet = artifacts.require("AddressSet");
const ERC1056Resolver = artifacts.require("ERC1056");

module.exports = function(deployer) {
	deployer.deploy(AddressSet);
	deployer.link(AddressSet, IdentityRegistry);
    deployer.deploy(IdentityRegistry);
    deployer.deploy(EthereumDIDRegistry);
    deployer.deploy(ERC1056Resolver, IdentityRegistry.address, EthereumDIDRegistry.address).then(
    	function (r) {
    		console.log("IdentityRegistry Address is" + IdentityRegistry.address);
    		console.log("EthereumDIDRegistry Address is" + EthereumDIDRegistry.address);
    		console.log("ERC1056Resolver Address is" + ERC1056Resolver.address);
    	});
};
