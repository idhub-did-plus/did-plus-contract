const Migrations = artifacts.require("Migrations");

console.log(artifacts);

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
