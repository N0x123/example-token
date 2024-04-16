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
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./uniswap/IUniswapV2Router02.sol";
import "./uniswap/IUniswapV2Factory.sol";

contract AiEth is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    AccessControl,
    ERC20Permit
{
    uint256 public maxSupply;
    uint256 public APR;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PRESALE_ROLE = keccak256("PRESALE_ROLE");
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");
    bool private _presaleIsActive = false;

    // Project Wallets
    address public constant reserveWallet =
        address(0x43868b067F57E44FB4a40F84f1681b9eA0ee20A1);
    uint256 public constant reservePercentage = 40;

    address public constant airDropWallet =
        address(0xdBCa77CAF4E76C4E6B527CCe8480BF2639bd3134);
    uint256 public constant airDropPercentage = 40;

    address public constant publicPresaleWallet =
        address(0x9C49484ab6e0fb6d4FBB8dDE48a265301A1F39e9);
    uint256 public constant publicPresalePercentage = 250;

    address public constant privatePresaleWallet =
        address(0x56AaecC2CB3657c3373065a21f775B4Da191E22b);
    uint256 public constant privatePresalePercentage = 25;

    address public constant liquidityWarrantyWallet =
        address(0xFbbb58F21215989861Db1D88E3d8c69b17836C97);
    uint256 public constant liquidityWarrantyPercentage = 275;

    address public constant developmentWallet =
        address(0x1Fb4933b41573972202E2f6D501Ff8d0567257B2);
    uint256 public constant developmentPercentage = 60;

    address public constant marketingWallet =
        address(0x79d1116620e7A885edD3c3746D456d7dbcf5cd99);
    uint256 public constant marketingPercentage = 60;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    address public constant DEAD_WALLET =
        address(0x000000000000000000000000000000000000dEaD);
    address public projectWallet;

    uint16 public buyTax;
    uint16 public sellTax;
    uint16 public projectBuyTax;
    uint16 public projectSellTax;

    bool public takeTax;

    mapping(address => bool) public _isExcludedFromFees;

    mapping(address => bool) public automatedMarketMakerPairs;

    constructor(
        uint256 setMaxSupply,
        uint256 setAPR
    ) ERC20("aiETH", "aiETH") ERC20Permit("aiETH") {
        // Defining Roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PRESALE_ROLE, publicPresaleWallet);

        // granted roles from team
        _grantRole(TEAM_ROLE, reserveWallet);
        _grantRole(TEAM_ROLE, airDropWallet);
        _grantRole(TEAM_ROLE, publicPresaleWallet);
        _grantRole(TEAM_ROLE, privatePresaleWallet);
        _grantRole(TEAM_ROLE, liquidityWarrantyWallet);
        _grantRole(TEAM_ROLE, developmentWallet);
        _grantRole(TEAM_ROLE, marketingWallet);

        // Defining the MaxSupply
        maxSupply = setMaxSupply;

        //Defining the APR percentage
        APR = setAPR;

        // Uniswap Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        buyTax = 1;
        sellTax = 4;
        projectBuyTax = 100;
        projectSellTax = 100;
        projectWallet = publicPresaleWallet;
        takeTax = false;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);

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
        _mint(reserveWallet, (maxSupply * reservePercentage) / 1000);
        _mint(airDropWallet, (maxSupply * airDropPercentage) / 1000);
        _mint(
            publicPresaleWallet,
            (maxSupply * publicPresalePercentage) / 1000
        );
        _mint(
            privatePresaleWallet,
            (maxSupply * privatePresalePercentage) / 1000
        );
        _mint(
            liquidityWarrantyWallet,
            (maxSupply * liquidityWarrantyPercentage) / 1000
        );
        _mint(marketingWallet, (maxSupply * marketingPercentage) / 1000);
        _mint(developmentWallet, (maxSupply * developmentPercentage) / 1000);
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
            !_presaleIsActive || hasRole(TEAM_ROLE, msg.sender),
            "Transfers are paused during pre-sale"
        );
        return super.transfer(to, amount);
    }

    // Function to update the pre-sale status
    function updatePresaleStatus(bool _status) public onlyRole(PRESALE_ROLE) {
        _presaleIsActive = _status;
        emit PresaleStatus(_status);
    }

    // events
    event APRUpdated(string message, uint256 newApr);
    event PresaleStatus(bool status);
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SetBuyTax(uint16 indexed _tax);
    event SetSellTax(uint16 indexed _tax);
    event SetProjectBuyTax(uint16 indexed _tax);
    event SetProjectSellTax(uint16 indexed _tax);
    event SetProjectWallet(address indexed _wallet);
    event SetTakeTax(bool indexed _value);

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    // Uniswap logic functions

    function excludeFromFees(
        address account,
        bool excluded
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setBuyTax(uint16 _tax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tax < 20);
        buyTax = _tax;

        emit SetBuyTax(_tax);
    }

    function setSellTax(uint16 _tax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tax < 20);
        sellTax = _tax;

        emit SetSellTax(_tax);
    }

    function setProjectBuyTax(
        uint16 _tax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tax <= 100);
        projectBuyTax = _tax;

        emit SetProjectBuyTax(_tax);
    }

    function setProjectSellTax(
        uint16 _tax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tax <= 100);
        projectSellTax = _tax;

        emit SetProjectSellTax(_tax);
    }

    function setProjectWallet(
        address _wallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        projectWallet = _wallet;

        emit SetProjectWallet(_wallet);
    }

    function setTakeTax(bool _value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        takeTax = _value;

        emit SetTakeTax(_value);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            pair != uniswapV2Pair,
            "The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    // Logic for taxes
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            !_presaleIsActive || hasRole(TEAM_ROLE, msg.sender),
            "Transfers are paused during pre-sale"
        );

        require(from != DEAD_WALLET, "ERC20: transfer from the dead address");
        if (amount == 0) {
            super._transfer(from, to, amount);
            emit Transfer(from, to, amount);
            return;
        }

        // Buy & Sell Taxes
        if (!takeTax) {
            super._transfer(from, to, amount);
            emit Transfer(from, to, amount);
            return;
        }

        bool _takeTax = true;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            _takeTax = false;
        }

        // Buy or Sell
        if (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) {
            if (_takeTax) {
                if (automatedMarketMakerPairs[from]) {
                    // Buy
                    uint256 _tax = (amount * buyTax) / 100;
                    uint256 _projectTax = (_tax * projectBuyTax) / 100;
                    uint256 _burnTax = _tax - _projectTax;
                    amount = amount - _tax;

                    super._transfer(from, projectWallet, _projectTax);
                    emit Transfer(from, projectWallet, _projectTax);

                    super._transfer(from, DEAD_WALLET, _burnTax);
                    emit Transfer(from, DEAD_WALLET, _burnTax);

                    super._transfer(from, to, amount);
                    emit Transfer(from, to, amount);
                } else if (automatedMarketMakerPairs[to]) {
                    // Sell
                    uint256 _tax = (amount * sellTax) / 100;
                    uint256 _projectTax = (_tax * projectSellTax) / 100;
                    uint256 _burnTax = _tax - _projectTax;
                    amount = amount - _tax;

                    super._transfer(from, projectWallet, _projectTax);
                    emit Transfer(from, projectWallet, _projectTax);

                    super._transfer(from, DEAD_WALLET, _burnTax);
                    emit Transfer(from, DEAD_WALLET, _burnTax);

                    super._transfer(from, to, amount);
                    emit Transfer(from, to, amount);
                }
            } else {
                super._transfer(from, to, amount);
                emit Transfer(from, to, amount);
            }
        } else {
            super._transfer(from, to, amount);
            emit Transfer(from, to, amount);
        }
    }
}
