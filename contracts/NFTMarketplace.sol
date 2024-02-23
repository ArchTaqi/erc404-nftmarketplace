// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Interface/IDN404.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract NFTMarketplace is Context {
    // track no. of listings on marketplace
    uint256 private counter;

    // structure of an NFT listing, price and seller
    struct Listing {
        uint256 price;
        address seller;
    }

    /***********************/
    /*  State Variables    */
    /***********************/

    // This mapping is used to store the listings of NFTs in the marketplace. Key is address of NFT contract and value is NFT listings, price and seller.
    mapping(address => Listing) private s_listings;
    // This mapping is used to keep track of the proceeds earned by each seller from NFT sales in the marketplace. Key is the seller address and value is the earning.
    mapping(address => uint256) private s_proceeds;

    error PriceNotMet(address nftAddress, uint256 price);
    error ItemNotForSale(address nftAddress);
    error NotListed(address nftAddress);
    error AlreadyListed(address nftAddress);
    error NoProceeds();
    error NotOwner();
    error NotApprovedForMarketplace();
    error PriceMustBeAboveZero();
    error NotApproved();

    /**
     * @dev emitted when an NFT is listed for sale in the marketplace.
     * @param seller address of the seller who listed the NFT. The indexed keyword allows filtering events based on this parameter.
     * @param nftAddress address of the NFT being listed
     * @param price price at which the NFT is listed
     */
    event LogItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 price
    );

    /**
     * @dev emitted when a listed NFT is canceled by the seller
     * @param seller address of the seller who canceled the listing
     * @param nftAddress address of the NFT that was canceled
     */
    event LogItemCanceled(address indexed seller, address indexed nftAddress);

    /**
     * @dev emitted when an NFT is bought from the marketplace
     * @param buyer address of the buyer who purchased the NFT. The indexed keyword allows filtering events based on this parameter.
     * @param nftAddress address of the NFT that was bought. The indexed keyword allows filtering events based on this parameter
     * @param price Represents the price at which the NFT was bought
     * @param fraction Represents some fraction or portion of the NFT bought. This parameter might be used if the NFT is divided into fractions or shares
     */
    event LogItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 price,
        uint256 fraction
    );

    // Function modifiers
    modifier isListed(address nftAddress) {
        Listing memory listing = s_listings[nftAddress];
        require(listing.price > 0, "Not listed");
        _;
    }
    modifier notListed(address nftAddress) {
        Listing memory listing = s_listings[nftAddress];
        require(listing.price == 0, "Already listed");
        _;
    }
    modifier isOwner(address nftAddress, address spender) {
        IDN404 nft = IDN404(nftAddress);
        require(nft.balanceOf(spender) > 0, "Not owner");
        _;
    }

    /**
     *
     * @param nftAddress address of the NFT contract
     * @param amount amount of the NFT to be listed
     * @param price price at which to list the NFT
     * @param deadline deadline for the permit
     * @param v parms of signature
     * @param r parms of signature
     * @param s parms of signature
     */
    function listItemWithPermit(
        address nftAddress,
        uint256 amount,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external notListed(nftAddress) {
        // notListed ensuring that the NFT is not already listed before proceeding
        IDN404 nft = IDN404(nftAddress);

        nft.permit(_msgSender(), address(this), amount, deadline, v, r, s);

        if (nft.allowance(_msgSender(), address(this)) < amount) {
            revert NotApproved();
        }

        // Store the listing information
        s_listings[nftAddress] = Listing(price, _msgSender());

        // Emit event
        emit LogItemListed(_msgSender(), nftAddress, price);

        counter++;
    }

    /**
     * @param nftAddress address of the NFT contract to cancel the listing for.
     */
    function cancelListing(
        address nftAddress
    ) external isOwner(nftAddress, _msgSender()) isListed(nftAddress) {
        delete s_listings[nftAddress];
        emit LogItemCanceled(_msgSender(), nftAddress);
    }

    /**
     * @param nftAddress address of the NFT contract to buy
     * @param fraction The fraction or portion of the NFT to buy
     */
    function buyItem(
        address nftAddress,
        uint256 fraction
    ) external payable isListed(nftAddress) {
        Listing memory listedItem = s_listings[nftAddress];
        require(msg.value >= listedItem.price, "Price not met");

        s_proceeds[listedItem.seller] += msg.value;
        delete s_listings[nftAddress];
        IDN404(nftAddress).transferFrom(
            listedItem.seller,
            _msgSender(),
            fraction
        );
        emit LogItemBought(
            _msgSender(),
            nftAddress,
            listedItem.price,
            fraction
        );
    }

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[_msgSender()];
        require(proceeds > 0, "No proceeds");
        s_proceeds[_msgSender()] = 0;

        (bool success, ) = payable(_msgSender()).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    /**
     *
     * @param nftAddress address of the NFT contract.
     */
    function getListing(
        address nftAddress
    ) external view returns (Listing memory) {
        return s_listings[nftAddress];
    }

    /**
     *
     * @param seller address of the seller
     */
    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }

    function numListings() external view returns (uint256) {
        return counter;
    }
}
