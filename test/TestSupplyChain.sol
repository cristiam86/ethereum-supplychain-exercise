pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./Proxy.sol";

contract TestSupplyChain {
    string name = "book";
    uint256 price = 1000;
    uint256 sku = 0;

    SupplyChain public chain;
    Proxy public sellActor;
    Proxy public buyActor;

    // allow contract to receive ether
    function() external payable {}

    function beforeEach() public
    {
        // Contract to test
        chain = new SupplyChain();

        // Sell transaction actor
        sellActor = new Proxy(chain);

        // Buy transaction actor
        buyActor = new Proxy(chain);

        // Seed buyer with some funds
        // Note: these values are in wei
        uint256 seedValue = price + 1;
        address(buyActor).send(seedValue);

        // Seed known item to set contract to `for-sale`
        sellActor.placeItemForSale(name, price);
    }
    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    // buyItem

    // test for failure if user does not send enough funds
    function testNotEnoughFunds() public  {
        bool result = buyActor.purchaseItem(sku, price - 1);
        Assert.isFalse(result, "buyer did not send enough funds");
    }
    // test for purchasing an item that is not for Sale
    function testPurchasingNotForSaleItem() public  {
        buyActor.purchaseItem(sku, price);
        bool result = buyActor.purchaseItem(sku, price);
        Assert.isFalse(result, "item is not for sale");
    }

    // shipItem

    // test for calls that are made by not the seller
    function testShipingByBuyerIsForbidden() public  {
        buyActor.purchaseItem(sku, price);
        bool result = buyActor.shipItem(sku);
        Assert.isFalse(result, "buyer can not ship item");
    }

    // test for trying to ship an item that is not marked Sold
    function testCanNotShipAnItemNotSold() public  {
        bool result = sellActor.shipItem(sku);
        Assert.isFalse(result, "seller can not ship an item that has not been sold");
    }

    // receiveItem

    // test calling the function from an address that is not the buyer
    function testReceivingBySellerIsForbidden() public  {
        buyActor.purchaseItem(sku, price);
        sellActor.shipItem(sku);
        bool result = sellActor.receiveItem(sku);
        Assert.isFalse(result, "item must be received by buyer");
    }

    // test calling the function on an item not marked Shipped
    function testCanNotReceiveNotShippedItem() public  {
        buyActor.purchaseItem(sku, price);
        bool result = buyActor.receiveItem(sku);
        Assert.isFalse(result, "item is not Shipped");
    }
}
