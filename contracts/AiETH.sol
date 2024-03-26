// SPDX-License-Identifier: MIT

//      ██████      ███ ██████ ███████████ ███      ███
//    ███    ███        ██         ███     ███      ███
//   ███      ███   ███ ██████     ███     ████████████
//  ███ ██████ ███  ███ ██         ███     ███      ███
// ███          ███ ███ ██████     ███     ███      ███

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract AiEth is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    AccessControl,
    ERC20Permit
{
    uint256 public maxSupply;
    uint256 public APR;
    address public PRESALE_ADDRESS;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bool private _presaleIsActive = false;

    // Array to store the combination of name, wallet, and percentage for each service
    struct ServiceInfo {
        string name;
        address wallet;
        uint256 percentage;
    }

    // Defining the services
    ServiceInfo[] public reserveServices;
    ServiceInfo[] public airDropServices;
    ServiceInfo[] public rewardServices;
    ServiceInfo[] public publicPresaleServices;
    ServiceInfo[] public privatePresaleServices;
    ServiceInfo[] public liquidityWarrantyServices;
    ServiceInfo[] public developmentServices;
    ServiceInfo[] public marketingServices;

    constructor(
        uint256 setMaxSupply,
        uint256 setAPR
    ) ERC20("aiETH", "aiETH") ERC20Permit("aiETH") {
        // Defining Roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Defining the MaxSupply
        maxSupply = setMaxSupply;

        //Defining the APR percentage
        APR = setAPR;

        // Setting the name, wallet, and percentage for each service
        reserveServices.push(
            ServiceInfo(
                "Strategic Reserve",
                0x43868b067F57E44FB4a40F84f1681b9eA0ee20A1,
                40
            )
        );
        airDropServices.push(
            ServiceInfo(
                "AirDrops and Presale Bonus",
                0xdBCa77CAF4E76C4E6B527CCe8480BF2639bd3134,
                40
            )
        );
        rewardServices.push(
            ServiceInfo("Unminted for Staking LP Rewards", msg.sender, 250)
        );
        publicPresaleServices.push(
            ServiceInfo(
                "Public Presale",
                0x9C49484ab6e0fb6d4FBB8dDE48a265301A1F39e9,
                250
            )
        );
        privatePresaleServices.push(
            ServiceInfo(
                "Seed Funding Presale",
                0x56AaecC2CB3657c3373065a21f775B4Da191E22b,
                25
            )
        );
        liquidityWarrantyServices.push(
            ServiceInfo(
                "Liquidity Warranty for Dexs",
                0xFbbb58F21215989861Db1D88E3d8c69b17836C97,
                275
            )
        );
        marketingServices.push(
            ServiceInfo(
                "Marketing Fund",
                0x79d1116620e7A885edD3c3746D456d7dbcf5cd99,
                60
            )
        );
        developmentServices.push(
            ServiceInfo(
                "Development and Security Progress Fund",
                0x1Fb4933b41573972202E2f6D501Ff8d0567257B2,
                60
            )
        );

        // Mint the initial supply
        _initalSupply();
    }

    // Modifiers

    // Verify the max Supply before mint
    modifier checkMaxSupply(uint256 amount) {
        require(totalSupply() + amount <= maxSupply, "Exceeds maximum supply");
        _;
    }

    // Initial Supply
    function _initalSupply() private {
        _mint(
            reserveServices[0].wallet,
            (maxSupply * reserveServices[0].percentage) / 1000
        );
        _mint(
            airDropServices[0].wallet,
            (maxSupply * airDropServices[0].percentage) / 1000
        );
        _mint(
            publicPresaleServices[0].wallet,
            (maxSupply * publicPresaleServices[0].percentage) / 1000
        );
        _mint(
            privatePresaleServices[0].wallet,
            (maxSupply * privatePresaleServices[0].percentage) / 1000
        );
        _mint(
            liquidityWarrantyServices[0].wallet,
            (maxSupply * liquidityWarrantyServices[0].percentage) / 1000
        );
        _mint(
            marketingServices[0].wallet,
            (maxSupply * marketingServices[0].percentage) / 1000
        );
        _mint(
            developmentServices[0].wallet,
            (maxSupply * developmentServices[0].percentage) / 1000
        );
    }

    // Functions to update services
    function updateReserveServices(
        address wallet,
        uint256 percentage
    ) public onlyRole(MANAGER_ROLE) {
        require(
            percentage +
                airDropServices[0].percentage +
                rewardServices[0].percentage +
                publicPresaleServices[0].percentage +
                privatePresaleServices[0].percentage +
                liquidityWarrantyServices[0].percentage +
                developmentServices[0].percentage +
                marketingServices[0].percentage <=
                1000,
            "Exceeds maximum percentage"
        );
        delete reserveServices;
        reserveServices.push(
            ServiceInfo("Strategic Reserve", wallet, percentage)
        );
        emit ServiceUpdated("Strategic Reserve", percentage, wallet);
    }

    function updateAirDropServices(
        address wallet,
        uint256 percentage
    ) public onlyRole(MANAGER_ROLE) {
        require(
            reserveServices[0].percentage +
                percentage +
                rewardServices[0].percentage +
                publicPresaleServices[0].percentage +
                privatePresaleServices[0].percentage +
                liquidityWarrantyServices[0].percentage +
                developmentServices[0].percentage +
                marketingServices[0].percentage <=
                1000,
            "Exceeds maximum percentage"
        );
        delete airDropServices;
        airDropServices.push(
            ServiceInfo("AirDrops and Presale Bonus", wallet, percentage)
        );
        emit ServiceUpdated("AirDrops and Presale Bonus", percentage, wallet);
    }

    function updateRewardServices(
        address wallet,
        uint256 percentage
    ) public onlyRole(MANAGER_ROLE) {
        require(
            reserveServices[0].percentage +
                airDropServices[0].percentage +
                percentage +
                publicPresaleServices[0].percentage +
                privatePresaleServices[0].percentage +
                liquidityWarrantyServices[0].percentage +
                developmentServices[0].percentage +
                marketingServices[0].percentage <=
                1000,
            "Exceeds maximum percentage"
        );
        delete rewardServices;
        rewardServices.push(
            ServiceInfo("Unminted for Staking LP Rewards", wallet, percentage)
        );
        emit ServiceUpdated(
            "Unminted for Staking LP Rewards",
            percentage,
            wallet
        );
    }

    function updatePublicPresaleServices(
        address wallet,
        uint256 percentage
    ) public onlyRole(MANAGER_ROLE) {
        require(
            reserveServices[0].percentage +
                airDropServices[0].percentage +
                rewardServices[0].percentage +
                percentage +
                privatePresaleServices[0].percentage +
                liquidityWarrantyServices[0].percentage +
                developmentServices[0].percentage +
                marketingServices[0].percentage <=
                1000,
            "Exceeds maximum percentage"
        );
        delete publicPresaleServices;
        publicPresaleServices.push(
            ServiceInfo("Public Presale", wallet, percentage)
        );
        emit ServiceUpdated("Public Presale", percentage, wallet);
    }

    function updatePrivatePresaleServices(
        address wallet,
        uint256 percentage
    ) public onlyRole(MANAGER_ROLE) {
        require(
            reserveServices[0].percentage +
                airDropServices[0].percentage +
                rewardServices[0].percentage +
                publicPresaleServices[0].percentage +
                percentage +
                liquidityWarrantyServices[0].percentage +
                developmentServices[0].percentage +
                marketingServices[0].percentage <=
                1000,
            "Exceeds maximum percentage"
        );
        delete privatePresaleServices;
        privatePresaleServices.push(
            ServiceInfo("Seed Funding Presale", wallet, percentage)
        );
        emit ServiceUpdated("Seed Funding Presale", percentage, wallet);
    }

    function updateLiquidityWarrantyServices(
        address wallet,
        uint256 percentage
    ) public onlyRole(MANAGER_ROLE) {
        require(
            reserveServices[0].percentage +
                airDropServices[0].percentage +
                rewardServices[0].percentage +
                publicPresaleServices[0].percentage +
                privatePresaleServices[0].percentage +
                percentage +
                developmentServices[0].percentage +
                marketingServices[0].percentage <=
                1000,
            "Exceeds maximum percentage"
        );
        delete liquidityWarrantyServices;
        liquidityWarrantyServices.push(
            ServiceInfo("Liquidity Warranty for Dexs", wallet, percentage)
        );
        emit ServiceUpdated("Liquidity Warranty for Dexs", percentage, wallet);
    }

    function updateMarketingService(
        address wallet,
        uint256 percentage
    ) public onlyRole(MANAGER_ROLE) {
        require(
            reserveServices[0].percentage +
                airDropServices[0].percentage +
                rewardServices[0].percentage +
                publicPresaleServices[0].percentage +
                privatePresaleServices[0].percentage +
                liquidityWarrantyServices[0].percentage +
                developmentServices[0].percentage +
                percentage <=
                1000,
            "Exceeds maximum percentage"
        );
        delete marketingServices;
        marketingServices.push(
            ServiceInfo("Marketing Fund", wallet, percentage)
        );
        emit ServiceUpdated("Marketing Fund", percentage, wallet);
    }

    function updateDevelopService(
        address wallet,
        uint256 percentage
    ) public onlyRole(MANAGER_ROLE) {
        require(
            reserveServices[0].percentage +
                airDropServices[0].percentage +
                rewardServices[0].percentage +
                publicPresaleServices[0].percentage +
                privatePresaleServices[0].percentage +
                liquidityWarrantyServices[0].percentage +
                percentage +
                marketingServices[0].percentage <=
                1000,
            "Exceeds maximum percentage"
        );
        delete developmentServices;
        developmentServices.push(
            ServiceInfo(
                "Development and Security Progress Fund",
                wallet,
                percentage
            )
        );
        emit ServiceUpdated(
            "Development and Security Progress Fund",
            percentage,
            wallet
        );
    }

    // Update APR
    function updateApr(uint256 newApr) public onlyRole(MANAGER_ROLE) {
        require(newApr != APR, "El APR debe ser diferente al actual.");

        APR = newApr;
        emit APRUpdated("APR Updated", newApr);
    }

    // Pause the contract for security
    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    // Unpause the contract for normaly use
    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    // Only can mint the manager
    function mintStakingRewards(
        address account,
        uint256 amount
    ) public onlyRole(MANAGER_ROLE) checkMaxSupply(amount) {
        _mint(account, amount);
    }

    // burn function for only manager
    function burn(uint256 amount) public override onlyRole(MANAGER_ROLE) {
        _burn(_msgSender(), amount);
    }

    // Function to pause transfers during pre-sale
    function transfer(
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(
            !_presaleIsActive || hasRole(MANAGER_ROLE, msg.sender),
            "Transfers are paused during pre-sale"
        );
        return super.transfer(to, amount);
    }

    // Function to update the pre-sale status
    function updatePresaleStatus(bool _status) public onlyRole(MANAGER_ROLE) {
        _presaleIsActive = _status;
        emit PresaleStatus(_status);
    }

    // events
    event ServiceUpdated(
        string serviceName,
        uint256 newPercentage,
        address newWallet
    );
    event APRUpdated(string message, uint256 newApr);
    event PresaleStatus(bool status);

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
