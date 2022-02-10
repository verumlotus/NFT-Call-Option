# NFT Call Options

Call options for any ERC721 conforming asset. 

[NiftyOptions](https://niftyoptions.org/) is an on-chain options protocol for NFTs, but it currently only support the creation of puts. While this minimizes downside risk for NFT holders, the needs of NFT speculators is left unmet. Thus, call options. 

Selling covered call options for NFTs allows sellers to generate a premium and guarantee a fixed upside from the current price. For call purchasers, these options are a way to speculate on NFT price movement for a small premium. 

## Flow for an Option Seller
- Deploy an instance of the `Option.sol` contract, specifying parameters such as the `quoteToken`, `strike`, `premium`, and `expiry`. 
- Deposit the NFT into the contract via `deposit`. 
- At expiry, if the option has not been exericsed, the seller can call `closeOption` to receive their NFT.
- At any time, if the contract has not been purchased yet, the seller can call `closeOption` to close the contract and receive their NFT. 

## Flow for an Option Buyer
- Call `purchaseCall`: the buyer can either call `approve` on the `quoteToken`, or can provide an EIP-2612 Permit signature. 
- To exercise an option, the buyer can call `exerciseOption` and pay the strike price to receive the NFT. 

## Build & Testing
This repo uses Foundry for both the build and testing flows. Run `forge build` to build the repo and `forge test` for tests. 

## Disclaimer
This was created mostly for fun, and should not be used in production. It's not gas optimized and only has very basic tests. 



