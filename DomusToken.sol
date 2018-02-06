pragma solidity ^0.4.19;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
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


contract FinalizableToken is ERC20Token, Owned {

    using Math for uint256;
    
    //Public Reserved token address
    address publicReservedAddress;
    
    //board members persentages list
    mapping(address=>uint) boardReservedAccount;
    
    //ICO contract addresss
    FlexibleTokenSale saleToken;
    
    event Burn(address burner,uint256 value);

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
            saleToken.setTotalToken(_value);
        }
        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to, _value);
        //assign total sale token count
        if(address(saleToken) == _to) {
            saleToken.setTotalToken(_value);
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
        
        //check date to allowed tokens 2028/01/01
        if(1830297600 < currentTime()){
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

    //get current time
    function currentTime() public constant returns (uint256) {
        return now;
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
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
    
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        tokenTotalSupply = tokenTotalSupply.sub(_value);
        Burn(burner, _value);
    }
    
}

contract DOCTokenConfig {

    string  public constant TOKEN_SYMBOL      = "DOC";
    string  public constant TOKEN_NAME        = "DOMUSCOINS Token";
    uint8   public constant TOKEN_DECIMALS    = 18;

    uint256 public constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;

    address public constant PUBLIC_RESERVED = 0xbc2cd781169e83AB1Af1ab837f704d545194B52E;
    uint256 public constant PUBLIC_RESERVED_PERSENTAGE = 9000;

    address[] public BOARD_RESERVED = [ 0xc773ca08704EB9C03416c0514945DDeEB74F098A,
        0x9bdB2652f7add45Fdb10D23DD68363DDF09F1550,
        0x6BfefB1D11fFC09041CEE721bd1e3EA6Ac103011,
        0xE2Fe7E2fc2122646a3F5a73a92f6D690B41173EE,
        0xf19bdeAad7D3AEc3A986A97d81Aa66084D65E0f5,
        0xA103c3e2483f63B66dec50239a418115884C9836,
        0xF94Fac0D7062AFA3b7Ec9A3B354485ACE9a3A5CB,
        0x191B2a493FaaC287bCC1D9a5c82D4C294809a91a,
        0xf541869c9b5D2e70eC360bf7Cb6Db09aDa8aa2c3,
        0x75Df6E47ED074314Ca57A4D665B48FD5dE0B41cb];

    uint256[] public BOARD_RESERVED_PERSENTAGE = [2000,2000,2000,1000,1000,500,500,400,300,300];

}

contract DOCToken is FinalizableToken, DOCTokenConfig {

    using Math for uint256;
                   event TokensReclaimed(uint256 _amount);
    uint256 dividendPersentage;

    function DOCToken() public
    FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY, PUBLIC_RESERVED, PUBLIC_RESERVED_PERSENTAGE, BOARD_RESERVED, BOARD_RESERVED_PERSENTAGE)
    {

    }
    
    //get dividend tokens
    function claimDividendTokens() public  returns (bool) {
        uint256 dividendBalance = balanceOf(address(this));
        require(dividendBalance > 0);
        uint256 tokens = balances[msg.sender];
        uint256 dividendToken = tokens.mul(dividendPersentage).div(tokenConversionFactor);
        require(transfer(msg.sender, dividendToken));
        return true;
    }
    
    //set dividend tokens persentage in between 1.00 % to 99.9 %, pass 111 for 1.11 %
    function setDividendPersentage(uint _dividendPersentage) public onlyOwner returns (bool) {
        require(_dividendPersentage >= 100 && _dividendPersentage <= 999);
        dividendPersentage=_dividendPersentage;
        return true;
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

contract FlexibleTokenSale is  Owned, usingOraclize {

    using Math for uint256;

    //
    // Lifecycle
    //
    bool public suspended;

    //
    // Pricing
    //
    uint256 public tokenPrice;
    uint256 public tokenPerEther;
    uint256 public contributionMin;
    uint256 public tokenConversionFactor;

    //
    // Wallets
    //
    address public walletAddress;

    //
    // Token
    //
    FinalizableToken public token;
    uint256 public totalToken;

    //
    // Counters
    //
    uint256 public totalTokensSold;
    uint256 public totalEtherCollected;

    bool public updatePrice = true;

    
    
    //
    // Events
    //
    event Initialized();
    event TokenPriceUpdated(uint256 _newValue);
    event TokenPerEtherUpdated(bytes32 ID,uint256 _newValue);
    event TokenMinUpdated(uint256 _newValue);
    event TotalTokenUpdated(uint256 _newValue);
    event WalletAddressUpdated(address _newAddress);
    event SaleSuspended();
    event SaleResumed();
    event TokensPurchased(address _beneficiary, uint256 _cost, uint256 _tokens);
    event TokensReclaimed(uint256 _amount);


    function FlexibleTokenSale(address _walletAddress) public
    Owned()
    {

        require(_walletAddress != address(0));
        require(_walletAddress != address(this));

        walletAddress = _walletAddress;

        suspended = false;
        tokenPrice = 100;
        tokenPerEther = 70111;
        contributionMin     = 250 * 10**18;
        totalTokensSold     = 0;
        totalEtherCollected = 0;
    }

    // Initialize should be called by the owner as part of the deployment + setup phase.
    // It will associate the sale contract with the token contract and perform basic checks.
    function initialize(FinalizableToken _token) external onlyOwner returns(bool) {
        require(address(token) == address(0));
        require(address(_token) != address(0));
        require(address(_token) != address(this));
        require(address(_token) != address(walletAddress));
        require(isOwner(address(_token)) == false);
        tokenConversionFactor = 10**(uint256(18).sub(_token.decimals()).add(4).add(2));//.add(2)
        require(tokenConversionFactor > 0);
        token = _token;

        Initialized();

        return true;
    }


    //
    // Owner Configuation
    //

    // Allows the owner to change the wallet address which is used for collecting
    // ether received during the token sale.
    function setWalletAddress(address _walletAddress) external onlyOwner returns(bool) {
        require(_walletAddress != address(0));
        require(_walletAddress != address(this));
        require(_walletAddress != address(token));
        require(isOwner(_walletAddress) == false);

        walletAddress = _walletAddress;

        WalletAddressUpdated(_walletAddress);

        return true;
    }
    
    //set token price in between $1.0 to $99.9, pass 111 for $1.11
    function setTokenPrice(uint _tokenPrice) external onlyOwner returns (bool) {
        require(_tokenPrice >= 100 && _tokenPrice <= 999);
        
        tokenPrice=_tokenPrice;
        
        TokenPriceUpdated(_tokenPrice);
        return true;
    }

    function setMinToken(uint256 _minToken) external onlyOwner returns(bool) {
        require(_minToken > 0);

        contributionMin = _minToken;

        TokenMinUpdated(_minToken);

        return true;
    }

    //count total token for sale added in ICO address
    function setTotalToken(uint256 _token) external  returns(bool) {
        require(msg.sender == address(token) && _token > 0);

        totalToken = totalToken.add(_token);

        TokenMinUpdated(_token);

        return true;
    }
    
    function getSoldTokenCount() view external  returns(uint256) {
        return totalTokensSold;
    }

    function getTotalTokenCount() view external  returns(uint256) {
        return totalToken;
    }

    // Allows the owner to suspend the sale until it is manually resumed at a later time.
    function suspend() external onlyOwner returns(bool) {
        if (suspended == true) {
            return false;
        }

        suspended = true;

        SaleSuspended();

        return true;
    }

    // Allows the owner to resume the sale.
    function resume() external onlyOwner returns(bool) {
        if (suspended == false) {
            return false;
        }

        suspended = false;

        SaleResumed();

        return true;
    }


    //
    // Contributions
    //
    
    // Default payable function which can be used to purchase tokens.
    function () payable public {
        buyTokens(msg.sender);
    }


    // Allows the caller to purchase tokens for a specific beneficiary (proxy purchase).
    function buyTokens(address _beneficiary) public payable returns (uint256) {
        require(!suspended);


        require(_beneficiary != address(0));
        require(_beneficiary != address(this));
        require(_beneficiary != address(token));

        // We don't want to allow the wallet collecting ETH to
        // directly be used to purchase tokens.
        require(msg.sender != address(walletAddress));
        
        // Check how many tokens are still available for sale.
        uint256 saleBalance = token.balanceOf(address(this));
        require(saleBalance > 0);
        
        
        return buyTokensInternal(_beneficiary);
    }
    
    function startStopUpdateTokenPerEther(bool _value) public onlyOwner returns(bool){
        updatePrice = _value;
        
        return true;
    }
      
    function updateTokenPerEther() public payable onlyOwner{
        oraclize_query(7200,"URL","json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
    }

    function __callback(bytes32 myid, string result) public  {
        require(msg.sender == oraclize_cbAddress());
        tokenPerEther=stringToUint(result);
        TokenPerEtherUpdated(myid,tokenPerEther);
        if(updatePrice)
            updateTokenPerEther();
    }


    function buyTokensInternal(address _beneficiary) internal returns (uint256) {

        // Calculate how many tokens the contributor could purchase based on ETH received.
        uint256 tokens = msg.value.mul(tokenPerEther).mul(10000).div(tokenConversionFactor);//.div(tokenPrice)
        // require(tokens >= contributionMin);
        
        // This is the actual amount of ETH that can be sent to the wallet.
        uint256 contribution =msg.value;
        walletAddress.transfer(contribution);
        totalEtherCollected = totalEtherCollected.add(contribution);

        // Update our stats counters.
        totalTokensSold = totalTokensSold.add(tokens);

        // Transfer tokens to the beneficiary.
        require(token.transfer(_beneficiary, tokens));

        TokensPurchased(_beneficiary, msg.value, tokens);

        return tokens;
    }



    function getUserTokenBalance(address _beneficiary) internal view returns (uint256) {
        return token.balanceOf(_beneficiary);
    }


    // Allows the owner to take back the tokens that are assigned to the sale contract.
    function reclaimTokens() external onlyOwner returns (bool) {
        uint256 tokens = token.balanceOf(address(this));

        if (tokens == 0) {
            return false;
        }

        address tokenOwner = token.owner();
        require(tokenOwner != address(0));

        totalToken = totalToken.sub(tokens);

        require(token.transfer(tokenOwner, tokens));

        TokensReclaimed(tokens);

        return true;
    }

    //Below function will convert string to integer removing decimal
    function stringToUint(string s) pure internal returns (uint) {
        bytes memory b = bytes(s);
        uint i;
        uint result1 = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if(c == 46)
            {
                // Do nothing --this will skip the decimal
            }
            else if (c >= 48 && c <= 57) {
                result1 = result1 * 10 + (c - 48);
                // usd_price=result;

            }
        }
        return result1;
    }
}

contract DOCTokenSaleConfig {
    address WALLET_ADDRESS = 0xbc2cd781169e83AB1Af1ab837f704d545194B52E;
}

contract DOCTokenSale is FlexibleTokenSale,DOCTokenSaleConfig {

    function DOCTokenSale() public
    FlexibleTokenSale(WALLET_ADDRESS)
    {

    }

}
