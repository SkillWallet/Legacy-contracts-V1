//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "hardhat/console.sol";

/**
 * @title DistributedTown Community
 *
 * @dev Implementation of the Community concept in the scope of the DistributedTown project
 * @author DistributedTown
 */

contract Community is ERC1155, ERC1155Holder {

    Template public template;

    enum TokenType {DiToCredit, Community}
    enum Template {OpenSource, Art, Local}

    // add JSON Schema base URL
    constructor(string memory _url, uint _template) public ERC1155(_url) {
        template = Template(_template);
        // Fungible DiToCredits ERC-20 token
        _mint(address(this), uint256(TokenType.DiToCredit), 96000 * 1e18, "");
        // Non-Fungible Community template NFT token
        _mint(address(this), uint256(TokenType.Community), 1, "");
    }

    function transferDiToCredits(
        address _from,
        address _to,
        uint256 _value
    ) public {
        super.safeTransferFrom(
            _from,
            _to,
            0,
            _value,
            ""
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) public override {
        require(
            _id != uint256(TokenType.Community),
            "Community NFT can't be trasfered"
        );

        super.safeTransferFrom(_from, _to, _id, _value, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) public override {
        require(
            !contains(_ids, uint256(TokenType.Community)),
            "Community NFT can't be trasfered"
        );

        super.safeBatchTransferFrom(_from, _to, _ids, _values, _data);
    }

    function balanceOf(address _owner, uint256 _id)
    public
    view
    override
    returns (uint256)
    {
        require(
            _id != uint256(TokenType.Community),
            "Community NFT doesn't have a balance."
        );
        super.balanceOf(_owner, _id);
    }

    function diToCreditsBalance(address _owner) public view returns (uint256) {
        super.balanceOf(_owner, uint256(TokenType.DiToCredit));
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    public
    view
    override
    returns (uint256[] memory)
    {
        require(
            !contains(_ids, uint256(TokenType.Community)),
            "Community NFT can't be trasfered"
        );

        super.balanceOfBatch(_owners, _ids);
    }

    function setApprovalForAll(address _operator, bool _approved)
    public
    override
    {
        super.setApprovalForAll(_operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool)
    {
        super.isApprovedForAll(_owner, _operator);
    }

    function contains(uint256[] memory arr, uint256 element)
    internal
    view
    returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == element) return true;
        }
        return false;
    }

    /**
 * @dev See {IERC165-supportsInterface}.
 */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
        || interfaceId == type(IERC1155MetadataURI).interfaceId
        || interfaceId == type(IERC1155Receiver).interfaceId
        || super.supportsInterface(interfaceId);
    }

    // TODO: Only CommunityRegistry can call this
    // @dev This is added because approval is needed for the membership address, so it can transfer credits (calling setApprovalFor all won't work, we need to make it external)
    function setApprovalForMembership(address membershipAddress) public override {
        super.setApprovalForMembership(membershipAddress);
    }
}