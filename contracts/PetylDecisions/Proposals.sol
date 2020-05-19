pragma solidity ^0.6.2;

import "./Members.sol";

import "../Misc/Owned.sol";
import "../Misc/SafeMath.sol";
import "../../interfaces/IPetylToken.sol";


// ----------------------------------------------------------------------------
// Voting Proposals
//
// URL: ClubEth.App
// GitHub: https://github.com/bokkypoobah/ClubEth
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd and
// the ClubEth.App Project - 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Proposals Data Structure
// ----------------------------------------------------------------------------

library Proposals {
    enum ProposalType {
        AddMember,                         //  0 Add member
        RemoveMember,                      //  1 Remove member
        MintTokens,                        //  2 Mint tokens
        BurnTokens,                        //  3 Burn tokens
        EtherTransfer,                     //  4 Ether transfer from club
        ClubEthTokenTransfer,              //  5 ClubEth token transfer from club
        ERC20TokenTransfer,                //  6 ERC20 token transfer from club
        AddRule,                           //  7 Add governance rule
        DeleteRule,                        //  8 Delete governance rule
        UpdateClubEthName,                 //  9 Update ClubEth name
        UpdateInitialTokensForNewMembers,  // 10 Update initialTokensForNewMembers
        UpdateClubEthToken,                // 11 Update ClubEthToken
        UpdateClubEth                      // 12 Update ClubEth
    }

    struct Proposal {
        ProposalType proposalType;
        address proposer;
        string  description;
        address address1;
        address address2;
        uint amount;
        mapping(address => uint) voted;
        uint votedNo;
        uint votedYes;
        uint initiated;
        uint closed;
        bool pass;
    }

    struct Data {
        bool initialised;
        Proposal[] proposals;
    }

    event NewProposal(uint indexed proposalId, Proposals.ProposalType indexed proposalType, address indexed proposer); 
    event Voted(uint indexed proposalId, address indexed voter, bool vote, uint votedYes, uint votedNo);
    event VoteResult(uint indexed proposalId, bool pass, uint votes, uint quorumPercent, uint membersLength, uint yesPercent, uint requiredMajority);

    function proposeAddMember(Data storage self, string memory memberName, address memberAddress) internal returns (uint proposalId) {
        Proposal memory proposal = Proposal({
            proposalType: ProposalType.AddMember,
            proposer: msg.sender,
            description: memberName,
            address1: memberAddress,
            address2: address(0),
            amount: 0,
            votedNo: 0,
            votedYes: 0,
            initiated: now,
            closed: 0,
            pass: false
        });
        self.proposals.push(proposal);
        proposalId = self.proposals.length - 1;
        emit NewProposal(proposalId, proposal.proposalType, msg.sender);
    }
    function proposeRemoveMember(Data storage self, string memory description, address memberAddress) internal returns (uint proposalId) {
        Proposal memory proposal = Proposal({
            proposalType: ProposalType.RemoveMember,
            proposer: msg.sender,
            description: description,
            address1: memberAddress,
            address2: address(0),
            amount: 0,
            votedNo: 0,
            votedYes: 0,
            initiated: now,
            closed: 0,
            pass: false
        });
        self.proposals.push(proposal);
        proposalId = self.proposals.length - 1;
        emit NewProposal(proposalId, proposal.proposalType, msg.sender);
    }
    function proposeMintTokens(Data storage self, string memory description, address tokenOwner, uint amount) internal returns (uint proposalId) {
        Proposal memory proposal = Proposal({
            proposalType: ProposalType.MintTokens,
            proposer: msg.sender,
            description: description,
            address1: tokenOwner,
            address2: address(0),
            amount: amount,
            votedNo: 0,
            votedYes: 0,
            initiated: now,
            closed: 0,
            pass: false
        });
        self.proposals.push(proposal);
        proposalId = self.proposals.length - 1;
        emit NewProposal(proposalId, proposal.proposalType, msg.sender);
    }
    function proposeBurnTokens(Data storage self, string memory description, address tokenOwner, uint amount) internal returns (uint proposalId) {
        Proposal memory proposal = Proposal({
            proposalType: ProposalType.BurnTokens,
            proposer: msg.sender,
            description: description,
            address1: tokenOwner,
            address2: address(0),
            amount: amount,
            votedNo: 0,
            votedYes: 0,
            initiated: now,
            closed: 0,
            pass: false
        });
        self.proposals.push(proposal);
        proposalId = self.proposals.length - 1;
        emit NewProposal(proposalId, proposal.proposalType, msg.sender);
    }
    function proposeEtherTransfer(Data storage self, string memory description, address recipient, uint amount) internal returns (uint proposalId) {
        require(address(this).balance >= amount);
        Proposal memory proposal = Proposal({
            proposalType: ProposalType.EtherTransfer,
            proposer: msg.sender,
            description: description,
            address1: recipient,
            address2: address(0),
            amount: amount,
            votedNo: 0,
            votedYes: 0,
            initiated: now,
            closed: 0,
            pass: false
        });
        self.proposals.push(proposal);
        proposalId = self.proposals.length - 1;
        emit NewProposal(proposalId, proposal.proposalType, msg.sender);
    }
    function vote(Data storage self, uint proposalId, bool yesNo, uint membersLength, uint quorum, uint requiredMajority) internal {
        Proposal storage proposal = self.proposals[proposalId];
        require(proposal.closed == 0);
        // First vote
        if (proposal.voted[msg.sender] == 0) {
            if (yesNo) {
                proposal.votedYes++;
                proposal.voted[msg.sender] = 1;
            } else {
                proposal.votedNo++;
                proposal.voted[msg.sender] = 2;
            }
            emit Voted(proposalId, msg.sender, yesNo, proposal.votedYes, proposal.votedNo);
        // Changing Yes to No
        } else if (proposal.voted[msg.sender] == 1 && !yesNo && proposal.votedYes > 0) {
            proposal.votedYes--;
            proposal.votedNo++;
            proposal.voted[msg.sender] = 2;
            emit Voted(proposalId, msg.sender, yesNo, proposal.votedYes, proposal.votedNo);
        // Changing No to Yes
        } else if (proposal.voted[msg.sender] == 2 && yesNo && proposal.votedNo > 0) {
            proposal.votedYes++;
            proposal.votedNo--;
            proposal.voted[msg.sender] = 1;
            emit Voted(proposalId, msg.sender, yesNo, proposal.votedYes, proposal.votedNo);
        }
        if (proposal.proposalType == ProposalType.RemoveMember && membersLength > 0) {
            membersLength--;
        }
        uint voteCount = proposal.votedYes + proposal.votedNo;
        if (voteCount * 100 >= quorum * membersLength) {
            uint yesPercent = proposal.votedYes * 100 / voteCount;
            proposal.pass = yesPercent >= requiredMajority;
            emit VoteResult(proposalId, proposal.pass, voteCount, quorum, membersLength, yesPercent, requiredMajority);
        }
    }
    // TODO - Issues:
    // 1. quorumReached is not accurate after the vote passes and accepts a new member
    //    Unless storing it as a storage variable, we can't accurately track the status before the proposal is executed
    // 2. To calculate required additional votes we need to apply a ceiling function which consumes gas
    function getVotingStatus(Data storage self, uint proposalId, uint membersLength, uint quorum, uint requiredMajority) internal view returns (bool isOpen, bool quorumReached, uint _requiredMajority, uint yesPercent) {
        Proposal storage proposal = self.proposals[proposalId];
        isOpen = (proposal.closed == 0);
        uint voteCount = proposal.votedYes + proposal.votedNo;
        quorumReached = (voteCount * 100 >= quorum * membersLength);
        yesPercent = proposal.votedYes * 100 / voteCount;
        _requiredMajority = requiredMajority;
    }
    // function get(Data storage self, uint proposalId) public view returns (Proposal proposal) {
    //    return self.proposals[proposalId];
    // }
    function getProposalType(Data storage self, uint proposalId) internal view returns (ProposalType) {
        return self.proposals[proposalId].proposalType;
    }
    function getDescription(Data storage self, uint proposalId) internal view returns (string memory) {
        return self.proposals[proposalId].description;
    }
    function getAddress1(Data storage self, uint proposalId) internal view returns (address) {
        return self.proposals[proposalId].address1;
    }
    function getAmount(Data storage self, uint proposalId) internal view returns (uint) {
        return self.proposals[proposalId].amount;
    }
    function getInitiated(Data storage self, uint proposalId) internal view returns (uint) {
        return self.proposals[proposalId].initiated;
    }
    function isClosed(Data storage self, uint proposalId) internal view returns (bool) {
        self.proposals[proposalId].closed;
    }
    function pass(Data storage self, uint proposalId) internal view returns (bool) {
        return self.proposals[proposalId].pass;
    }
    function toExecute(Data storage self, uint proposalId) internal view returns (bool) {
        return self.proposals[proposalId].pass && self.proposals[proposalId].closed == 0;
    }
    function close(Data storage self, uint proposalId) internal {
        self.proposals[proposalId].closed = now;
    }
    function length(Data storage self) internal view returns (uint) {
        return self.proposals.length;
    }
}
