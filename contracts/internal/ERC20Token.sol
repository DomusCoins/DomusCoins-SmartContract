pragma solidity ^0.4.19;

import "./ERC20Interface.sol";
import "./Math.sol";

contract ERC20Token is ERC20Interface {

    using Math for uint256;

    string  private tokenName;
    string  private tokenSymbol;
    uint8   private tokenDecimals;
    uint256 internal tokenTotalSupply;
    uint256 publicReservedToken;
    uint256 tokenConversionFactor = 10**(4);
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) allowed;


    function ERC20Token(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply,address _publicReserved,uint256 _publicReservedPersentage,address[] boardReserved,uint256[] boardReservedPersentage) public {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        tokenTotalSupply = _totalSupply;

        // The initial Public Reserved balance of tokens is assigned to the given token holder address.
        // 90 persentage tokens assign to public reserved  holder
        publicReservedToken = _totalSupply.mul(uint256(_publicReservedPersentage)).div(tokenConversionFactor);
        balances[_publicReserved] = publicReservedToken;

        //10 persentage token available for board members
        uint256 boardReservedToken = _totalSupply.sub(publicReservedToken);

        // Per EIP20, the constructor should fire a Transfer event if tokens are assigned to an account.
        Transfer(0x0, _publicReserved, publicReservedToken);

        // The initial Board Reserved balance of tokens is assigned to the given token holder address.
        for(uint i=0; i<boardReserved.length; i++){
            //assigning board members persentage tokens to particular board member address.
            uint256 token = boardReservedToken.mul(uint256(boardReservedPersentage[i])).div(tokenConversionFactor);
            balances[boardReserved[i]] = token;
            Transfer(0x0, boardReserved[i], token);
        }

    }


    function name() public view returns (string) {
        return tokenName;
    }


    function symbol() public view returns (string) {
        return tokenSymbol;
    }


    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }


    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);

        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }
}
