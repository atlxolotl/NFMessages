// SPDX-License-Identifier:  GPL-3.0-only
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { NFTMessages } from "./NFTMessages.sol";
import { MessagesToken  } from "./MessagesToken.sol";

contract NFMSG is Ownable {

    NFTMessages public  nftMessagesSC;
    MessagesToken public messagesTokenSC;
    uint256 public immutable mintingAndLockDeadline;
    uint256 public mintingNFTFee;

    struct reward {
        uint256 count;
        uint256 multiplier;
    }
    // From, to, reward
    mapping(address => mapping(address => reward)) interactions;

    event NFTMinted(address indexed from, address indexed to, string tokenURI);

    constructor(uint256 _mintingAndLockDeadline, uint256 _mintingNFTFee)
        Ownable(msg.sender) {
        require(_mintingAndLockDeadline > block.timestamp, "Invalid minting and unlock deadline");
        mintingAndLockDeadline = _mintingAndLockDeadline;
        mintingNFTFee = _mintingNFTFee;
        nftMessagesSC = new NFTMessages();
        messagesTokenSC = new MessagesToken(_mintingAndLockDeadline);
    }

    receive() external payable {}

    //@notice: muliplier based on the amount of transactions up to 3X when it reaches 10000
    function _airDropCalculator(address from, address to) internal 
    returns (uint256) {
    // for now proof of concept just registry a reward
        // add interaction
        interactions[from][to].count += 1;
        // update reward multiplier
        uint256 count = interactions[from][to].count;
        if (count % 10 == 0 && count <= 100) {
            interactions[from][to].multiplier = 1 + (count / (100));
        } else if (count % 100 == 0 &&  count > 100  && count <= 1000) {
            interactions[from][to].multiplier = 2 + (count / (1000));
        }
        // return reward
        return interactions[from][to].multiplier;
    }

    // Handled by DAO in the future
    // for ether or tokens depending on the mintingAndLockDeadline
    function setMintingFee(uint256 newMintingNFTFee) external onlyOwner {
        mintingNFTFee = newMintingNFTFee;
    }

    // this one before deadline
    function sendNFTMessage(address to, string memory tokenURI) external payable {
        if (block.timestamp < mintingAndLockDeadline) {
            require(msg.value >= mintingNFTFee, "Insufficient Ether fee for minting Message");
            nftMessagesSC.safeMint(to, tokenURI);
            //Airdrop to sender 1000 Tokens times multiplier
            messagesTokenSC.mint(msg.sender, 1000 * _airDropCalculator(msg.sender, to));
        } else {
            bool erc20receipt =  messagesTokenSC.transferFrom(msg.sender, address(this), mintingNFTFee);
            require(erc20receipt, "NFMT transfer you must forefill the fee");
            // 50% of fee goes gets burned, 50% for DAO 
            uint256 amountToBurn = mintingNFTFee / 2;
            // Burn 50% of the received NFMT tokens
            messagesTokenSC.burn(amountToBurn);
            nftMessagesSC.safeMint(to, tokenURI);
        }

        emit NFTMinted(msg.sender, to, tokenURI);
    }

    function cashOutEther(uint256 amount, address payable recipient) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance in contract");
        recipient.transfer(amount);
    }

    function cashOutERC20(uint256 amount, address recipient) public onlyOwner {
        require(messagesTokenSC.balanceOf(address(this)) >= amount, "Insufficient NFMT balance in contract");
        messagesTokenSC.transfer(recipient, amount);
    }
}

