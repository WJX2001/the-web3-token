// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * 发行的代币需求
 *  1. 合约恶客
 */

contract TheWebThree is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable
{
    uint256 public number;
    // 代币名称
    string private constant NAME = "TheWebThreeToken";

    // 代币符号
    string private constant SYMBOL = "TWT";

    // 增发的最小时间间隔 1年一次
    uint256 public constant MIN_MINT_INTERVAL = 365 days;

    // 百分比的百分比精度
    uint256 public constant MINT_CAP_DENOMINATOR = 10_000;

    // 增发上限的最大分子
    uint256 public constant MINT_CAP_MAX_NUMERATOR = 200;

    // 当前的增发比例 比如设置200 就是 2%
    uint256 public mintCapNumerator;

    // 下一次允许增发的时间戳
    uint256 public nextMint;

    error TheWeb3Token_ImproperlyInitialized();

    error TheWeb3Token_MintAmountTooLarge(uint256 amount, uint256 maximumAmount);

    error TheWeb3Token_NextMintTimestampNotElapsed(uint256 currentTimestamp, uint256 nextMintTimestamp);

    error TheWeb3Token_MintCapNumeratorTooLarge(uint256 numberator, uint256 maximumNumerator);

    event MintCapNumeratorChanged(address indexed from, uint256 previousMintCapNumerator, uint256 newMintCapNumerator);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _initialSupply,
        address _owner
    ) public initializer {
        if (_initialSupply == 0 || _owner == address(0))
            revert TheWeb3Token_ImproperlyInitialized();

        // 检查初始供应量和 owner 地址不能为空
        __ERC20_init(NAME, SYMBOL);
        // 初始化父合约
        __ERC20Burnable_init();
        __Ownable_init(_owner);

        // 给owner 铸造初始供应量
        _mint(_owner, _initialSupply);

        // 设置下一次允许增发的时间戳
        nextMint = block.timestamp + MIN_MINT_INTERVAL;

        // 将合约owner 设置为 _owner
        _transferOwnership(_owner);
    }

    // 增发函数（带限制）
    /**
     *  _recipient 接收新增铸造代币的地址（收币人）
     *  _amount 铸造的代币数量
     */
    function mint(address _recipient, uint256 _amount) public onlyOwner { // 只有 owner 可以调用
        // 计算当前最大可增发额度，比如当前总供应 10000 mintCapNumerator = 200，那么最大增发是  10000 * 200 / 10000 = 200（2%）。
        uint256 maximumMintAmount = (totalSupply() * mintCapNumerator) / MINT_CAP_DENOMINATOR;

        // 如果超过最大增发量 直接revert
        if (_amount > maximumMintAmount) {
            revert TheWeb3Token_MintAmountTooLarge(_amount, maximumMintAmount);
        }

        // 增发时间没到 禁止增发
        if (block.timestamp < nextMint) revert TheWeb3Token_NextMintTimestampNotElapsed(block.timestamp, nextMint);

        // 更新下一次增发时间
        nextMint = block.timestamp + MIN_MINT_INTERVAL;

        // 正式执行增发
        super._mint(_recipient,_amount);

    }

    // 设置代币的年度增发上限百分比
    function setMintCapNumberator(uint256 _mintCapNumerator) public onlyOwner {
        // 上限校验
        if(_mintCapNumerator > MINT_CAP_MAX_NUMERATOR) {
            revert TheWeb3Token_MintCapNumeratorTooLarge(_mintCapNumerator, MINT_CAP_MAX_NUMERATOR);
        }
        // 触发事件
        emit MintCapNumeratorChanged(msg.sender, mintCapNumerator, _mintCapNumerator);
        // 状态更新
        mintCapNumerator = _mintCapNumerator;
    }
}
