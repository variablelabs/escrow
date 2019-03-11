var escrow = artifacts.require("./variableLabsEscrow.sol");
var xToken = artifacts.require("./xToken.sol");

module.exports = function(deployer) {
  deployer.deploy(escrow, '0x4EF7989116c7C8938241054728ac46e6807a3249');
  deployer.deploy(xToken, 10000000);
};
