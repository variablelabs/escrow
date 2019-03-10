var escrow = artifacts.require("./variableLabsEscrow.sol");

contract('escrow', accounts => {
    var escrowInstance;
    it('inits the contract with the correct values', () => {
        return escrow.deployed().then((instance) => {
            escrowInstance = instance;
            return escrowInstance.owner();
        }).then((owner) => {
            assert.equal(owner, accounts[0], 'has correct owner');
            return escrowInstance.resolver();
        }).then((resolver) => {
            assert.equal(resolver, accounts[0], 'has correct resolver');
            return escrowInstance.tokenAddress();
        }).then((tokenAddress) => {
            assert.equal(tokenAddress, '0x854880dB37EEb4feE281933006440FdB607c576f', 'has correct token address')
        });
    });
    
});