// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract UserFactory {
    mapping(address => string) userNameMapping;

    // ユーザの作成
    function _createUser(address _userAddress, string memory _name) public {
        userNameMapping[_userAddress] = _name;
    }
}
