# PixelWeave
A decentralized collaborative pixel art creation and sharing platform built on Stacks.

## Features
- Create and edit pixel art canvas (32x32 pixels)
- Collaborate with other artists on shared canvases 
- Save and mint artwork as NFTs
- Share artwork ownership and royalties
- View artwork history and contributors

## Setup and Installation
1. Clone the repository
2. Install Clarinet 
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; Create new canvas
(contract-call? .pixel-weave create-canvas "My Artwork" 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Update pixel
(contract-call? .pixel-weave update-pixel u1 u5 "FF0000" 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Mint artwork as NFT
(contract-call? .pixel-weave mint-artwork u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
