pragma solidity ^0.4.19;

import "./internal/FlexibleTokenSale.sol";
import "./DOCTokenSaleConfig.sol";

contract DOCTokenSale is FlexibleTokenSale, DOCTokenSaleConfig {

    function DOCTokenSale() public
    FlexibleTokenSale(WALLET_ADDRESS,TOKEN_PER_TOKEN)
    {

    }

}