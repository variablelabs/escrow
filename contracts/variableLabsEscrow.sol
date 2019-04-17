pragma solidity 0.5.7;

/**
@dev Contract for escrowing xToken
Used as an escrow service. Configirable to any ERC-20 token.
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
/**
@dev Token contract
Used to transfer, transferFrom ERC-20 tokens
*/
contract Token{
	function transfer(address _to, uint256 _value) public returns(bool success);
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

	/**
    @dev Address to an ERC-20 token for transfer, transferToken functionality
    */
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
		uint256 fee;
		uint256 state;
		bool exists;
	}

	/**
    @dev Event to log the creation of an escrow
	Logs the unique ID that is used to identify an escrow. Can be queried to obtain additional escrow details.
    */
	event Creation(
		bytes32 indexed _id
	);

	/**
    @dev Maps a unique ID to an escrow with additional details.
    */
	mapping (bytes32 => Escrow) public escrow;

	/**
    @dev Constructor for the contract.
	@param _tokenAddress 
	Sets up the owner, creation time and token address of the ERC-20 token.
    */
	constructor(address _tokenAddress) public {
		owner = msg.sender;
		creationTime = now;
		tokenAddress = _tokenAddress;
	}
	
	/**
    @dev Create an escrow.
	@param _id @param _funds @param _receiver @param _resolver @param _fee 
	Creates an escrow using the unique ID. Sets the funds, receiver, resolver and a fee in percentage. Sets the state of the escrow.
	It transfers the funds, creates an escrow and emits an event.
    */
	function createEscrow(bytes32 _id, uint256 _funds, address _receiver, address _resolver, uint256 _fee) public returns(bool success){		
		require((_fee >= 0) && (_fee <= 10000), "fee must be a percentage");
		if(escrow[_id].exists) 
			revert("escrow exists");

		Escrow memory currentEscrow;
		currentEscrow.funds = _funds;
		currentEscrow.depositer = msg.sender;
		currentEscrow.receiver = _receiver;
		currentEscrow.resolver = _resolver;

		// Sender must approve this contract to spend the said amount of funds+fees before it can be transfered.
		uint256 _feeAmount = _funds.mul(_fee);
		_feeAmount = _feeAmount.div(10000);

		currentEscrow.fee = _feeAmount;
		currentEscrow.state = 0;
		currentEscrow.exists = true;

		uint256 _total = _funds.add(_feeAmount);
		Token(tokenAddress).transferFrom(msg.sender, address(this), _total);

		escrow[_id] = currentEscrow;
		emit Creation(_id);
		return true;
	}

	/**
    @dev Depositer approves an escrow.
	@param _id 
	Transfers funds to the receiver in the escrow, transfers the fee to the resolver and changes the state of the escrow.
    */
	function approveEscrow(bytes32 _id) public returns(bool success){
		if(!escrow[_id].exists) 
			revert("escrow does not exist");
		require(escrow[_id].depositer == msg.sender, "only by depositer");
		require(escrow[_id].state == 0, "escrow must be active");

		Token(tokenAddress).transfer(escrow[_id].receiver, escrow[_id].funds);
		Token(tokenAddress).transfer(escrow[_id].resolver, escrow[_id].fee);

		escrow[_id].state = 1;

		return true;
	}

	/**
    @dev Reciever cancels an escrow.
	@param _id 
	Transfers funds to the depositer in the escrow, transfers the fee to the resolver and changes the state of the escrow.
    */
	function cancelEscrow(bytes32 _id) public returns(bool success){
		if(!escrow[_id].exists) 
			revert("escrow does not exist");
		require(escrow[_id].receiver == msg.sender, "only by receiver");
		require(escrow[_id].state == 0, "escrow must be active");
		

		Token(tokenAddress).transfer(escrow[_id].depositer, escrow[_id].funds);
		Token(tokenAddress).transfer(escrow[_id].resolver, escrow[_id].fee);

		escrow[_id].state = 2;

		return true;
	}

	/**
    @dev Depositer or receiver raises a dispute.
	@param _id 
	Transfers funds to the receiver in the escrow, transfers the fee to the resolver and changes the state of the escrow.
    */
	function raiseDispute(bytes32 _id) public returns(bool success){
		if(!escrow[_id].exists) 
			revert("escrow does not exist");
		require((escrow[_id].depositer == msg.sender) || (escrow[_id].receiver == msg.sender), "only by depositer or receiver");
		require(escrow[_id].state == 0, "escrow must be active");

		if(msg.sender == escrow[_id].depositer){
			escrow[_id].state = 3;
		}
		if(msg.sender == escrow[_id].receiver){
			escrow[_id].state = 4;
		}

		return true;
	}

	/**
    @dev Resolver resolves a dispute. 
	@param _id @param _decision
	Resolver resolves a disputed contract in either direction. Funds and fees are transferred.
    */
	function resolveDispute(bytes32 _id, uint256 _decision) public returns (bool success){
		if(!escrow[_id].exists) 
			revert("escrow does not exist");
		require(escrow[_id].resolver == msg.sender, "only by resolver");
		require((escrow[_id].state == 3) || (escrow[_id].state == 4), "escrow should be disputed");
		require((_decision == 0) || (_decision == 1), "decision has to be in favor of depositer or receiver");

		Token(tokenAddress).transfer(escrow[_id].resolver, escrow[_id].fee);

		// Funds go to depositer
		if(_decision == 0){
			Token(tokenAddress).transfer(escrow[_id].depositer, escrow[_id].funds);

			escrow[_id].state = 5;
		}
		// Funds go to receiver
		if(_decision == 1){
			Token(tokenAddress).transfer(escrow[_id].receiver, escrow[_id].funds);

			escrow[_id].state = 6;
		}
		else{
			return false;
		}
		return true;

	}

	/**
    @dev Destroys a contract
	Temporary functionality.
    */
	function killContract() public onlyBy(owner){
		selfdestruct(owner);
	}

}