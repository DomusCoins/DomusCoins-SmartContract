pragma solidity ^0.4.19;
library Math {

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 r = a + b;

      require(r >= a);

      return r;
   }


   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(a >= b);

      return a - b;
   }


   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 r = a * b;

      require(a == 0 || r / a == b);

      return r;
   }


   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
   }
}

// ----------------------------------------------------------------------------
// Based on the final ERC20 specification at:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {

   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   function name() public view returns (string);
   function symbol() public view returns (string);
   function decimals() public view returns (uint8);
   function totalSupply() public view returns (uint256);

   function balanceOf(address _owner) public view returns (uint256 balance);
   function allowance(address _owner, address _spender) public view returns (uint256 remaining);

   function transfer(address _to, uint256 _value) public returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
   function approve(address _spender, uint256 _value) public returns (bool success);
}

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
        
        publicReservedToken = _totalSupply.mul(uint256(_publicReservedPersentage)).div(tokenConversionFactor);
        uint256 boardReservedToken = _totalSupply.sub(publicReservedToken);
        // The initial balance of tokens is assigned to the given token holder address.
        balances[_publicReserved] = publicReservedToken;

        // Per EIP20, the constructor should fire a Transfer event if tokens are assigned to an account.
        Transfer(0x0, _publicReserved, publicReservedToken);
        
        for(uint i=0; i<boardReserved.length; i++){
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

contract Owned {

   address public owner;
   address public proposedOwner;

   event OwnershipTransferInitiated(address indexed _proposedOwner);
   event OwnershipTransferCompleted(address indexed _newOwner);
   event OwnershipTransferCanceled();


   function Owned() public
   {
      owner = msg.sender;
   }


   modifier onlyOwner() {
      require(isOwner(msg.sender) == true);
      _;
   }


   function isOwner(address _address) public view returns (bool) {
      return (_address == owner);
   }


   function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
      require(_proposedOwner != address(0));
      require(_proposedOwner != address(this));
      require(_proposedOwner != owner);

      proposedOwner = _proposedOwner;

      OwnershipTransferInitiated(proposedOwner);

      return true;
   }


   function cancelOwnershipTransfer() public onlyOwner returns (bool) {
      if (proposedOwner == address(0)) {
         return true;
      }

      proposedOwner = address(0);

      OwnershipTransferCanceled();

      return true;
   }


   function completeOwnershipTransfer() public returns (bool) {
      require(msg.sender == proposedOwner);

      owner = msg.sender;
      proposedOwner = address(0);

      OwnershipTransferCompleted(owner);

      return true;
   }
}


//
// Implements a security model with owner and ops.
//
contract OpsManaged is Owned {

   address public opsAddress;

   event OpsAddressUpdated(address indexed _newAddress);


   function OpsManaged() public
      Owned()
   {
   }


   modifier onlyOwnerOrOps() {
      require(isOwnerOrOps(msg.sender));
      _;
   }


   function isOps(address _address) public view returns (bool) {
      return (opsAddress != address(0) && _address == opsAddress);
   }


   function isOwnerOrOps(address _address) public view returns (bool) {
      return (isOwner(_address) || isOps(_address));
   }


   function setOpsAddress(address _newOpsAddress) public onlyOwner returns (bool) {
      require(_newOpsAddress != owner);
      require(_newOpsAddress != address(this));

      opsAddress = _newOpsAddress;

      OpsAddressUpdated(opsAddress);

      return true;
   }
}

contract FinalizableToken is ERC20Token, OpsManaged {

   using Math for uint256;
   mapping(address=>uint) boardReservedAccount;


   // The constructor will assign the initial token supply to the owner (msg.sender).
   function FinalizableToken(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply,address _publicReserved,uint256 _publicReservedPersentage,address[] _boardReserved,uint256[] _boardReservedPersentage) public
      ERC20Token(_name, _symbol, _decimals, _totalSupply, _publicReserved, _publicReservedPersentage, _boardReserved, _boardReservedPersentage)
      OpsManaged(){
        for(uint i=0; i<_boardReserved.length; i++){
            boardReservedAccount[_boardReserved[i]] = balances[_boardReserved[i]];   
        }  
   }


   function transfer(address _to, uint256 _value) public returns (bool success) {
      validateTransfer(msg.sender, _to,_value);

      return super.transfer(_to, _value);
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      validateTransfer(msg.sender, _to, _value);

      return super.transferFrom(_from, _to, _value);
   }


   function validateTransfer(address _sender, address _to, uint256 _value) private view {
    require(_to != address(0));
    require(!isOwner(_to));

    
    uint256 allowed = boardReservedAccount[_sender];
    
    if (allowed == 0) {
         return;
    }
    
    //calculation
    uint256 publicReservedRemaining = balances[owner];
    uint256 publicReservedSoldPersentage = publicReservedRemaining.mul(10000).div(publicReservedToken);
    uint256 remainToken = allowed.mul(publicReservedSoldPersentage).div(tokenConversionFactor);
    uint256 allowedToken = allowed.sub(remainToken);
    require(allowedToken>=_value);
    //  

   }
}


contract DOCTokenConfig {

    string  public constant TOKEN_SYMBOL      = "ABC";
    string  public constant TOKEN_NAME        = "ABC Token";
    uint8   public constant TOKEN_DECIMALS    = 18;

    uint256 public constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
    
    address public constant PUBLIC_RESERVED = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
    uint256 public constant PUBLIC_RESERVED_PERSENTAGE = 9000;
    
    address[] public BOARD_RESERVED = [ 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c,
                                        0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db,
                                        0x583031d1113ad414f02576bd6afabfb302140225,
                                        0xdd870fa1b7c4700f2bd7f44238821c26f7392148,
                                        0xEdEe789Eda59c4387055572a76A92FE4f67D0fa0 ];
    
    uint256[] public BOARD_RESERVED_PERSENTAGE = [2000,2000,2000,1000,1000,500,500,400,300,300];
    
}

contract DOCToken is FinalizableToken, DOCTokenConfig {

   using Math for uint256;
   event TokensReclaimed(uint256 _amount);


   function DOCToken() public
      FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY, PUBLIC_RESERVED, PUBLIC_RESERVED_PERSENTAGE, BOARD_RESERVED, BOARD_RESERVED_PERSENTAGE)
   {
       
   }


   // Allows the owner to reclaim tokens that have been sent to the token address itself.
   function reclaimTokens() public onlyOwner returns (bool) {

      address account = address(this);
      uint256 amount  = balanceOf(account);

      if (amount == 0) {
         return false;
      }

      balances[account] = balances[account].sub(amount);
      balances[owner] = balances[owner].add(amount);

      Transfer(account, owner, amount);

      TokensReclaimed(amount);

      return true;
   }
}
