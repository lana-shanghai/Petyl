pragma solidity ^0.6.9;

import "./Moloch.sol";
import "./Nikkal.sol";

import "../Utils/CloneFactory.sol";

contract Summoner is CloneFactory {

    address public greatKingMoloch;
    address payable public greatQueenNikkal;


    Moloch private M;
    Nikkal private N;

    address[] public Molochs;
    address[] public Nikkals;

    event SummonedMoloch(address indexed M, address indexed _summoner);
    event SummonedNikkal(address indexed M, address indexed _summoner);

    /// @notice Moloch, king of fire and money, used to distribute funds
    function summonMoloch(
        address[] memory _approvedTokens,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _proposalDeposit,
        uint256 _dilutionBound,
        uint256 _processingReward) public {
        M = Moloch(createClone(greatKingMoloch));
        M.awakenMoloch(
            msg.sender,
            _approvedTokens,
            _periodDuration,
            _votingPeriodLength,
            _gracePeriodLength,
            _proposalDeposit,
            _dilutionBound,
            _processingReward);
        Molochs.push(address(M));
        emit SummonedMoloch(address(M), msg.sender);
    }

    /// @notice Nikkal, Queen of spring and blossoms, used to decide issues
    function summonNikkal(
        address _token, 
        string memory _groupName, 
        uint _tokensForNewMembers,
        uint _quorum,              
        uint _quorumDecayPerWeek,  
        uint _requiredMajority) public {
        N = Nikkal(payable(createClone(greatQueenNikkal)));
        N.awakenNikkal(
            _token, 
            _groupName, 
            _tokensForNewMembers,
            _quorum,              
            _quorumDecayPerWeek,  
            _requiredMajority);
        Nikkals.push(address(N));
        emit SummonedNikkal(address(N), msg.sender);
    }


    function getMolochCount() public view returns (uint256 MolochCount) {
        return Molochs.length;
    }

    function getNikkalCount() public view returns (uint256 NikkalCount) {
        return Nikkals.length;
    }

    receive () external payable {
        revert();
    }
}