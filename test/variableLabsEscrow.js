var escrow = artifacts.require("./variableLabsEscrow.sol");
var xToken = artifacts.require("./xToken.sol");

contract('escrow', accounts => {
    var escrowInstance;
    var xTokenInstance;
    it('inits the contract with the correct values', () => {
        return escrow.deployed().then((instance) => {
            escrowInstance = instance;
            return escrowInstance.owner();
        }).then((owner) => {
            assert.equal(owner, accounts[0], 'has correct owner');
            return escrowInstance.tokenAddress();
        }).then((tokenAddress) => {
            assert.equal(tokenAddress, '0x16EB958722991e3685bD113eD958F9872a4533e7', 'has correct token address')
        });
    });

    it('creates an escrow without approved funds', () => {
        return escrow.deployed().then((instance) => {
            escrowInstance = instance;
            // ID is TEST01
            return escrowInstance.createEscrow(
                '',
                100,
                accounts[1],
                0
            );
        }).then(assert.fail).catch((error) => {
            assert(error.message.indexOf('bytes32') >= 0, 'error message must contain invlaid bytes32 value');
            return escrowInstance.createEscrow(
                '0x5d3d87414e6c80b79dca8bfaa44ef284e23969de5f4f1f8dde7337b5f4b3da31',
                100,
                accounts[1],
                20000
            );
        }).then(assert.fail).catch((error) => {
            assert(error.message.indexOf('revert') >= 0, 'error message must contain revert');
            return escrowInstance.createEscrow(
                '0x5d3d87414e6c80b79dca8bfaa44ef284e23969de5f4f1f8dde7337b5f4b3da31',
                100,
                accounts[1],
                0
            );
        }).then(assert.fail).catch((error) => {
            assert(error.message.indexOf('revert') >= 0, 'error message must contain revert as funds not approved');
        });
    });

    it('approves funds', () => {
        return xToken.deployed().then((instance) => {
            xTokenInstance = instance;
            return escrow.deployed(xTokenInstance.address).then((instance) => {
                escrowInstance = instance;
                return xTokenInstance.approve(escrowInstance.address, 100, { from: accounts[0] });
            }).then((receipt) => {
                assert.equal(receipt.logs.length, 1, 'triggers one event');
                assert.equal(receipt.logs[0].event, 'Approval', 'should be the "Approval" event');
                assert.equal(receipt.logs[0].args._owner, accounts[0], 'logs the account the tokens are authorized from');
                assert.equal(receipt.logs[0].args._spender, escrowInstance.address, 'logs the account the tokens are authorized to');
                assert.equal(receipt.logs[0].args._value, 100, 'logs the transfer amount');
                return escrowInstance.createEscrow(
                    '0x5d3d87414e6c80b79dca8bfaa44ef284e23969de5f4f1f8dde7337b5f4b3da31',
                    100,
                    accounts[1],
                    0,
                    { from: accounts[0] }
                );
            }).then((receipt) => {
                console.log(receipt);
            });
        });
    });

});