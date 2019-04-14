var escrow = artifacts.require("./variableLabsEscrow.sol");
// var xToken = artifacts.require("./xToken.sol");

module.exports = function(deployer) {
  deployer.deploy(escrow, '0xA75da4Bebe87f2F3CE8dC40A5B8C4B3fE8601835');
  // deployer.deploy(xToken, 10000000);
};
