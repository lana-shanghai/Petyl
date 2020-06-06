pragma solidity ^0.6.9;

import "./Members.sol";
import "./Proposals.sol";
import "../Utils/Owned.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/IPetylToken.sol";



// ----------------------------------------------------------------------------
// Decentralised Future Fund DAO
//
// https://github.com/bokkypoobah/DecentralisedFutureFundDAO
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT


contract Nikkal is Owned {
    using SafeMath for uint;
    using Members for Members.Data;
    using Proposals for Proposals.Data;

    string public name;

    IPetylToken public token;
    Members.Data members;
    Proposals.Data proposals;

    uint public tokensForNewMembers;

    uint public quorum = 80;              // AG Updateable
    uint public quorumDecayPerWeek = 10;  // AG Updateable
    uint public requiredMajority = 70;    // AG Updateable

    // Must be copied here to be added to the ABI
    event MemberAdded(address indexed memberAddress, string name, uint totalAfter);
    event MemberRemoved(address indexed memberAddress, string name, uint totalAfter);
    event MemberNameUpdated(address indexed memberAddress, string oldName, string newName);

    event NewProposal(uint indexed proposalId, Proposals.ProposalType indexed proposalType, address indexed proposer); 
    event Voted(uint indexed proposalId, address indexed voter, bool vote, uint votedYes, uint votedNo);
    event VoteResult(uint indexed proposalId, bool pass, uint votes, uint quorumPercent, uint membersLength, uint yesPercent, uint requiredMajority);
    event TokenUpdated(address indexed oldToken, address indexed newToken);
    event TokensForNewMembersUpdated(uint oldTokens, uint newTokens);
    event EtherDeposited(address indexed sender, uint amount);
    event EtherTransferred(uint indexed proposalId, address indexed sender, address indexed recipient, uint amount);

    modifier onlyMember {
        require(members.isMember(msg.sender));
        _;
    }

    function initPetylVote(address _token, string memory _groupName, uint _tokensForNewMembers) public {
        require(!members.isInitialised());
        _initOwned(msg.sender);
        name = _groupName;
        tokensForNewMembers = _tokensForNewMembers;
        token = IPetylToken(_token);
        emit TokenUpdated(address(token), _token);
    }
    function initAddMember( string memory _name, address _address) public  {
        require(isOwner());
        require(!members.isInitialised());
        require(address(token) != address(0));
        members.add(_address, _name);
        token.operatorMint(_address, tokensForNewMembers, "","");

    }
    function initRemoveMember(address _address) public {
        require(isOwner());
        require(!members.isInitialised());
        members.remove(_address);
    }
    function initialisationComplete() public {
        require(isOwner());
        require(!members.isInitialised());
        require(members.length() != 0);
        members.init();
        _transferOwnership(address(0));
    }



    function setMemberName(string memory memberName) public {
        members.setName(msg.sender, memberName);
    }
    function proposeAddMember(string memory memberName, address memberAddress) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeAddMember(memberName, memberAddress);
        vote(proposalId, true);
    }
    function proposeRemoveMember(string memory description, address memberAddress) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeRemoveMember(description, memberAddress);
        vote(proposalId, true);
    }
    function proposeMintTokens(string memory description, address tokenOwner, uint amount) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeMintTokens(description, tokenOwner, amount);
        vote(proposalId, true);
    }
    function proposeBurnTokens(string memory description, address tokenOwner, uint amount) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeBurnTokens(description, tokenOwner, amount);
        vote(proposalId, true);
    }
    function proposeUpdateTokensForNewMembers(string memory description,  uint amount) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeUpdateTokensForNewMembers(description, amount);
        vote(proposalId, true);
    }
    function proposeEtherTransfer(string memory description, address recipient, uint amount) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeEtherTransfer(description, recipient, amount);
        vote(proposalId, true);
    }
    function voteNo(uint proposalId) public onlyMember {
        vote(proposalId, false);
    }
    function voteYes(uint proposalId) public onlyMember {
        vote(proposalId, true);
    }
    function vote(uint proposalId, bool yesNo) internal {
        proposals.vote(proposalId, yesNo, members.length(), getQuorum(proposals.getInitiated(proposalId), now), requiredMajority);
        Proposals.ProposalType proposalType = proposals.getProposalType(proposalId);
        if (proposals.toExecute(proposalId)) {
            string memory description = proposals.getDescription(proposalId);
            address address1  = proposals.getAddress1(proposalId);
            uint amount = proposals.getAmount(proposalId);
            if (proposalType == Proposals.ProposalType.AddMember) {
                addMember(address1, description);

            } else if (proposalType == Proposals.ProposalType.RemoveMember) {
                removeMember(address1);

            } else if (proposalType == Proposals.ProposalType.MintTokens) {
                token.operatorMint(address1, amount,"","");

            } else if (proposalType == Proposals.ProposalType.BurnTokens) {
                token.operatorBurn(address1, amount,"","");

            } else if (proposalType == Proposals.ProposalType.UpdateTokensForNewMembers) {
                setTokensForNewMembers(amount);

            } else if (proposalType == Proposals.ProposalType.EtherTransfer) {
                payable(address1).transfer(amount);
                emit EtherTransferred(proposalId, msg.sender, address1, amount);
            }
            proposals.close(proposalId);
        }
    }
    function getVotingStatus(uint proposalId) public view returns (bool, bool, uint, uint) {
        return proposals.getVotingStatus(proposalId, members.length(), getQuorum(proposals.getInitiated(proposalId), now), requiredMajority);
    }

    
    // function setToken(address clubToken) internal {
    //     emit TokenUpdated(address(token), clubToken);
    //     token = ClubTokenInterface(clubToken);
    // }
    function setTokensForNewMembers(uint _tokensForNewMembers) internal {
        emit TokensForNewMembersUpdated(tokensForNewMembers, _tokensForNewMembers);
        tokensForNewMembers = _tokensForNewMembers;
    }
    function addMember(address memberAddress, string memory memberName) internal {
        members.add(memberAddress, memberName);
        token.operatorMint(memberAddress, tokensForNewMembers,"","");
    }
    function removeMember(address memberAddress) internal {
        members.remove(memberAddress);
        token.operatorBurn(memberAddress, uint(-1),"","");

    }


    function numberOfMembers() public view returns (uint) {
        return members.length();
    }
    function getMembers() public view returns (address[] memory) {
        return members.index;
    }
    function getMemberData(address memberAddress) public view returns (bool _exists, uint _index, string memory _name) {
        Members.Member memory member = members.entries[memberAddress];
        return (member.exists, member.index, member.name);
    }
    function getMemberByIndex(uint _index) public view returns (address _member) {
        return members.index[_index];
    }

    function getQuorum(uint proposalTime, uint currentTime) public view returns (uint) {
        if (quorum > currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks)) {
            return quorum.sub(currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks));
        } else {
            return 0;
        }
    }
    function numberOfProposals() public view returns (uint) {
        return proposals.length();
    }
    function getProposal(uint proposalId) public view returns (uint _proposalType, address _proposer, string memory _description, address _address1, address _address2, uint _amount, uint _votedNo, uint _votedYes, uint _initiated, uint _closed) {
        Proposals.Proposal memory proposal = proposals.proposals[proposalId];
        _proposalType = uint(proposal.proposalType);
        _proposer = proposal.proposer;
        _description = proposal.description;
        _address1 = proposal.address1;
        _address2 = proposal.address2;
        _amount = proposal.amount;
        _votedNo = proposal.votedNo;
        _votedYes = proposal.votedYes;
        _initiated = proposal.initiated;
        _closed = proposal.closed;
    }
    receive () external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }
}