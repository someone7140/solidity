// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

import "./StrUtil.sol";

contract HandUtil is StrUtil {

    string fixSecretKey = "secret";
    string[] handList = ["rock", "paper", "scissors"];
    address defaultAddress = address(0);
 
    struct CommitmentHand {
        address userAddress;
        bytes32 encryptionHand;
        string userSettingKey;
    }

    struct RevealHand {
        address userAddress;
        string userName;
        string hand;
    }
 
    // 暗号化されたじゃんけんの手の取得
    function _getEncryptionHand(string memory _hand, string memory _userSettingKey) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(_strConnect(_strConnect(_hand, fixSecretKey), _userSettingKey))
        );
    }

    // じゃんけんの手のチェック
    function _checkHand(string memory _hand) public view returns (bool) {
        bool check = false;
        for (uint i = 0; i < handList.length; i++) {
            if (equal(_hand, handList[i])) {
                check = true;
            }
        }
        return check;
    }

    // 手の複合化
    function _getDecryptHand(address _userAddress, CommitmentHand[] memory commitmentHands) public view returns (string memory) {
        string memory revealHand = "";
        for (uint i = 0; i < commitmentHands.length; i++) {
            if (_userAddress == commitmentHands[i].userAddress) {
                for (uint k = 0; k < handList.length; k++) {
                    if (commitmentHands[i].encryptionHand == _getEncryptionHand(handList[k], commitmentHands[i].userSettingKey)) {
                        revealHand = handList[k];
                    }
                }

            }
        }
        return revealHand;
    }

    // 勝者の取得（あいこの場合は初期値アドレス）
    function _judgeWinner(RevealHand[] memory revealHands) public view returns (address) {
        if (equal(revealHands[0].hand, "rock")) {
            if (equal(revealHands[1].hand, "rock")) {
                return defaultAddress;
            } else if (equal(revealHands[1].hand, "paper")) {
                return revealHands[1].userAddress;
            } else {
                return revealHands[0].userAddress; 
            }
        } else if (equal(revealHands[0].hand, "paper")) {
            if (equal(revealHands[1].hand, "rock")) {
                return revealHands[0].userAddress;
            } else if (equal(revealHands[1].hand, "paper")) {
                return defaultAddress;
            } else {
                return revealHands[1].userAddress; 
            }   
        } else {
            if (equal(revealHands[1].hand, "rock")) {
                return revealHands[1].userAddress;
            } else if (equal(revealHands[1].hand, "paper")) {
                return revealHands[0].userAddress;
            } else {
                return defaultAddress; 
            }  
        }
    }
}