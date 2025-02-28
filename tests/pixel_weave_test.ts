import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Canvas creation test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('pixel-weave', 'create-canvas',
        [types.ascii("Test Canvas"), types.principal(deployer.address)],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    const response = chain.callReadOnlyFn(
      'pixel-weave',
      'get-canvas',
      [types.uint(1)],
      deployer.address
    );
    
    response.result.expectSome().expectTuple();
  }
});

Clarinet.test({
  name: "Pixel update test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Create canvas
    let block = chain.mineBlock([
      Tx.contractCall('pixel-weave', 'create-canvas',
        [types.ascii("Test Canvas"), types.principal(deployer.address)],
        deployer.address
      )
    ]);
    
    // Update pixel as owner
    block = chain.mineBlock([
      Tx.contractCall('pixel-weave', 'update-pixel',
        [
          types.uint(1),
          types.uint(5),
          types.uint(5),
          types.ascii("FF0000"),
          types.principal(deployer.address)
        ],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try update as unauthorized user
    block = chain.mineBlock([
      Tx.contractCall('pixel-weave', 'update-pixel',
        [
          types.uint(1),
          types.uint(5),
          types.uint(5),
          types.ascii("FF0000"),
          types.principal(user1.address)
        ],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(101);
  }
});

Clarinet.test({
  name: "NFT minting test", 
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Create canvas
    let block = chain.mineBlock([
      Tx.contractCall('pixel-weave', 'create-canvas',
        [types.ascii("Test Canvas"), types.principal(deployer.address)],
        deployer.address
      )
    ]);
    
    // Mint as owner
    block = chain.mineBlock([
      Tx.contractCall('pixel-weave', 'mint-artwork',
        [types.uint(1), types.principal(deployer.address)],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try mint as non-owner
    block = chain.mineBlock([
      Tx.contractCall('pixel-weave', 'mint-artwork',
        [types.uint(1), types.principal(user1.address)],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(101);
  }
});
