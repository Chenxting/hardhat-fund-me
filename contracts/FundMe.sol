// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner(); // error声明在合约之外

/**
 * @title A contract for crowd funding
 * @author Chenny
 * @notice This contract is to demmo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256; // uint256 use PriceConverter as a library

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner; // 一行就可以设置的常量
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18; // 需要在构造函数里设置的常量
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // 修饰器
        // require(msg.sender == owner); //消耗的gas比error-revert多
        if (msg.sender != i_owner) revert FundMe__NotOwner(); // 只有募集资金的人(合约的调用者)能够提款
        _; // 运行余下的代码 ，此处代表的就是withdraw函数
    }

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    // what happens if someone sends this contract ETH without calling the fund function?
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        // 修饰器，在运行withdraw()之前，必须先运行修饰器函数
        // 1.reset the mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // 2.reset the array
        s_funders = new address[](0);
        // 3.actually withdraw the funds
        /* 3.1 transfer 
            3.1.1
            msg.sender = address
            payable(msg.sender) = payable address // 自动回滚交易
            3.1.2 把想要发送到的目标地址放到payable关键字里，
                  msg.sender是合约调用者，address(this)是合约地址，
                  即将合约中的余额address(this).balance发送到合约调用者msg.sender中。
            payable(msg.sender).transfer(address(this).balance);
           3.2 send
            bool sendSuccess = payable(msg.sender).send(address(this).balance);
            require(sendSuccess, "Send failed"); // 手动回滚交易
           3.3 call 最推荐，没有gas上限*/
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed"); // 手动回滚交易
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mapping cant't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
