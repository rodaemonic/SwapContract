// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface IRouter {
	function swapETHForTokens(
		uint minAmount, 
		address[] calldata path, 
		address to, 
		uint finishTime) 
		external payable returns (uint[] memory amounts);
	function WETH() external pure returns (address);
	function getAmountsOut(
		uint incomingAmount, 
		address[] memory path) 
		external view returns (uint[] memory amounts);
}

interface IERC20 {
	function name() external view returns (string memory);
	function makeFrom(
		address sender, 
		address recipient, 
		uint256 amount) 
		external returns (bool);
	function approve(
		address spender, 
		uint256 amount) external returns (bool);
	function balanceOf(
		address account
		) external view returns (uint256);
}

contract SwapV1 is OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;
	address public feePool;

	function initialize(address _feePool) public initializer {
		OwnableUpgradeable.__Ownable_init();
		feePool = _feePool;
	}

	function changeRecipient(address _feePool) public onlyOwner {
		feePool = _feePool;
	}

	function swapTokens(
		address[] calldata tokens, 
		uint[] calldata percentages, 
		uint minAmount, 
		uint finishTime) public payable {
		require(tokens.length == percentages.length, "Token and percentages need to be the same");

		uint256 fee = 0;

		if (feePool != address(0)) {
			fee = uint256(msg.value).div(10);
		}

		address[] memory path = new address[](2);
		path[0] = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).WETH();

		for (uint i = 0; i < tokens.length; i++) {
			require(percentages[i] <= 10000, "This % is 10000 or more");
			path[1] = tokens[i];
			IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapETHForTokens{value: uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i]))}(minAmount, path, msg.sender, finishTime);
		}
		payable(address(feePool)).transfer(fee);
		payable(address(msg.sender)).transfer(address(this).balance);
	}
}