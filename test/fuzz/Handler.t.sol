// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
contract Handler is Test{
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dsce,DecentralizedStableCoin _dsc){
        dsce=_dsce;
        dsc=_dsc;
          address[]  memory  collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }
     
 // Helper Functions
function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock){
    if(collateralSeed % 2 == 0){
        return weth;
    }
    return wbtc;
}
function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
  
    amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
    ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);

    // mint and approve!
    vm.startPrank(msg.sender);
    collateral.mint(msg.sender, amountCollateral);
    collateral.approve(address(dsce), amountCollateral);

    dsce.depositCollateral(address(collateral), amountCollateral);
    vm.stopPrank();
}
function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
    ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
    uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(address(collateral), msg.sender);

    amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);
    if(amountCollateral == 0){
        return;
    }

    dsce.redeemCollateral(address(collateral), amountCollateral);
}
function mintDsc(uint256 amount) public {
    (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(msg.sender);

    uint256 maxDscToMint = (collateralValueInUsd / 2) - totalDscMinted;
    if(maxDscToMint < 0){
        return;
    }

    amount = bound(amount, 0, maxDscToMint);
    if(amount < 0){
        return;
    }

    vm.startPrank(msg.sender);
    dsce.mintDsc(amount);
    vm.stopPrank();
}
}