// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

import "./UserFactory.sol";
import "./HandUtil.sol";

contract GameFactory is UserFactory, HandUtil {
 
    uint count = 0;
    uint timerLimit = 1 days;

    struct UserDeposit {
        address userAddress;
        uint deposit;
    }

    struct OpenGame {
        uint gameId;
        string hostName;
        uint deposit;
    }

    OpenGame[] public openGames;
 
    struct UserDepositSetting {
        UserDeposit[] deposits;
    }
 
    struct CommitmentHandSetting { 
        CommitmentHand[] commitmentHands;
    }

    struct RevealHandSetting { 
        RevealHand[] revealHands;
    }

    mapping (uint => address) gameHostAddressMapping;
    mapping (uint => string) gameStateMapping;
    mapping (uint => UserDepositSetting) gameDepositMapping;
    mapping (uint => CommitmentHandSetting) gameCommitmentHandMapping;
    mapping (uint => RevealHandSetting) gameRevealHandMapping;
    mapping (uint => uint) gameTimerMapping;

    // ゲームの開始
    function _gameStart(address _userAddress, string memory _hostHand, uint _deposit, string memory _userSettingKey) public {
        require(_checkHand(_hostHand));
        require(_deposit < userAmountMapping[_userAddress]);
        count++;
        uint gameId = count;
        gameHostAddressMapping[gameId] = _userAddress;
        gameStateMapping[gameId] = "gameOpen";
        gameDepositMapping[gameId].deposits.push(UserDeposit(_userAddress, _deposit));
        userAmountMapping[_userAddress] = userAmountMapping[_userAddress] - _deposit;
        // 暗号化された手の登録
        gameCommitmentHandMapping[gameId].commitmentHands.push(
            CommitmentHand(_userAddress, _getEncryptionHand(_hostHand, _userSettingKey), _userSettingKey)
        );
        // 受付ゲームの取得
        openGames.push(OpenGame(
            gameId,
            userNameMapping[gameHostAddressMapping[gameId]],
            _deposit
        ));
    }

    // 参加可能ゲームの取得
    function _getOpenGame() public view returns (OpenGame[] memory) {
        return openGames;
    }

    // ゲームの参加
    function _joinGame(address _userAddress, uint _gameId, string memory _counterHand, string memory _userSettingKey) public {
        require(equal(gameStateMapping[_gameId], "gameOpen"));
        require(gameHostAddressMapping[_gameId] != _userAddress);
        // デポジットは参加ゲームのものを設定
        uint deposit = gameDepositMapping[_gameId].deposits[0].deposit;
        gameDepositMapping[_gameId].deposits.push(UserDeposit(_userAddress, deposit));
        userAmountMapping[_userAddress] = userAmountMapping[_userAddress] - deposit;
        // 暗号化された手の登録
        gameCommitmentHandMapping[_gameId].commitmentHands.push(
            CommitmentHand(_userAddress, _getEncryptionHand(_counterHand, _userSettingKey), _userSettingKey)
        );
        // 受付ゲームの削除
        for (uint i; i < openGames.length; i++) {
            if (openGames[i].gameId == _gameId) {
                delete openGames[i];
            }
        }

        gameStateMapping[_gameId] = "commitment";
    }

    // 手の公開
    function _reveal(address _userAddress, uint _gameId) public {
        require(
            equal(gameStateMapping[_gameId], "commitment") ||
            equal(gameStateMapping[_gameId], "oneRevealed")
        );
        bool revealedFlg = false;
        RevealHand[] memory revealHands = gameRevealHandMapping[_gameId].revealHands;
        for (uint i; i < revealHands.length; i++) {
            if (revealHands[i].userAddress == _userAddress) {
                revealedFlg = true;
            }
        }
        if (!revealedFlg) {
            // 暗号化された手の復号化
            string memory revealHand = _getDecryptHand(_userAddress, gameCommitmentHandMapping[_gameId].commitmentHands);
            require(!equal(revealHand, ""));
            if (equal(gameStateMapping[_gameId], "oneRevealed")) {
                // 時間チェック
                require(!_exceededTimerCheck(_gameId));

                gameRevealHandMapping[_gameId].revealHands.push(
                    RevealHand(_userAddress, userNameMapping[_userAddress], revealHand)
                );
                gameStateMapping[_gameId] = "twoRevealed";
                // 勝敗判定
                address winner = _judgeWinner(gameRevealHandMapping[_gameId].revealHands);
                // デポジットの更新
                uint winnerDepositIndex = 0;
                uint loserDepositIndex = 0;
                if (winner != defaultAddress) {
                    for (uint i; i < gameDepositMapping[_gameId].deposits.length; i++) {
                        if (gameDepositMapping[_gameId].deposits[i].userAddress == winner) {
                            winnerDepositIndex = i;
                        } else {
                            loserDepositIndex = i;
                        }
                    }
                }
                gameDepositMapping[_gameId].deposits[winnerDepositIndex].deposit = 
                    gameDepositMapping[_gameId].deposits[winnerDepositIndex].deposit +
                    gameDepositMapping[_gameId].deposits[loserDepositIndex].deposit;
                gameDepositMapping[_gameId].deposits[loserDepositIndex].deposit = 0;
            } else if (equal(gameStateMapping[_gameId], "commitment")) {
                gameRevealHandMapping[_gameId].revealHands.push(
                    RevealHand(_userAddress, userNameMapping[_userAddress], revealHand)
                );
                gameStateMapping[_gameId] = "oneRevealed";
                // タイマー設定
                gameTimerMapping[_gameId] = now;
            }
        } 
    }

    // 公開された手の参照
    function _getRevealHands(uint _gameId) public view returns(RevealHand[] memory) {
        return gameRevealHandMapping[_gameId].revealHands;
    }

    // デポジットの引出し
    function _drawDeposit(address _userAddress, uint _gameId) public {
        // twoRevealedか、oneRevealedで時間超過
        require(
            equal(gameStateMapping[_gameId], "twoRevealed") ||
            (
                equal(gameStateMapping[_gameId], "oneRevealed") &&
                _exceededTimerCheck(_gameId)
            )
        );
        if (equal(gameStateMapping[_gameId], "twoRevealed")) {
            for (uint i; i < gameDepositMapping[_gameId].deposits.length; i++) {
                if (gameDepositMapping[_gameId].deposits[i].userAddress == _userAddress) {
                    userAmountMapping[_userAddress] = userAmountMapping[_userAddress] + gameDepositMapping[_gameId].deposits[i].deposit;
                    gameDepositMapping[_gameId].deposits[i].deposit = 0;
                }
            }
        } else {
            // 時間超過の場合は双方の合計
            uint depositSum = 0;
            for (uint i; i < gameDepositMapping[_gameId].deposits.length; i++) {
                depositSum = depositSum + gameDepositMapping[_gameId].deposits[i].deposit;
                gameDepositMapping[_gameId].deposits[i].deposit = 0;
            }
            userAmountMapping[_userAddress] = userAmountMapping[_userAddress] + depositSum;
        }
    }

    // 時間超過チェック
    function _exceededTimerCheck(uint _gameId) private view returns(bool) {
        require(gameTimerMapping[_gameId] != 0);
        return (now - gameTimerMapping[_gameId] > timerLimit);
    }
}
