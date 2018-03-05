pragma solidity ^0.4.19;

import "./ERC20Token.sol";
import "./Owned.sol";
import "./SafeMath.sol";

contract FinalizableToken is ERC20Token, Owned {

    using SafeMath for uint256;


    /**
         * @dev Call publicReservedAddress - library function exposed for testing.
    */
    address public publicReservedAddress;

    //board members time list
    mapping(address=>uint) private boardReservedAccount;
    uint256[] public BOARD_RESERVED_YEARS = [1 years,2 years,3 years,4 years,5 years,6 years,7 years,8 years,9 years,10 years];

    event Burn(address indexed burner,uint256 value);

    // The constructor will assign the initial token supply to the owner (msg.sender).
    function FinalizableToken(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply,address _publicReserved,uint256 _publicReservedPersentage,address[] _boardReserved,uint256[] _boardReservedPersentage) public
    ERC20Token(_name, _symbol, _decimals, _totalSupply, _publicReserved, _publicReservedPersentage, _boardReserved, _boardReservedPersentage)
    Owned(){
        publicReservedAddress = _publicReserved;
        for(uint i=0; i<_boardReserved.length; i++){
            boardReservedAccount[_boardReserved[i]] = currentTime() + BOARD_RESERVED_YEARS[i];
        }
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(validateTransfer(msg.sender, _to));
        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(validateTransfer(msg.sender, _to));
        return super.transferFrom(_from, _to, _value);
    }


    function validateTransfer(address _sender, address _to) private view returns(bool) {
        //check null address
        require(_to != address(0));

        //check board member address
        uint256 time = boardReservedAccount[_sender];
        if (time == 0) {
            //if not then return and allow for transfer
            return true;
        }else{
            // else  then check allowed token for board member
            return currentTime() > time;
        }
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);


        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        tokenTotalSupply = tokenTotalSupply.sub(_value);
        Burn(burner, _value);
    }

    //get current time
    function currentTime() public constant returns (uint256) {
        return now;
    }

}