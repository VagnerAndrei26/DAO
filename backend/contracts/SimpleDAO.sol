// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    /// @return Returns the price in Wei for an NFT
    function getPrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract SimpleDAO is Ownable {
    enum Vote {
        Yes,
        No
    }


    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(uint256 => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numberProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT nftContract;

    constructor(address _nftMarketplace, address _nftContract) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        nftContract = ICryptoDevsNFT(_nftContract);
    }


    modifier onlyOwnerOfNft() {
        require(nftContract.balanceOf(msg.sender) > 0, "Not a nft owner");
        _;
    }


    modifier activeProposalOnly(uint proposalIndex) {
        require(proposals[proposalIndex].deadline > block.timestamp, "Deadline exceeded");
        _;
    }


    modifier inactiveProposalOnly(uint propsalIndex) {
        require(proposals[propsalIndex].deadline <= block.timestamp, "Deadline not exceeded");
        require(proposals[propsalIndex].executed == false, "Proposal already executed");
        _;
    }

    
    function createProposal(uint _nftTokenId) external onlyOwnerOfNft returns(uint) {
        require(nftMarketplace.available(_nftTokenId), "NFT is not for sale");
        Proposal storage proposal = proposals[numberProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numberProposals ++;

        return numberProposals - 1;
    }


    function voteOnProposal(uint proposalIndex, Vote vote) external onlyOwnerOfNft activeProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        uint voterNFTBalance = nftContract.balanceOf(msg.sender);
        uint numVotes = 0;

        for(uint i = 0; i < voterNFTBalance; i++) {
            uint tokenId = nftContract.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] == false){
                numVotes ++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "Already voted");

        if(vote == Vote.Yes) {
            proposal.yesVotes += numVotes;
        } else {
            proposal.noVotes += numVotes;
        }
    }


    function executeProposal(uint proposalIndex) external onlyOwnerOfNft inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        if(proposal.yesVotes > proposal.noVotes){
            uint nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "Not enough ether");
            nftMarketplace.purchase{ value: nftPrice }(proposal.nftTokenId);
        }
        proposal.executed = true;
    }


    function withdrawEther() external onlyOwner {
        uint amount = address(this).balance;
        address owner = owner();
        require(amount > 0, "No ether in the contract");
        (bool s, ) = payable(owner).call{ value: amount}("");
        require(s, "Transfer failed");
    }


    receive() external payable {}


    fallback() external payable {}
}