// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract StrUtil {
    // 文字列の結合（https://programming-learning.com/2018/04/10/solidity%E3%81%A7%E6%96%87%E5%AD%97%E5%88%97%E9%80%A3%E7%B5%90%E3%81%97%E3%81%A6%E8%BF%94%E5%8D%B4/）
    function _strConnect(string memory str1, string memory str2)
        public
        view
        returns (string memory)
    {
        bytes memory strbyte1 = bytes(str1);
        bytes memory strbyte2 = bytes(str2);
        bytes memory str = new bytes(strbyte1.length + strbyte2.length);
        uint8 point = 0;
        for (uint8 j = 0; j < strbyte1.length; j++) {
            str[point] = strbyte1[j];
            point++;
        }
        for (uint8 k = 0; k < strbyte2.length; k++) {
            str[point] = strbyte2[k];
            point++;
        }
        return string(str);
    }

    /// 文字列比較（https://github.com/ethereum/dapp-bin/blob/master/library/stringUtils.sol）
    function equal(string memory _a, string memory _b)
        public
        view
        returns (bool)
    {
        return compare(_a, _b) == 0;
    }

    function compare(string memory _a, string memory _b)
        public
        view
        returns (int256)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }
}
