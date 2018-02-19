/**
 * Created by smartSense on 17/02/18.
 */
var DOCToken = artifacts.require("./DOCToken.sol");
var DOCTokenSale = artifacts.require("./DOCTokenSale.sol");

module.exports = function(deployer) {
    deployer.deploy(DOCToken);
    deployer.deploy(DOCTokenSale);
};
