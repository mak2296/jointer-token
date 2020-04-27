pragma solidity ^0.5.9;
import "../common/RegisteryOwnable.sol";
import "../Proxy/IRegistry.sol";
import "../Proxy/UpgradeabilityProxy.sol";

interface InitializeInterface {
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _primaryOwner,
        address _systemAddress,
        address _authorityAddress,
        address _registeryAddress,
        uint256 _tokenPrice,
        uint256 _tokenMaturityDays,
        uint256 _tokenHoldBackDays
    ) external;
    
    function premint(address[] calldata _which,uint256[] calldata _amount) external;
}




/**
 * @title Registry
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 */
contract SuperTokenRegistry is RegisteryOwnable, IRegistry {
    // Mapping of versions to implementations of different functions
    mapping(uint256 => address) internal versions;   
     
    uint256 public currentVersion;
    
    address payable public proxyAddress;

    //@dev constructor
    //@param _systemAddress address of the system Owner
    constructor(address _systemAddress, address _multisigAddress)
        public
        RegisteryOwnable(_systemAddress, _multisigAddress)
    {}

    /**
     * @dev Registers a new version with its implementation address
     * @param version representing the version name of the new implementation to be registered
     * @param implementation representing the address of the new implementation to be registered
     */
    function addVersion(uint256 version, address implementation)
        public
        onlyOneOfOnwer()
        notZeroAddress(implementation)
    {
        require(
            versions[version] == address(0),
            "This version has implementation attached"
        );
        versions[version] = implementation;
        emit VersionAdded(version, implementation);
    }

    /**
     * @dev Tells the address of the implementation for a given version
     * @param version to query the implementation of
     * @return address of the implementation registered for the given version
     */
    function getVersion(uint256 version) public view returns (address) {
        return versions[version];
    }
    
    //function setTokenDetails()
    
    /**
     * @dev Creates an upgradeable proxy
     * @param version representing the first version to be set for the proxy
     * @return address of the new proxy created
     */
    function createProxy(
        string memory _name,
        string memory _symbol,
        address _primaryOwner,
        address _systemAddress,
        address _authorityAddress,
        address _registeryAddress,
        uint256 _tokenPrice,
        uint256 _tokenMaturityDays,
        uint256 _tokenHoldBackDays,
        address[] memory _which,
        uint256[] memory _amount,
        uint256 version
    ) public onlyOneOfOnwer() 
    

    returns (address) {
        
        require(proxyAddress == address(0),"ERR_PROXY_ALREADY_CREATED");
        
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(version);
        
        InitializeInterface(address(proxy)).initialize(
            _name,
            _symbol,
            _primaryOwner,
            _systemAddress,
            _authorityAddress,
            _registeryAddress,
            _tokenPrice,
            _tokenMaturityDays,
            _tokenHoldBackDays
        );
        InitializeInterface(address(proxy)).premint(
            _which,_amount
        );
        
        currentVersion = version;
        proxyAddress = address(proxy);
        emit ProxyCreated(address(proxy));
        return address(proxy);
    }
    

    /**
     * @dev Upgrades the implementation to the requested version
     * @param version representing the version name of the new implementation to be set
     */
    
    function upgradeTo(uint256 version) public onlyAuthorized() returns(bool) {
        currentVersion = version;
        UpgradeabilityProxy(proxyAddress).upgradeTo(version);
        return true;
    }
    
}