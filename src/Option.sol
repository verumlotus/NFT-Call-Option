// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@oz/token/ERC721/IERC721Receiver.sol";
import "@oz/token/ERC721/IERC721.sol";
import "@oz/token/ERC20/IERC20.sol";
import "@oz/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20Permit.sol";

/**
 * @title NFT Call Option
 * @author verum
 */
contract Option is IERC721Receiver {
    using SafeERC20 for IERC20;
    /************************************************
     *  STORAGE
    ***********************************************/
    // flag whether NFT has been deposited to contract
    bool public nftDeposited;

    /// @notice creator of the contract
    address public seller;

    /// @notice buyer of the option
    address public buyer;

    /// @notice address of NFT contract
    address public underlying;

    /// @notice index of the NFT 
    uint256 public tokenId;

    /************************************************
     *  IMMUTABLES & CONSTANTS
    ***********************************************/

    /// @notice ERC20 (likely a stablecoin) in which the premium & strike is denominated
    address public immutable quoteToken;

    /// @notice strike price specified in underlyingDenomination
    uint256 public immutable strike;

    /// @notice premium specified in underlyingDenomination
    uint256 public immutable premium;

    ///@notice expiry of contract
    uint256 public immutable expiry;

    struct PermitData {
        uint deadline; 
        uint8 v; 
        bytes32 r;
        bytes32 s;
    }

    /************************************************
     *  EVENTS, ERRORS, MODIFIERS
    ***********************************************/
    /// Emit when NFT is transferred to this contract
    event NftDeposited(address indexed from, address indexed underlying, uint256 tokenId);

    event OptionPurchased(address indexed buyer);

    event OptionExercised();

    modifier onlySeller {
        require(msg.sender == seller, "only seller");
        _;
    }

    /**
     * @notice initializes the contract with the specified parameters, but does not actually receive the NFT
     * @param _quoteToken - quote token for denominations
     * @param _strike strike price
     * @param _premium premium for option
     * @param _expiry expiry at a specific Unix timestamp
     */
    constructor(address _quoteToken, uint256 _strike, uint256 _premium, uint256 _expiry) {
        quoteToken = _quoteToken;
        strike = _strike;
        premium = _premium;
        expiry = _expiry;
        seller = msg.sender;
    }

    /**
     * @notice Deposits the underlying NFT to this contract
     * @dev approve() should be called before invoking this function
     * @param _underlying - underlying NFT address
     * @param _tokenId - ID of the token that the sender owns 
     */
    function deposit(address _underlying, uint256 _tokenId) onlySeller external {
        require(!nftDeposited, "can only deposit once");
        nftDeposited = true;
        underlying = _underlying;
        tokenId = _tokenId;

        // Assumes revert on failed transfer
        IERC721(_underlying).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit NftDeposited(msg.sender, _underlying, _tokenId);
    }

    /**
     * @notice purchases the call option 
     * @dev approve() should be called before invoking this function OR a permitSignature can be passed in 
     * @param _permitData - info for ERC20-Permit; can be empty byte if approve() was called
     */
    function purchaseCall(bytes calldata _permitData) external {
        require(buyer == address(0), "option has already been purchased");
        require(nftDeposited, "No NFT has been deposited yet");

        if (_permitData.length > 0) {
            PermitData memory permitData = abi.decode(_permitData, (PermitData));
            IERC20Permit(quoteToken).permit(
                msg.sender, address(this), premium, permitData.deadline, permitData.v, permitData.r, permitData.s
            );
        }

        // Transfer premium straight to seller
        IERC20(quoteToken).safeTransferFrom(msg.sender, seller, premium);

        // Update state
        buyer = msg.sender;
        emit OptionPurchased(msg.sender);
    }

    /**
     * @notice Allows the purchaser of the call option to buy underlying NFT
     * @dev approve() should be called before invoking this function OR a permitSignature can be passed in 
     * @param _permitData - info for ERC20-Permit; can be empty byte if approve() was called
     */
    function exerciseOption(bytes calldata _permitData) external {
        require(msg.sender == buyer, "Only buyer can exercise option");
        require(block.timestamp <= expiry, "Option has expired");

        if (_permitData.length > 0) {
            PermitData memory permitData = abi.decode(_permitData, (PermitData));
            IERC20Permit(quoteToken).permit(
                msg.sender, address(this), strike, permitData.deadline, permitData.v, permitData.r, permitData.s
            );
        }

        // Transfer strike straight to seller
        IERC20(quoteToken).safeTransferFrom(msg.sender, seller, strike);

        // Transfer underlying NFT to the buyer
        IERC721(underlying).safeTransferFrom(address(this), msg.sender, tokenId);

        emit OptionExercised();
    }

    /**
     * @notice Allows the seller to close the option & withdraw NFT if option is past expiry or there is no buyer 
     */
    function closeOption() external onlySeller {
        require(block.timestamp > expiry || buyer == address(0), "Option has not expired yet");
        // Transfer NFT back to seller
        IERC721(underlying).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(address, address, uint256, bytes memory) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
