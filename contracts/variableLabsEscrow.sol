pragma solidity ^0.5.0;

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
		require(msg.sender == _address, 'forbidden request');
		_;
    }

    /**
    @dev Owner and creation time
    The address of the owner is stored with the time of creation of the contract.
    */
    address payable public owner;
    uint public creationTime;

	address public resolver;
	address public tokenAddress;

	/**
    @dev Escrow structure 
    Stores the funds in xTokens, addresses of the depositer, receiver, resolver fees and state.
	States:
	0 - Active
	1 - Approved
	2 - Cancelled
	3 - Disputed
	4 - Resolved: In favor of depositer
	5 - Resolved: In favor of receiver
    */
	struct Escrow{
		uint256 funds;
		address depositer;
		address receiver;
		uint8 fee;
		uint8 state;
	}

	event Creation(
		bytes32 indexed _id
	);

	mapping (bytes32 => Escrow) public escrow;

	constructor(address _tokenAddress) public {
		owner = msg.sender;
		creationTime = now;
		resolver = msg.sender;
		tokenAddress = _tokenAddress;
	}
	
	function createEscrow(bytes32 _id, uint256 _funds, address _receiver, uint8 _fee) public returns(bool success){
		require(_receiver != address(this), "this contract can't receive funds");

		Escrow memory currentEscrow;
		currentEscrow.funds = _funds;
		currentEscrow.depositer = msg.sender;
		currentEscrow.receiver = _receiver;
		currentEscrow.fee = _fee;

		// Sender must approve this contract to spend token
		Token(tokenAddress).transferFrom(msg.sender, address(this), _funds);

		escrow[_id] = currentEscrow;

		emit Creation(_id);
		return true;
	}

}