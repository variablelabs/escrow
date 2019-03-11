var escrow = artifacts.require("./variableLabsEscrow.sol");
var xToken = artifacts.require("./xToken.sol");

module.exports = function(deployer) {
  deployer.deploy(escrow, '0x16EB958722991e3685bD113eD958F9872a4533e7');
  deployer.deploy(xToken, 10000000);
};
