pragma solidity ^0.4.19;

import "./ERC20Token.sol";
import "./Owned.sol";
import "./SafeMath.sol";
import "./FlexibleTokenSale.sol";

contract FinalizableToken is ERC20Token, Owned {

    using SafeMath for uint256;


    /**
         * @dev Call publicReservedAddress - library function exposed for testing.
    */
    address public publicReservedAddress;

    //board members persentages list
    mapping(address=>uint) private boardReservedAccount;

    //ICO contract addresss
    FlexibleTokenSale saleToken;

    event Burn(address indexed burner,uint256 value);

    // The constructor will assign the initial token supply to the owner (msg.sender).
    function FinalizableToken(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply,address _publicReserved,uint256 _publicReservedPersentage,address[] _boardReserved,uint256[] _boardReservedPersentage) public
    ERC20Token(_name, _symbol, _decimals, _totalSupply, _publicReserved, _publicReservedPersentage, _boardReserved, _boardReservedPersentage)
    Owned(){
        publicReservedAddress = _publicReserved;
        for(uint i=0; i<_boardReserved.length; i++){
            boardReservedAccount[_boardReserved[i]] = balances[_boardReserved[i]];
        }
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to,_value);
        //assign total sale token count
        if(address(saleToken) == _to) {
            saleToken.addTotalToken(_value);
        }
        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to, _value);
        //assign total sale token count
        if(address(saleToken) == _to) {
            saleToken.addTotalToken(_value);
        }
        return super.transferFrom(_from, _to, _value);
    }


    function validateTransfer(address _sender, address _to, uint256 _value) private view {
        //check null address
        require(_to != address(0));

        //check saleToken address
        require(address(saleToken) != address(0));

        //Only ICO address can send tokens to publicReservedAddress other then not allowed
        require(address(saleToken) == _sender || publicReservedAddress != _to);

        //check board member address
        uint256 allowed = boardReservedAccount[_sender];
        if (allowed == 0) {
            //if not then return and allow for transfer
            return;
        }

        // if yes then check allowed token for board member
        require(getBoardMemberAllowedToken(allowed)>=_value);


    }

    function getBoardMemberAllowedToken(uint allowed) internal constant returns (uint256) {

        //check public reserved address tokens
        uint256 publicReservedRemaining = balances[publicReservedAddress];

        //total token allocated in ICO address
        uint256 icoToken = saleToken.getTotalTokenCount();

        //total sold token
        uint256 publicSoldToken = saleToken.getSoldTokenCount();

        //get remainToken count of public reserved address
        publicReservedRemaining = publicReservedRemaining.add(icoToken).sub(publicSoldToken);

        //count persentage for remainTokens
        uint256 publicReservedSoldPersentage = publicReservedRemaining.mul(10000).div(publicReservedToken);

        //and allowed that persentage tokens to board member
        uint256 remainToken = allowed.mul(publicReservedSoldPersentage).div(tokenConversionFactor);
        uint256 allowedToken = allowed.sub(remainToken);

        //return allowedToken
        return allowedToken;
    }

    //set ICO address
    function setICOAddress(FlexibleTokenSale _saleToken) public onlyOwner returns (bool) {
        require(address(_saleToken) != address(0));
        require(address(_saleToken) != address(this));
        saleToken = _saleToken;
        return true;
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

}