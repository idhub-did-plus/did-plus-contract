pragma solidity ^0.5.0;

/// @title 一种地址集合的数据结构实现。
/// @author Noah Zinsmeister, Zaakin Yao
/// @dev O(1)时间复杂度  插入、删除、集合判断、长度等函数
library AddressSet {
    struct Set {
        address[] members;
        mapping(address => uint) memberIndices;
    }

    /// @dev 将一个元素插入一个集合，如果集合中已存在该元素，则此函数无操作。
    /// @param self 要插入元素的集合。
    /// @param other 要插入的元素。
    function insert(Set storage self, address other) internal {
        if (!contains(self, other)) {
            self.memberIndices[other] = self.members.push(other);
        }
    }

    /// @dev 从一个集合中删除一个元素，如果集合中不存在该元素，则此函数无操作。
    /// @param self 要删除元素的集合。
    /// @param other 要删除的元素。
    function remove(Set storage self, address other) internal {
        if (contains(self, other)) {
            // replace other with the last element
            self.members[self.memberIndices[other] - 1] = self.members[length(self) - 1];
            // reflect this change in the indices
            self.memberIndices[self.members[self.memberIndices[other] - 1]] = self.memberIndices[other];
            delete self.memberIndices[other];
            // remove the last element
            self.members.pop();
        }
    }

    /// @dev 检查集合成员。
    /// @param self 要检查的集合。
    /// @param other 要检查的元素。
    /// @return 集合中存在元素为 true，否则 false
    function contains(Set storage self, address other) internal view returns (bool) {
        return ( // solium-disable-line operator-whitespace
            self.memberIndices[other] > 0 && 
            self.members.length >= self.memberIndices[other] && 
            self.members[self.memberIndices[other] - 1] == other
        );
    }

    /// @dev 返回集合中的成员数量。
    /// @param self 要检查长度的集合。
    /// @return 集合长度。
    function length(Set storage self) internal view returns (uint) {
        return self.members.length;
    }
}