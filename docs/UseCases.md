# IDHub DID-Plus On-Chain UseCases

IDHub DID-Plus采用ERC1056标示用户去中心化数字身份，并在后续根据DID协议进行扩展；另外，采用ERC1484对用户在以太坊上的数字身份进行聚合。在此用例中，ERC1056`identity`和ERC1484`EIN`同时作为用户的去中心化数字身份标识符。

## 身份管理

ERC1484提供了身份创建、恢复`EIN`，ERC1056默认自动为用户注册`identity`。

### 身份创建
在ERC1484调用`createIdentity`函数或者通过授权签名调用`createIdentityDelegated`函数获得`EIN`，在ERC1056中会默认将以太坊交易发起地址或授权签名地址注册为`identity`

```solidity
	// ERC1484创建身份
	function createIdentity(address recoveryAddress, address[] memory providers, address[] memory resolvers)
        public returns (uint ein)

	// 或者采用授权签名的方式注册身份
	function createIdentityDelegated(
        address recoveryAddress, address associatedAddress, address[] memory providers, address[] memory resolvers,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp) returns (uint ein)

    // ERC1056会默认注册创建身份
    function identityOwner(address identity) public view returns(address) {
        address owner = owners[identity];
        if (owner != address(0)) {
            return owner;
        }
        return identity;
    }
```
`createIdentity`的交易发起地址为`associatedAddress`或者`createIdentityDelegated`函数的`v, r, s`参数值来自于参数`associatedAddress`的签名。在创建身份步骤里，前面所述的`associatedAddress`会在ERC1056中默认被注册为`identity`。恢复地址`recoveryAddress`对应的私钥应该被冷存储用于特殊情况发生时找回`EIN`的控制权。ERC1056的地址应该作为`Resolver`之一传入。

### 身份找回

身份的找回主要依靠恢复地址的使用。

#### 更改恢复地址

关联地址可以通过调用`triggerRecoveryAddressChange`函数来更改恢复地址。
```solidity
    function triggerRecoveryAddressChange(address newRecoveryAddress) public
```
新的恢复地址需要两周才生效，原恢复地址有权利在两周内直接触发身份恢复流程来找回身份，参考下一节，此权限适用于身份被盗用且触发了更改恢复地址的流程。

#### 身份恢复

恢复地址或更改恢复地址流程触发两周内的原恢复地址可以调用`triggerRecovery`触发身份恢复流程来找回`EIN`的控制权。
```solidity
    function triggerRecovery(uint ein, address newAssociatedAddress, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        public _identityExists(ein) _hasIdentity(newAssociatedAddress, false) ensureSignatureTimeValid(timestamp)
```
此操作会删除`EIN`所有的关联地址、`Provider`和`Resolver`，传入的`newAssociatedAddress`参数需要未和任何`EIN`绑定过关联关系且会成为`EIN`的唯一关联地址。另外，还需要`newAssociatedAddress`的签名`v, r, s`值。

### 身份注销

用户在发现关联地址或者恢复地址被盗用且触发恢复流程的两周内，可以强制注销身份。
```solidity
    function triggerDestruction(uint ein, address[] memory firstChunk, address[] memory lastChunk, bool resetResolvers)
        public _identityExists(ein)
```
此操作的交易发起者必须是`EIN`的关联地址之一，且要严格按序传入`EIN`的所有关联地址，包括交易发起者之前的关联地址数组和之后的关联地址数组。因此，必要的时候用户应该按序保存所有关联地址或注销身份时读取关联地址的排序来构建参数。

## 密钥轮换管理

ERC1484提供了将多个关联地址`associatedAddress`映射到同一个`EIN`的功能。

### 关联地址增加

用户可以直接或授权签名为自己的`EIN`绑定关联地址，每个`EIN`的关联地址数量没有限制。
```solidity
    function addAssociatedAddress(
        address approvingAddress, address addressToAdd, uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp)


    // Or
    function addAssociatedAddressDelegated(
        address approvingAddress, address addressToAdd,
        uint8[2] memory v, bytes32[2] memory r, bytes32[2] memory s, uint[2] memory timestamp
    )
        public ensureSignatureTimeValid(timestamp[0]) ensureSignatureTimeValid(timestamp[1])
```
`approvingAddress`是`EIN`的已有关联地址之一，`addressToAdd`是要被添加的关联地址。用户直接调用`addAssociatedAddress`函数的交易发送者必须是其中之一且需要来自另一地址的签名的`v, r, s`值。如果签名授权调用`addAssociatedAddressDelegated`的函数则同时需要两个地址的签名的`v, r, s`值，数组顺序和参数顺序一致。

### 关联地址删除

用户的一个关联地址可以直接或签名授权和用户的数字身份移除绑定关系。
```solidity
	function removeAssociatedAddress() public

	function removeAssociatedAddressDelegated(address addressToRemove, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        public ensureSignatureTimeValid(timestamp)
```
关联地址主动调用`removeAssociatedAddress`发送交易则移除与自己对应的数字身份的绑定关系，授权别人调用`removeAssociatedAddressDelegated`则需要关联地址签名的`v, r, s`值。

## 链上声明验证

ERC780提供了在以太坊区块链上读写`claim`声明的功能。声明代表对用户身份的某种属性的一种公开说明或认证，IDHub用于对数字身份投资合规性的认证。

### 链上声明发布

通过调用`setClaim`函数可以实现链上声明的创建与更新。
```solidity
    function setClaim(address subject, bytes32 key, bytes32 value) public 
```
`subject`参数为声明接受者，或被声明认证的地址；`key`是声明的类型，命名参考[方案](https://github.com/ethereum/EIPs/issues/780)；`value`是声明的值，无具体限制。

在数字身份投资合规性认证场景中，`subject`应设为被认证用户的ERC1056`identity`标识符地址；`key`应设为`keccak256('IDHub:compliantInvestor:countryOfResidency:Nationality')`，其中占位符`countryOfResidency`表示被声明用户的居住国，`Nationality`表示被声明用户的国籍；`value`应设为`left_padded_timestamp`，其中占位符`left_padded_timestamp`表示声明有效截止时间，格式为向左填充256位（`bytes`）的秒级时间戳，声明有效期一般为三个月。

### 链上声明验证

第三方合约依次通过调用`getEIN`、`einToDID`、`getClaim`可以对以太坊交易发送者完成一次链上声明的自动验证。
```solidity
	function getEIN(address _address) public view _hasIdentity(_address, true) returns (uint ein) 

	mapping(uint => address) public einToDID;

	function getClaim(address issuer, address subject, bytes32 key) public view returns(bytes32) 
```
用户通过某个关联地址`associatedAddress`调用第三方合约，第三方合约通过`getEIN(associatedAddress)`查到用户的`EIN`，然后通过`einToDID(EIN)`查到用户的ERC1056`identity`地址（即用户的`ethr-did`地址），最后通过`getClaim(issuer, identity, key)`函数另外传入预期的`issuer`和`key`得到声明的`value`值，检查`value`值是否符合预期即可完成声明的验证。




