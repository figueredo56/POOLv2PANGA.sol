// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Basic ERC20 / BEP20 standard interface
  */
  interface IERC20 {
      function totalSupply() external view returns (uint256);
          function balanceOf(address account) external view returns (uint256);
              function transfer(address to, uint256 amount) external returns (bool);
                  function allowance(address owner, address spender) external view returns (uint256);
                      function approve(address spender, uint256 amount) external returns (bool);
                          function transferFrom(address from, address to, uint256 amount) external returns (bool);
                              
                                  event Transfer(address indexed from, address indexed to, uint256 value);
                                      event Approval(address indexed owner, address indexed spender, uint256 value);
                                      }

                                      /**
                                       * @dev Contract module which provides a basic access control mechanism (Owner)
                                        */
                                        abstract contract Ownable {
                                            address private _owner;

                                                event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

                                                    constructor() {
                                                            _owner = msg.sender;
                                                                    emit OwnershipTransferred(address(0), msg.sender);
                                                                        }

                                                                            function owner() public view virtual returns (address) {
                                                                                    return _owner;
                                                                                        }

                                                                                            modifier onlyOwner() {
                                                                                                    require(owner() == msg.sender, "Ownable: caller is not the owner");
                                                                                                            _;
                                                                                                                }

                                                                                                                    function renounceOwnership() public virtual onlyOwner {
                                                                                                                            emit OwnershipTransferred(_owner, address(0));
                                                                                                                                    _owner = address(0);
                                                                                                                                        }
                                                                                                                                        }

                                                                                                                                        /**
                                                                                                                                         * @dev Token Z featuring compatibility for PancakeSwap V2 and PinkLock whitelisting
                                                                                                                                          */
                                                                                                                                          contract TokenZ is IERC20, Ownable {
                                                                                                                                              mapping(address => uint256) private _balances;
                                                                                                                                                  mapping(address => mapping(address => uint256)) private _allowances;

                                                                                                                                                      // Mapping to whitelist/exclude specific addresses from taxes, fees, or limits
                                                                                                                                                          mapping(address => bool) private _isExcludedFromFees;

                                                                                                                                                              string private _name = "Z";
                                                                                                                                                                  string private _symbol = "Z";
                                                                                                                                                                      uint8 private _decimals = 18;
                                                                                                                                                                          uint256 private _totalSupply;

                                                                                                                                                                              // Optional transfer limit variables that usually cause PinkLock buttons to freeze
                                                                                                                                                                                  uint256 public maxTransactionAmount; 

                                                                                                                                                                                      constructor() {
                                                                                                                                                                                              // 100 total supply with 18 decimals = 100 * 10**18
                                                                                                                                                                                                      uint256 totalTokens = 100;
                                                                                                                                                                                                              _totalSupply = totalTokens * 10**uint256(_decimals);
                                                                                                                                                                                                                      
                                                                                                                                                                                                                              _balances[msg.sender] = _totalSupply;
                                                                                                                                                                                                                                      
                                                                                                                                                                                                                                              // Exclude deployer and contract itself from fees/limits by default
                                                                                                                                                                                                                                                      _isExcludedFromFees[msg.sender] = true;
                                                                                                                                                                                                                                                              _isExcludedFromFees[address(this)] = true;

                                                                                                                                                                                                                                                                      // Set a default high max transaction limit (e.g., 5% of total supply) to prevent initial transfer failures
                                                                                                                                                                                                                                                                              maxTransactionAmount = _totalSupply * 5 / 100; 

                                                                                                                                                                                                                                                                                      emit Transfer(address(0), msg.sender, _totalSupply);
                                                                                                                                                                                                                                                                                          }

                                                                                                                                                                                                                                                                                              function name() public view returns (string memory) { return _name; }
                                                                                                                                                                                                                                                                                                  function symbol() public view returns (string memory) { return _symbol; }
                                                                                                                                                                                                                                                                                                      function decimals() public view returns (uint8) { return _decimals; }
                                                                                                                                                                                                                                                                                                          function totalSupply() public view override returns (uint256) { return _totalSupply; }
                                                                                                                                                                                                                                                                                                              function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

                                                                                                                                                                                                                                                                                                                  function transfer(address to, uint256 amount) public override returns (bool) {
                                                                                                                                                                                                                                                                                                                          _transfer(msg.sender, to, amount);
                                                                                                                                                                                                                                                                                                                                  return true;
                                                                                                                                                                                                                                                                                                                                      }

                                                                                                                                                                                                                                                                                                                                          function allowance(address owner, address spender) public view override returns (uint256) {
                                                                                                                                                                                                                                                                                                                                                  return _allowances[owner][spender];
                                                                                                                                                                                                                                                                                                                                                      }

                                                                                                                                                                                                                                                                                                                                                          function approve(address spender, uint256 amount) public override returns (bool) {
                                                                                                                                                                                                                                                                                                                                                                  _approve(msg.sender, spender, amount);
                                                                                                                                                                                                                                                                                                                                                                          return true;
                                                                                                                                                                                                                                                                                                                                                                              }

                                                                                                                                                                                                                                                                                                                                                                                  function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
                                                                                                                                                                                                                                                                                                                                                                                          _approve(from, msg.sender, _allowances[from][msg.sender] - amount);
                                                                                                                                                                                                                                                                                                                                                                                                  _transfer(from, to, amount);
                                                                                                                                                                                                                                                                                                                                                                                                          return true;
                                                                                                                                                                                                                                                                                                                                                                                                              }

                                                                                                                                                                                                                                                                                                                                                                                                                  // CRITICAL FUNCTION: Whitelists PinkLock contract address to clear restrictions
                                                                                                                                                                                                                                                                                                                                                                                                                      function setExcludedFromFees(address account, bool excluded) external onlyOwner {
                                                                                                                                                                                                                                                                                                                                                                                                                              _isExcludedFromFees[account] = excluded;
                                                                                                                                                                                                                                                                                                                                                                                                                                  }

                                               
