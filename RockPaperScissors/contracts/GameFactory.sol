// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

import "./DepositFactory.sol";
import "./HandUtil.sol";

contract GameFactory is DepositFactory {
    uint256 count = 0;
    uint256 timerLimit = 1 days;

    struct OpenGame {
        uint256 gameId;
        string hostName;
        uint256 deposit;
    }

    OpenGame[] public openGames;

    struct CommitmentHandSetting {
        CommitmentHand[] commitmentHands;
    }

    struct RevealHandSetting {
        RevealHand[] revealHands;
    }

    mapping(uint256 => address) gameHostAddressMapping;
    mapping(uint256 => string) gameStateMapping;
    mapping(uint256 => CommitmentHandSetting) gameCommitmentHandMapping;
    mapping(uint256 => RevealHandSetting) gameRevealHandMapping;
    mapping(uint256 => uint256) gameTimerMapping;

    // ゲームの開始
    function _gameStart(bytes32 _hostEncryptionHand) public payable {
        count++;
        uint256 gameId = count;
        gameHostAddressMapping[gameId] = msg.sender;
        gameStateMapping[gameId] = "gameOpen";
        _depositSet(gameId, msg.sender, msg.value);
        // 暗号化された手の登録
        gameCommitmentHandMapping[gameId].commitmentHands.push(
            CommitmentHand(msg.sender, _hostEncryptionHand)
        );
        // 受付ゲームの取得
        openGames.push(
            OpenGame(
                gameId,
                userNameMapping[gameHostAddressMapping[gameId]],
                msg.value
            )
        );
    }

    // 参加可能ゲームの取得
    function _getOpenGame() public view returns (OpenGame[] memory) {
        return openGames;
    }

    // ゲームの参加
    function _joinGame(uint256 _gameId, bytes32 _guestEncryptionHand)
        public
        payable
    {
        require(equal(gameStateMapping[_gameId], "gameOpen"));
        require(gameHostAddressMapping[_gameId] != msg.sender);
        // デポジットは参加ゲームの金額が設定されているか
        require(_depositCheckGuest(_gameId, msg.value));
        _depositSet(_gameId, msg.sender, msg.value);
        // 暗号化された手の登録
        gameCommitmentHandMapping[_gameId].commitmentHands.push(
            CommitmentHand(msg.sender, _guestEncryptionHand)
        );
        // 受付ゲームの削除
        for (uint256 i; i < openGames.length; i++) {
            if (openGames[i].gameId == _gameId) {
                delete openGames[i];
            }
        }

        gameStateMapping[_gameId] = "commitment";
    }

    // 手の公開
    function _reveal(
        address _userAddress,
        uint256 _gameId,
        string memory _userSettingKey
    ) public {
        require(
            equal(gameStateMapping[_gameId], "commitment") ||
                equal(gameStateMapping[_gameId], "oneRevealed")
        );
        bool revealedFlg = false;
        RevealHand[] memory revealHands = gameRevealHandMapping[_gameId]
            .revealHands;
        for (uint256 i; i < revealHands.length; i++) {
            if (revealHands[i].userAddress == _userAddress) {
                revealedFlg = true;
            }
        }
        if (!revealedFlg) {
            // 暗号化された手の復号化
            string memory revealHand = _getDecryptHand(
                _userAddress,
                _userSettingKey,
                gameCommitmentHandMapping[_gameId].commitmentHands
            );
            require(!equal(revealHand, ""));
            if (equal(gameStateMapping[_gameId], "oneRevealed")) {
                // 時間チェック
                require(!_exceededTimerCheck(_gameId));
                gameRevealHandMapping[_gameId].revealHands.push(
                    RevealHand(
                        _userAddress,
                        userNameMapping[_userAddress],
                        revealHand,
                        _userSettingKey
                    )
                );
                gameStateMapping[_gameId] = "twoRevealed";
                // 勝敗判定
                address winner = _judgeWinner(
                    gameRevealHandMapping[_gameId].revealHands
                );
                // デポジットの更新
                _depositUpdatebyGame(winner, _gameId);
            } else if (equal(gameStateMapping[_gameId], "commitment")) {
                gameRevealHandMapping[_gameId].revealHands.push(
                    RevealHand(
                        _userAddress,
                        userNameMapping[_userAddress],
                        revealHand,
                        _userSettingKey
                    )
                );
                gameStateMapping[_gameId] = "oneRevealed";
                // タイマー設定
                gameTimerMapping[_gameId] = block.timestamp;
            }
        }
    }

    // 公開された手の参照
    function _getRevealHands(uint256 _gameId)
        public
        view
        returns (RevealHand[] memory)
    {
        return gameRevealHandMapping[_gameId].revealHands;
    }

    // デポジットの引出し
    function _drawDeposit(address payable _userAddress, uint256 _gameId)
        public
    {
        // twoRevealedか、oneRevealedで時間超過
        require(
            equal(gameStateMapping[_gameId], "twoRevealed") ||
                (equal(gameStateMapping[_gameId], "oneRevealed") &&
                    _exceededTimerCheck(_gameId))
        );
        if (equal(gameStateMapping[_gameId], "twoRevealed")) {
            _drawDepositWhenRevealed(_userAddress, _gameId);
        } else {
            // 時間超過の場合は開示したアドレスのみ双方の合計を引出し
            if (
                gameRevealHandMapping[_gameId].revealHands[0].userAddress ==
                _userAddress
            ) {
                _drawDepositWhenTimeExceeded(_userAddress, _gameId);
            }
        }
    }

    // 時間超過チェック
    function _exceededTimerCheck(uint256 _gameId) private view returns (bool) {
        require(gameTimerMapping[_gameId] != 0);
        return (block.timestamp - gameTimerMapping[_gameId] > timerLimit);
    }
}
