# ERC 404 NFT Marketplace


Run the following command to install the dependencies:

```shell
npm install dotenv --save --force
npm install --save-dev hardhat --force
npm install --force
```

Try running some of the following tasks to test your project:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```


### Interact With the Frontend

1. connect your MetaMask wallet
2. Go to the “List NFT” field, enter your NFT contract address, and click on the “List NFT with Permit” button, to list your NFT on the marketplace.
3. If you want to delete the listing, go to the “Cancel Listing” field and click on the “Cancel Listing” button.
4. If you want to buy an NFT share, go to the “Buy NFT” field, enter the NFT details and the amount of share you want to buy, and then click on the “Buy NFT” button.
5. At last, if you want to update the price of your token share, go to the “Update Listing Price” field.