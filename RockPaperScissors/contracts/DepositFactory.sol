// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

import "./UserFactory.sol";
import "./HandUtil.sol";

contract DepositFactory is UserFactory, HandUtil {
    struct UserDeposit {
        address userAddress;
        uint256 deposit;
    }

    struct UserDepositSetting {
        UserDeposit[] deposits;
    }

    mapping(uint256 => UserDepositSetting) gameDepositMapping;

    // 受け取った金額をデポジットとして設定
    function _depositSet(
        uint256 _gameId,
        address _userAddress,
        uint256 _deposit
    ) public {
        gameDepositMapping[_gameId].deposits.push(
            UserDeposit(_userAddress, _deposit)
        );
    }

    // ゲストユーザの設定金額チェック
    function _depositCheckGuest(uint256 _gameId, uint256 _deposit)
        public
        view
        returns (bool)
    {
        uint256 hostDeposit = gameDepositMapping[_gameId].deposits[0].deposit;
        return hostDeposit == _deposit;
    }

    // ゲーム勝敗によるデポジット更新
    function _depositUpdatebyGame(address _winnerAddress, uint256 _gameId)
        public
    {
        uint256 winnerDepositIndex = 0;
        uint256 loserDepositIndex = 0;
        if (_winnerAddress != defaultAddress) {
            for (
                uint256 i;
                i < gameDepositMapping[_gameId].deposits.length;
                i++
            ) {
                if (
                    gameDepositMapping[_gameId].deposits[i].userAddress ==
                    _winnerAddress
                ) {
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
    }

    // デポジットの引出し（双方の手が開示された場合）
    function _drawDepositWhenRevealed(
        address payable _userAddress,
        uint256 _gameId
    ) public payable {
        for (uint256 i; i < gameDepositMapping[_gameId].deposits.length; i++) {
            if (
                gameDepositMapping[_gameId].deposits[i].userAddress ==
                _userAddress
            ) {
                _userAddress.transfer(
                    gameDepositMapping[_gameId].deposits[i].deposit
                );
                gameDepositMapping[_gameId].deposits[i].deposit = 0;
            }
        }
    }

    // デポジットの引出し（時間超過）
    function _drawDepositWhenTimeExceeded(
        address payable _userAddress,
        uint256 _gameId
    ) public payable {
        uint256 depositSum = 0;
        for (uint256 i; i < gameDepositMapping[_gameId].deposits.length; i++) {
            depositSum =
                depositSum +
                gameDepositMapping[_gameId].deposits[i].deposit;
            gameDepositMapping[_gameId].deposits[i].deposit = 0;
        }
        _userAddress.transfer(depositSum);
    }
}
