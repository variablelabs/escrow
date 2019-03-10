var escrow = artifacts.require("./variableLabsEscrow.sol");

module.exports = function(deployer) {
  deployer.deploy(escrow, '0x854880dB37EEb4feE281933006440FdB607c576f');
};
