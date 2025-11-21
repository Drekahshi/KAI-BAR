
const {
  Client,
  PrivateKey,
  AccountCreateTransaction,
  Hbar,
  Status,
} = require('@hashgraph/sdk');
const { INITIAL_BALANCE } = require('../../config/constants');

// Configure the client for the Hedera testnet
const client = Client.forName(process.env.HEDERA_NETWORK);
client.setOperator(
  process.env.HEDERA_ACCOUNT_ID,
  process.env.HEDERA_PRIVATE_KEY
);

/**
 * Creates a new Hedera account with an initial balance of 1 Hbar.
 *
 * @returns {object} An object containing the new account ID and private key.
 */
const createAccount = async (publicKey) => {
  // Create a new account with 1,000 tinybar starting balance
  const newAccount = await new AccountCreateTransaction()
    .setKey(publicKey)
    .setInitialBalance(Hbar.fromTinybars(INITIAL_BALANCE))
    .execute(client);

  // Get the new account ID
  const getReceipt = await newAccount.getReceipt(client);

  if (getReceipt.status !== Status.Success) {
    throw new Error(`Transaction failed with status: ${getReceipt.status}`);
  }

  const newAccountId = getReceipt.accountId;

  return {
    accountId: newAccountId.toString(),
  };
};

module.exports = {
  createAccount,
  client,
};
