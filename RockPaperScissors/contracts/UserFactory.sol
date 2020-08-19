// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract UserFactory {
    mapping(address => string) userNameMapping;
    mapping(address => uint256) userAmountMapping;

    // ユーザの作成
    function _createUser(
        address _userAddress,
        string memory _name,
        uint256 _amount
    ) public {
        userNameMapping[_userAddress] = _name;
        userAmountMapping[_userAddress] = _amount;
    }

    // 保有金額の確認
    function _showAmount(address _userAddress) public view returns (uint256) {
        return userAmountMapping[_userAddress];
    }
}
