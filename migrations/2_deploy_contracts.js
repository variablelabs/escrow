var escrow = artifacts.require("./escrow.sol");

module.exports = function(deployer) {
  deployer.deploy(escrow);
};
