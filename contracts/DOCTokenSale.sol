pragma solidity ^0.4.19;

import "./internal/FlexibleTokenSale.sol";
import "./DOCTokenSaleConfig.sol";

contract DOCTokenSale is FlexibleTokenSale, DOCTokenSaleConfig {

    function DOCTokenSale() public
    FlexibleTokenSale(TOKEN_ADDRESS,WALLET_ADDRESS,ETHER_PRICE,UPDATE_PRICE_ADDRESS)
    {

    }

}