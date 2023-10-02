// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NftMarketPlace__PriceMustBeAboveZero();
error NftMarketPlace__NotApprovedForMarketPlace();
error NftMarketPlace__AlreadyListed();
error NftMarketPlace__NotOwner();
error NftMarketPlace__PriceNotMet();
error NftMarketPlace__NotListed();
error NftMarketPlace__NotEnoughProceeds();
error NftMarketPlace__WithdrawProceedsFailed();

contract NftMarketPlace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    // mapping from NFT contract address -> NFT token Id -> Listing information
    mapping(address => mapping(uint256 => Listing)) s_listings;

    // seller address -> amount earned
    mapping(address => uint256) private s_proceeds;

    event ItemListed(
        address indexed seller,
        address nftContractAddress,
        uint256 tokenId,
        uint256 price
    );

    event ItemBought(
        address indexed buyer,
        address nftContractAddress,
        uint256 tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed nftContractAddress,
        uint256 tokenId,
        address seller
    );

    event PriceUpdated(
        address indexed nftContractAddress,
        uint256 tokenId,
        address seller
    );

    modifier notBeingListed(address nftContractAddress, uint256 tokenId) {
        // if the NFT listed before, the price will be > 0
        if (s_listings[nftContractAddress][tokenId].price > 0) {
            revert NftMarketPlace__AlreadyListed();
        }
        _;
    }

    modifier isBeingListed(address nftContractAddress, uint256 tokenId) {
        if (s_listings[nftContractAddress][tokenId].price <= 0) {
            revert NftMarketPlace__NotListed();
        }
        _;
    }

    modifier isOwner(
        address nftContractAddress,
        uint256 tokenId,
        address seller
    ) {
        // the owner of NFT need to be seller
        // 1. get the owner of NFT
        IERC721 nftContract = IERC721(nftContractAddress);
        address owner = nftContract.ownerOf(tokenId);

        // 2. compare owner of NFT vs seller
        if (owner != seller) {
            revert NftMarketPlace__NotOwner();
        }
        _;
    }

    // 1. `listItem`: Allow seller to list NFTs on marketplace
    // 2. `updateListing`: Allow seller to adjust the price of NFTs
    // 3. `cancelListing`: Allow seller to cancel the NFTs listed
    // 4. `withdrawProceeds`: Allow seller to withdraw money from bought NFTs
    // 5. `buyItem`: Buy the NFTs

    /**
     * @notice  Method for seller to list their NFT on the marketplace (seller will call this function)
     * @dev     Seller still hold that NFT, and the marketplace as a spender can sell that NFT and paid fund back to seller
     * @param   nftContractAddress: Address of the NFT contract (already deployed somewhere)
     * @param   tokenId  the tokenId of the NFT
     * @param   price  the price seller specify
     */
    function listItem(
        address nftContractAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notBeingListed(nftContractAddress, tokenId)
        isOwner(nftContractAddress, tokenId, msg.sender)
    {
        // the price need to higher than 0
        if (price < 0) {
            revert NftMarketPlace__PriceMustBeAboveZero();
        }

        // check if marketplace have approval to sell this NFT
        // sell NFT mean: transfer this NFT from our wallet to another wallet
        IERC721 nftContractInstance = IERC721(nftContractAddress);
        if (nftContractInstance.getApproved(tokenId) != address(this)) {
            revert NftMarketPlace__NotApprovedForMarketPlace();
        }

        // update the listing mapping
        s_listings[nftContractAddress][tokenId] = Listing(msg.sender, price);
        emit ItemListed(msg.sender, nftContractAddress, tokenId, price);
    }

    /**
     * @notice  Allow buyer to purchase the listing NFT (buyer will call this function)
     * @dev     user click on buy -> make a payment -> transfer that NFT to buyer and the fund to seller
     * @param   nftContractAddress: Address of the NFT contract (already deployed somewhere)
     * @param   tokenId  the tokenId of the NFT
     */
    function buyItem(
        address nftContractAddress,
        uint256 tokenId
    ) external payable isBeingListed(nftContractAddress, tokenId) nonReentrant {
        Listing memory listedItem = s_listings[nftContractAddress][tokenId];

        //* the send value need to equal price
        if (msg.value < listedItem.price) {
            revert NftMarketPlace__PriceNotMet();
        }

        //* update fund for seller
        s_proceeds[listedItem.seller] += msg.value;

        //* remove the bought NFT
        delete s_listings[nftContractAddress][tokenId];

        //* transfer NFT to buyer
        // need to "tell" the nftContract to assign new owner
        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(
            msg.sender,
            nftContractAddress,
            tokenId,
            listedItem.price
        );
    }

    /**
     * @notice  Allow seller to cancel the NFT listing (seller call this function)
     * @dev     The seller need to own that NFT, and the NFT need to in listing state
     * @param   nftContractAddress: Address of the NFT contract (already deployed somewhere)
     * @param   tokenId  the tokenId of the NFT
     */
    function cancelListing(
        address nftContractAddress,
        uint256 tokenId
    )
        external
        isOwner(nftContractAddress, tokenId, msg.sender)
        isBeingListed(nftContractAddress, tokenId)
    {
        delete s_listings[nftContractAddress][tokenId];

        emit ItemCanceled(nftContractAddress, tokenId, msg.sender);
    }

    /**
     * @notice  seller can update the price of NFT (seller call this function)
     * @dev     The seller need to own that NFT, and the NFT need to in listing state
     * @param   nftContractAddress  .
     * @param   tokenId  .
     * @param   newPrice  .
     */
    function updateListing(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isOwner(nftContractAddress, tokenId, msg.sender)
        isBeingListed(nftContractAddress, tokenId)
    {
        s_listings[nftContractAddress][tokenId].price = newPrice;
        emit PriceUpdated(nftContractAddress, tokenId, msg.sender);
    }

    /**
     * @notice  Allow seller to withdraw money from bought NFTs (seller call this function)
     * @dev     msg.sender is seller, and s_proceeds need to > 0
     */
    function withdrawProceeds() external {
        // seller need to have some fund to withdraw
        require(s_proceeds[msg.sender] > 0);

        uint256 balance = s_proceeds[msg.sender];
        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            revert NftMarketPlace__WithdrawProceedsFailed();
        }
    }

    //* Getter function

    function getListingItem(
        address nftContractAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[nftContractAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
