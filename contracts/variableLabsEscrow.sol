pragma solidity 0.5.0;

/**
@dev Contract for 'Escrow'
Used as an escrow service.
@author https://github.com/parthvshah
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	/**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);
		return c;
    }
}

contract Token{
	function transfer(address _to, uint256 _value) public returns(bool success);
	function approve(address _spender, uint256 _value) public returns(bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
}

contract variableLabsEscrow{
    using SafeMath for uint256;

    /**
    @dev Modifier for protecting functions
    @param _address 
    The function is executed only if the sender address is the same as _address
    */
    modifier onlyBy(address _address) {
		require(msg.sender == _address, "forbidden request");
		_;
    }

    /**
    @dev Owner and creation time
    The address of the owner is stored with the time of creation of the contract.
    */
    address payable public owner;
    uint public creationTime;

	address public tokenAddress;

	/**
    @dev Escrow structure 
    Stores the funds in Tokens, addresses of the depositer, receiver, resolver fees and state.
	States:
	0 - Active
	1 - Approved
	2 - Cancelled
	3 - Disputed: By depositer
	4 - Disputed: By receiver
	5 - Resolved: In favor of depositer
	6 - Resolved: In favor of receiver
    */
	struct Escrow{
		uint256 funds;
		address depositer;
		address receiver;
		address resolver;
		uint8 fee;
		uint8 state;
		bool exists;
	}

	event Creation(
		bytes32 indexed _id
	);

	mapping (bytes32 => Escrow) public escrow;

	constructor(address _tokenAddress) public {
		owner = msg.sender;
		creationTime = now;
		tokenAddress = _tokenAddress;
	}
	
	function createEscrow(bytes32 _id, uint256 _funds, address _receiver, address _resolver, uint8 _fee) public returns(bool success){		
		require((_fee >= 0) && (_fee <= 10000), "fee must be a percentage");
		if(escrow[_id].exists) 
			revert("escrow exists");

		Escrow memory currentEscrow;
		currentEscrow.funds = _funds;
		currentEscrow.depositer = msg.sender;
		currentEscrow.receiver = _receiver;
		currentEscrow.resolver = _resolver;
		currentEscrow.fee = _fee;
		currentEscrow.state = uint8(0);
		currentEscrow.exists = true;

		// Sender must approve this contract to spend Token
		Token(tokenAddress).transferFrom(msg.sender, address(this), _funds);

		escrow[_id] = currentEscrow;
		emit Creation(_id);
		return true;
	}

	function approveEscrow(bytes32 _id) public returns(bool success){
		if(!escrow[_id].exists) 
			revert("escrow does not exist");
		require(escrow[_id].depositer == msg.sender, "only by depositer");
		require(escrow[_id].state == uint8(0), "escrow must be active");

		Token(tokenAddress).transfer(escrow[_id].receiver, escrow[_id].funds);

		uint256 _feeAmount = escrow[_id].funds.mul(uint256(escrow[_id].fee));
		_feeAmount = _feeAmount.div(uint256(10000));
		Token(tokenAddress).transfer(escrow[_id].resolver, _feeAmount);

		escrow[_id].state = uint8(1);

		return true;
	}

	function cancelEscrow(bytes32 _id) public returns(bool success){
		if(!escrow[_id].exists) 
			revert("escrow does not exist");
		require(escrow[_id].receiver == msg.sender, "only by receiver");
		require(escrow[_id].state == uint8(0), "escrow must be active");
		

		Token(tokenAddress).transfer(escrow[_id].depositer, escrow[_id].funds);

		uint256 _feeAmount = escrow[_id].funds.mul(uint256(escrow[_id].fee));
		_feeAmount = _feeAmount.div(uint256(10000));
		Token(tokenAddress).transfer(escrow[_id].resolver, _feeAmount);

		escrow[_id].state = uint8(2);

		return true;
	}

	function raiseDispute(bytes32 _id) public returns(bool success){
		if(!escrow[_id].exists) 
			revert("escrow does not exist");
		require((escrow[_id].depositer == msg.sender) || (escrow[_id].receiver == msg.sender), "only by depositer or receiver");
		require(escrow[_id].state == uint8(0), "escrow must be active");

		if(msg.sender == escrow[_id].depositer){
			escrow[_id].state = uint8(3);
		}
		if(msg.sender == escrow[_id].receiver){
			escrow[_id].state = uint8(4);
		}

		return true;
	}

	function resolveDispute(bytes32 _id, uint8 _decision) public returns (bool success){
		if(!escrow[_id].exists) 
			revert("escrow does not exist");
		require((escrow[_id].state == uint8(3)) || (escrow[_id].state == uint8(4)), "escrow should be disputed");
		require((_decision == uint8(0)) || (_decision == uint8(1)), "decision has to be in favor of depositer or receiver");

		uint256 _feeAmount = escrow[_id].funds.mul(uint256(escrow[_id].fee));
		_feeAmount = _feeAmount.div(uint256(10000));
		Token(tokenAddress).transfer(escrow[_id].resolver, _feeAmount);

		// Funds go to depositer
		if(_decision == uint8(0)){
			Token(tokenAddress).transfer(escrow[_id].depositer, escrow[_id].funds);

			escrow[_id].state = uint8(5);
			return true;
		}
		// Funds go to receiver
		if(_decision == uint8(1)){
			Token(tokenAddress).transfer(escrow[_id].receiver, escrow[_id].funds);

			escrow[_id].state = uint8(6);
			return true;
		}

	}
	function killContract() public onlyBy(owner){
		selfdestruct(owner);
	}

}