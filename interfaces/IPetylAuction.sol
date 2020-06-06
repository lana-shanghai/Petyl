pragma solidity ^0.6.9;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

interface IPetylAuction {

    function initDutchAuction (
            address _token,
            uint256 _tokenSupply,
            uint256 _startDate,
            uint256 _endDate,
            address _paymentCurrency,
            uint256 _startPrice,
            uint256 _minimumPrice,
            address payable _wallet
        ) external ;
    function auctionEnded() external view returns (bool);

}
