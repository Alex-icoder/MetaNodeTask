// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAuctionReenter {
    function placeBid(uint256 auctionId,uint256 amount) external payable;
}

contract MaliciousBidder {
    IAuctionReenter public target;
    uint256 public reenterAttempted;

    constructor(address _target){
        target = IAuctionReenter(_target);
    }

    // 通过 fallback 在退款时尝试重入（如果退款用 call/value）
    receive() external payable {
        if (reenterAttempted==0) {
            reenterAttempted=1;
            // 试图再次出价（应被 ReentrancyGuard 阻止）
            try target.placeBid{value: msg.value}(0, msg.value) {
            } catch {
                // swallow
            }
        }
    }
}