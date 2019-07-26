pragma solidity ^0.5.0;

import "./SignatureVerifier.sol";
import "./AddressSet/AddressSet.sol";

/// @title The ERC-1484 Identity Registry.
/// @author Noah Zinsmeister
/// @author Andy Chorlian
/// @author Zaakin Yao
contract IdentityRegistry is SignatureVerifier {
    using AddressSet for AddressSet.Set;


    // 数字身份数据结构和参数 //////////////////////////////////////////////////////////////////////////

    struct Identity {
        address recoveryAddress;
        AddressSet.Set associatedAddresses;
        AddressSet.Set providers;
        AddressSet.Set resolvers;
    }

    mapping (uint => Identity) private identityDirectory;
    mapping (address => uint) private associatedAddressDirectory;

    uint public nextEIN = 1;
    uint public maxAssociatedAddresses = 50;


    // 签名时间有效期 ///////////////////////////////////////////////////////////////////////////////////////////////

    uint public signatureTimeout = 1 days;

    /// @dev 强制传入的时间戳在当前区块时间戳的`signatureTimeout`内。
    /// @param timestamp 待校验的时间戳。
    modifier ensureSignatureTimeValid(uint timestamp) {
        require(
            // solium-disable-next-line security/no-block-members
            block.timestamp >= timestamp && block.timestamp < timestamp + signatureTimeout, "Timestamp is not valid."
        );
        _;
    }


    // 恢复地址更改的日志记录 /////////////////////////////////////////////////////////////////////////////////

    struct RecoveryAddressChange {
        uint timestamp;
        address oldRecoveryAddress;
    }

    mapping (uint => RecoveryAddressChange) private recoveryAddressChangeLogs;


    // 恢复操作的日志记录 ////////////////////////////////////////////////////////////////////////////////////////////////

    struct Recovery {
        uint timestamp;
        bytes32 hashedOldAssociatedAddresses;
    }

    mapping (uint => Recovery) private recoveryLogs;


    // 恢复操作的时间有效期 ////////////////////////////////////////////////////////////////////////////////////////////////

    uint public recoveryTimeout = 2 weeks;

    /// @dev 检查传入的EIN是否已经在`recoveryTimeout`秒内更改了其恢复地址。
    function canChangeRecoveryAddress(uint ein) private view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > recoveryAddressChangeLogs[ein].timestamp + recoveryTimeout;
    }

    /// @dev 检查传入的EIN是否已在`recoveryTimeout`秒内执行了恢复操作。
    function canRecover(uint ein) private view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > recoveryLogs[ein].timestamp + recoveryTimeout;
    }


    // 数字身份静态 view 函数 /////////////////////////////////////////////////////////////////////////////////////////

    /// @notice 检查传入的EIN是否存在。
    /// @dev 不会抛出异常。
    /// @param ein 要被检查是否存在的EIN
    /// @return 如果EIN存在返回 true 否则返回 false
    function identityExists(uint ein) public view returns (bool) {
        return ein < nextEIN && ein > 0;
    }

    /// @dev 确保传入的EIN存在。
    /// @param ein 要被检查是否存在的EIN
    modifier _identityExists(uint ein) {
        require(identityExists(ein), "The identity does not exist.");
        _;
    }

    /// @notice 检查一个传入的地址是否与一个身份`Identity`相关联，即是否为一个身份的关联地址。
    /// @dev 不会抛出异常。
    /// @param _address 要被检查的地址。
    /// @return 如果是一个身份的关联地址返回 true 否则返回 false
    function hasIdentity(address _address) public view returns (bool) {
        return identityExists(associatedAddressDirectory[_address]);
    }

    /// @dev 确保一个传入的地址是否与一个身份`Identity`相关联，即是否为一个身份的关联地址。
    /// @param _address 要被检查的地址。
    /// @param check 传入 true 确保地址与一个身份相关联，传入 false 则反之。
    /// @return 如果关联状态等于`check`返回 true 否则返回 false
    modifier _hasIdentity(address _address, bool check) {
        require(
            hasIdentity(_address) == check,
            check ?
                "The passed address does not have an identity but should." :
                "The passed address has an identity but should not."
        );
        _;
    }

    /// @notice 获取与传入地址相关联的EIN
    /// @dev 如果传入的地址没有与任何一个身份相关联则抛出异常。
    /// @param _address 待检查的地址。
    /// @return 相关联的EIN
    function getEIN(address _address) public view _hasIdentity(_address, true) returns (uint ein) {
        return associatedAddressDirectory[_address];
    }

    /// @notice 检查传入的EIN是否和传入的地址相关联，即传入的地址是否为传入EIN的关联地址。
    /// @dev 不会抛出异常。
    /// @param ein 待检查的EIN
    /// @param _address 待检查的地址。
    /// @return 如果传入的EIN和传入的地址相关联返回 true 否则返回 false
    function isAssociatedAddressFor(uint ein, address _address) public view returns (bool) {
        return identityDirectory[ein].associatedAddresses.contains(_address);
    }

    /// @notice 检查传入的`Provider`是否被设置给了传入的EIN
    /// @dev 不会抛出异常。
    /// @param ein 待检查的EIN
    /// @param provider 待检查的`Provider`
    /// @return 如果`Provider`被设置给了EIN返回 true 否则返回 false
    function isProviderFor(uint ein, address provider) public view returns (bool) {
        return identityDirectory[ein].providers.contains(provider);
    }

    /// @dev 确保`msg.sender`被设置给了EIN
    /// @param ein 待检查的EIN
    modifier _isProviderFor(uint ein) {
        require(isProviderFor(ein, msg.sender), "The identity has not set the passed provider.");
        _;
    }

    /// @notice 检查传入的`Provider`是否被设置给了传入的EIN
    /// @dev 不会抛出异常
    /// @param ein 待检查的EIN
    /// @param resolver 待检查的`Provider`
    /// @return 如果传入的`Provider`被设置给了传入的EIN返回 true 否则返回 false
    function isResolverFor(uint ein, address resolver) public view returns (bool) {
        return identityDirectory[ein].resolvers.contains(resolver);
    }

    /// @notice 获取传入的EIN身份的所有相关信息。
    /// @dev 如果传入的EIN不存在则抛出异常。
    /// @param ein 要获取信息的EIN
    /// @return 所有跟传入EIN的身份相关联的信息。
    function getIdentity(uint ein) public view _identityExists(ein)
        returns (
            address recoveryAddress,
            address[] memory associatedAddresses, address[] memory providers, address[] memory resolvers
        )
    {
        Identity storage _identity = identityDirectory[ein];

        return (
            _identity.recoveryAddress,
            _identity.associatedAddresses.members,
            _identity.providers.members,
            _identity.resolvers.members
        );
    }


    // 身份管理函数 ///////////////////////////////////////////////////////////////////////////////////

    /// @notice 为以太坊交易发起人创建一个数字身份。
    /// @dev 设置`msg.sender`为唯一的关联地址。
    /// @param recoveryAddress 新建数字身份的恢复地址。
    /// @param providers 新建数字身份的`Provider`数组。
    /// @param resolvers 新建数字身份的`Resolver`数组。
    /// @return 新建数字身份的EIN
    function createIdentity(address recoveryAddress, address[] memory providers, address[] memory resolvers)
        public returns (uint ein)
    {
        return createIdentity(recoveryAddress, msg.sender, providers, resolvers, false);
    }

    /// @notice 允许为传入的关联地址新建一个数字身份。
    /// @param recoveryAddress 新建数字身份的恢复地址。
    /// @param associatedAddress 新建数字身份的一个关联地址（必须由此地址产生签名）。
    /// @param providers 新建数字身份的`Provider`数组。
    /// @param resolvers 新建数字身份的`Resolver`数组。
    /// @param v 签名的v值。
    /// @param r 签名的r值。
    /// @param s 签名的s值。
    /// @param timestamp 签名的时间戳。
    /// @return 新建数字身份的EIN
    function createIdentityDelegated(
        address recoveryAddress, address associatedAddress, address[] memory providers, address[] memory resolvers,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp) returns (uint ein)
    {
        require(
            isSigned(
                associatedAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize the creation of an Identity on my behalf.",
                        recoveryAddress, associatedAddress, providers, resolvers, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        return createIdentity(recoveryAddress, associatedAddress, providers, resolvers, true);
    }

    /// @dev 所有身份创建的通用逻辑。
    function createIdentity(
        address recoveryAddress,
        address associatedAddress, address[] memory providers, address[] memory resolvers, bool delegated
    )
        private _hasIdentity(associatedAddress, false) returns (uint)
    {
        uint ein = nextEIN++;
        Identity storage _identity = identityDirectory[ein];

        _identity.recoveryAddress = recoveryAddress;
        addAssociatedAddress(ein, associatedAddress);
        addProviders(ein, providers, delegated);
        addResolvers(ein, resolvers, delegated);

        emit IdentityCreated(msg.sender, ein, recoveryAddress, associatedAddress, providers, resolvers, delegated);

        return ein;
    }


    /// @notice 允许一个关联地址将一个地址添加为它的数字身份的另一个关联地址。
    /// @param approvingAddress 一个数字身份的关联地址。
    /// @param addressToAdd 添加为发送者数字身份的关联地址的地址。
    /// @param v 签名的v值。
    /// @param r 签名的r值。
    /// @param s 签名的s值。
    /// @param timestamp 签名的时间戳。
    function addAssociatedAddress(
        address approvingAddress, address addressToAdd, uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp)
    {
        bool fromApprovingAddress = msg.sender == approvingAddress;
        require(
            fromApprovingAddress || msg.sender == addressToAdd, "One or both of the passed addresses are malformed."
        );

        uint ein = getEIN(approvingAddress);

        require(
            isSigned(
                fromApprovingAddress ? addressToAdd : approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        fromApprovingAddress ?
                            "I authorize being added to this Identity." :
                            "I authorize adding this address to my Identity.",
                        ein, addressToAdd, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        addAssociatedAddress(ein, addressToAdd);

        emit AssociatedAddressAdded(msg.sender, ein, approvingAddress, addressToAdd, false);
    }

    /// @notice 允许添加一个地址成为一个数字身份的关联地址。
    /// @dev 第一个签名必须是`approvingAddress`的签名。
    /// @param approvingAddress 一个数字身份的关联地址。
    /// @param addressToAdd 要被设置为`approvingAddress`的数字身份的新关联地址的地址。
    /// @param v 签名的v值。
    /// @param r 签名的r值。
    /// @param s 签名的s值。
    /// @param timestamp 签名的时间戳。
    function addAssociatedAddressDelegated(
        address approvingAddress, address addressToAdd,
        uint8[2] memory v, bytes32[2] memory r, bytes32[2] memory s, uint[2] memory timestamp
    )
        public ensureSignatureTimeValid(timestamp[0]) ensureSignatureTimeValid(timestamp[1])
    {
        uint ein = getEIN(approvingAddress);

        require(
            isSigned(
                approvingAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize adding this address to my Identity.",
                        ein, addressToAdd, timestamp[0]
                    )
                ),
                v[0], r[0], s[0]
            ),
            "Permission denied from approving address."
        );
        require(
            isSigned(
                addressToAdd,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize being added to this Identity.",
                        ein, addressToAdd, timestamp[1]
                    )
                ),
                v[1], r[1], s[1]
            ),
            "Permission denied from address to add."
        );

        addAssociatedAddress(ein, addressToAdd);

        emit AssociatedAddressAdded(msg.sender, ein, approvingAddress, addressToAdd, true);
    }

    /// @dev 所有地址添加的通用逻辑。
    function addAssociatedAddress(uint ein, address addressToAdd) private _hasIdentity(addressToAdd, false) {
        require(
            identityDirectory[ein].associatedAddresses.length() < maxAssociatedAddresses, "Too many addresses."
        );

        identityDirectory[ein].associatedAddresses.insert(addressToAdd);
        associatedAddressDirectory[addressToAdd] = ein;
    }

    /// @notice 允许解除以太坊交易发送地址的和自己数字身份的关联性。
    function removeAssociatedAddress() public {
        uint ein = getEIN(msg.sender);

        removeAssociatedAddress(ein, msg.sender);

        emit AssociatedAddressRemoved(msg.sender, ein, msg.sender, false);
    }

    /// @notice 允许从一个身份删除一个关联地址。
    /// @param addressToRemove 要从身份删除的关联地址。
    /// @param v 签名的v值。
    /// @param r 签名的r值。
    /// @param s 签名的s值。
    /// @param timestamp 签名的时间戳。
    function removeAssociatedAddressDelegated(address addressToRemove, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        public ensureSignatureTimeValid(timestamp)
    {
        uint ein = getEIN(addressToRemove);

        require(
            isSigned(
                addressToRemove,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize removing this address from my Identity.",
                        ein, addressToRemove, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        removeAssociatedAddress(ein, addressToRemove);

        emit AssociatedAddressRemoved(msg.sender, ein, addressToRemove, true);
    }

    /// @dev 删除地址的通用逻辑。
    function removeAssociatedAddress(uint ein, address addressToRemove) private {
        identityDirectory[ein].associatedAddresses.remove(addressToRemove);
        delete associatedAddressDirectory[addressToRemove];
    }


    /// @notice 允许一个关联地址为它的身份添加一组`Provider`
    /// @param providers `Provider`数组。
    function addProviders(address[] memory providers) public {
        addProviders(getEIN(msg.sender), providers, false);
    }

    /// @notice 允许`Provider`为它的数字身份添加`Provider`
    /// @param ein 要被添加`Provdier`的EIN
    /// @param providers `Provider`数组。
    function addProvidersFor(uint ein, address[] memory providers) public _isProviderFor(ein) {
        addProviders(ein, providers, true);
    }

    /// @dev `Provider`添加的通用逻辑。
    function addProviders(uint ein, address[] memory providers, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];
        for (uint i; i < providers.length; i++) {
            _identity.providers.insert(providers[i]);
            emit ProviderAdded(msg.sender, ein, providers[i], delegated);
        }
    }

    /// @notice 允许一个关联地址为它的身份删除一组`Provider`
    /// @param providers `Provider`数组。
    function removeProviders(address[] memory providers) public {
        removeProviders(getEIN(msg.sender), providers, false);
    }

    /// @notice 允许`Provider`为它的数字身份删除`Provider`
    /// @param ein 要被删除`Provdier`的EIN
    /// @param providers `Provider`数组。
    function removeProvidersFor(uint ein, address[] memory providers) public _isProviderFor(ein) {
        removeProviders(ein, providers, true);
    }

    /// @dev `Provider`删除的通用逻辑。
    function removeProviders(uint ein, address[] memory providers, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];
        for (uint i; i < providers.length; i++) {
            _identity.providers.remove(providers[i]);
            emit ProviderRemoved(msg.sender, ein, providers[i], delegated);
        }
    }

    /// @notice 允许一个关联地址为它的身份添加一组`Resolver`
    /// @param resolvers `Resolver`数组。
    function addResolvers(address[] memory resolvers) public {
        addResolvers(getEIN(msg.sender), resolvers, false);
    }

    /// @notice 允许`Provider`为某个身份添加一组`Resolver`
    /// @param ein 要被添加`Resolver`的EIN
    /// @param resolvers `Resolver`数组。
    function addResolversFor(uint ein, address[] memory resolvers) public _isProviderFor(ein) {
        addResolvers(ein, resolvers, true);
    }

    /// @dev `Resolver`添加的通用逻辑。
    function addResolvers(uint ein, address[] memory resolvers, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];
        for (uint i; i < resolvers.length; i++) {
            _identity.resolvers.insert(resolvers[i]);
            emit ResolverAdded(msg.sender, ein, resolvers[i], delegated);
        }
    }

    /// @notice 允许一个关联地址为它的身份删除一组`Resolver`
    /// @param resolvers `Resolver`数组。
    function removeResolvers(address[] memory resolvers) public {
        removeResolvers(getEIN(msg.sender), resolvers, true);
    }

    /// @notice 允许`Provider`为某个身份删除一组`Resolver`
    /// @param ein 要被删除`Resolver`的EIN
    /// @param resolvers `Resolver`数组。
    function removeResolversFor(uint ein, address[] memory resolvers) public _isProviderFor(ein) {
        removeResolvers(ein, resolvers, true);
    }

    /// @dev `Resolver`删除的通用逻辑。
    function removeResolvers(uint ein, address[] memory resolvers, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];
        for (uint i; i < resolvers.length; i++) {
            _identity.resolvers.remove(resolvers[i]);
            emit ResolverRemoved(msg.sender, ein, resolvers[i], delegated);
        }
    }


    // 身份恢复管理函数 ///////////////////////////////////////////////////////////////////////////////////

    /// @notice 允许一个管理地址改变它的身份的恢复地址。
    /// @dev 每`recoveryTimeout`秒内最多可以更改一次恢复地址。
    /// @param newRecoveryAddress 要被设为交易发送者身份的新恢复地址的地址。
    function triggerRecoveryAddressChange(address newRecoveryAddress) public {
        triggerRecoveryAddressChange(getEIN(msg.sender), newRecoveryAddress, false);
    }

    /// @notice 允许`Provider`修改某个身份的恢复地址。
    /// @dev 每`recoveryTimeout`秒内最多可以更改一次恢复地址。
    /// @param ein 要被重设恢复地址的EIN
    /// @param newRecoveryAddress 要被设为传入的EIN的新恢复地址的地址。
    function triggerRecoveryAddressChangeFor(uint ein, address newRecoveryAddress) public _isProviderFor(ein) {
        triggerRecoveryAddressChange(ein, newRecoveryAddress, true);
    }

    /// @dev 恢复地址更改的通用逻辑。
    function triggerRecoveryAddressChange(uint ein, address newRecoveryAddress, bool delegated) private {
        Identity storage _identity = identityDirectory[ein];

        require(canChangeRecoveryAddress(ein), "Cannot trigger a change in recovery address yet.");

         // solium-disable-next-line security/no-block-members
        recoveryAddressChangeLogs[ein] = RecoveryAddressChange(block.timestamp, _identity.recoveryAddress);

        emit RecoveryAddressChangeTriggered(msg.sender, ein, _identity.recoveryAddress, newRecoveryAddress, delegated);

        _identity.recoveryAddress = newRecoveryAddress;
    }

    /// @notice 允许恢复地址触发它的身份的恢复流程。
    /// @dev `msg.sender`必须是身份的当前恢复地址，或者是最近被更改的上一个恢复地址。
    /// @param ein 要被触发恢复流程的EIN
    /// @param newAssociatedAddress 要被设为传入的EIN的新恢复地址的地址。
    /// @param v 签名的v值。
    /// @param r 签名的r值。
    /// @param s 签名的s值。
    /// @param timestamp 签名的时间戳。
    function triggerRecovery(uint ein, address newAssociatedAddress, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        public _identityExists(ein) _hasIdentity(newAssociatedAddress, false) ensureSignatureTimeValid(timestamp)
    {
        require(canRecover(ein), "Cannot trigger recovery yet.");
        Identity storage _identity = identityDirectory[ein];

        // 确保发送者是身份的当前恢复地址，或者是最近被更改的上一个恢复地址。
        if (canChangeRecoveryAddress(ein)) {
            require(
                msg.sender == _identity.recoveryAddress, "Only the current recovery address can trigger recovery."
            );
        } else {
            require(
                msg.sender == recoveryAddressChangeLogs[ein].oldRecoveryAddress,
                "Only the recently removed recovery address can trigger recovery."
            );
        }

        require(
            isSigned(
                newAssociatedAddress,
                keccak256(
                    abi.encodePacked(
                        byte(0x19), byte(0), address(this),
                        "I authorize being added to this Identity via recovery.",
                        ein, newAssociatedAddress, timestamp
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );

        // 记录记录旧的关联地址，以便在必要时进行身份销毁
        recoveryLogs[ein] = Recovery(
            block.timestamp, // solium-disable-line security/no-block-members
            keccak256(abi.encodePacked(_identity.associatedAddresses.members))
        );

        emit RecoveryTriggered(msg.sender, ein, _identity.associatedAddresses.members, newAssociatedAddress);

        // 删除身份数据，并将新地址添加为唯一的关联地址
        resetIdentityData(_identity, msg.sender, false);
        addAssociatedAddress(ein, newAssociatedAddress);
    }

    /// @notice 允许最近被恢复流程删除的关联地址永久禁用其旧的身份。
    /// @param ein 要被销毁的数字身份的EIN
    /// @param firstChunk 恢复流程触发前，身份关联地址数组中`msg.sender`之前的关联地址数组。
    /// @param lastChunk 恢复流程触发前，身份关联地址数组中`msg.sender`之后的关联地址数组。
    /// @param resetResolvers 如果身份要删除`Resolver`设为 true 否则设为 false
    function triggerDestruction(uint ein, address[] memory firstChunk, address[] memory lastChunk, bool resetResolvers)
        public _identityExists(ein)
    {
        require(!canRecover(ein), "Recovery has not recently been triggered.");
        Identity storage _identity = identityDirectory[ein];

        // 确保`msg.sender`是EIN引用身份的旧关联地址
        address payable[1] memory middleChunk = [msg.sender];
        require(
            keccak256(
                abi.encodePacked(firstChunk, middleChunk, lastChunk)
            ) == recoveryLogs[ein].hashedOldAssociatedAddresses,
            "Cannot destroy an EIN from an address that was not recently removed from said EIN via recovery."
        );

        emit IdentityDestroyed(msg.sender, ein, _identity.recoveryAddress, resetResolvers);

        resetIdentityData(_identity, address(0), resetResolvers);
    }

    /// @dev 清除身份数据的通用逻辑。
    function resetIdentityData(Identity storage identity, address newRecoveryAddress, bool resetResolvers) private {
        for (uint i; i < identity.associatedAddresses.members.length; i++) {
            delete associatedAddressDirectory[identity.associatedAddresses.members[i]];
        }
        delete identity.associatedAddresses;
        delete identity.providers;
        if (resetResolvers) delete identity.resolvers;
        identity.recoveryAddress = newRecoveryAddress;
    }


    // 事件 //////////////////////////////////////////////////////////////////////////////////////////////////////////

    event IdentityCreated(
        address indexed initiator, uint indexed ein,
        address recoveryAddress, address associatedAddress, address[] providers, address[] resolvers, bool delegated
    );
    event AssociatedAddressAdded(
        address indexed initiator, uint indexed ein, address approvingAddress, address addedAddress, bool delegated
    );
    event AssociatedAddressRemoved(address indexed initiator, uint indexed ein, address removedAddress, bool delegated);
    event ProviderAdded(address indexed initiator, uint indexed ein, address provider, bool delegated);
    event ProviderRemoved(address indexed initiator, uint indexed ein, address provider, bool delegated);
    event ResolverAdded(address indexed initiator, uint indexed ein, address resolvers, bool delegated);
    event ResolverRemoved(address indexed initiator, uint indexed ein, address resolvers, bool delegated);
    event RecoveryAddressChangeTriggered(
        address indexed initiator, uint indexed ein,
        address oldRecoveryAddress, address newRecoveryAddress, bool delegated
    );
    event RecoveryTriggered(
        address indexed initiator, uint indexed ein, address[] oldAssociatedAddresses, address newAssociatedAddress
    );
    event IdentityDestroyed(address indexed initiator, uint indexed ein, address recoveryAddress, bool resolversReset);
}