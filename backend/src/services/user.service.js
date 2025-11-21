
const db = require('../../config/database');

const createUser = async (identifier, accountId) => {
  const query = 'INSERT INTO users (identifier, account_id) VALUES ($1, $2) RETURNING *';
  const values = [identifier, accountId];
  const { rows } = await db.query(query, values);
  return rows[0];
};

const getUserByIdentifier = async (identifier) => {
  const query = 'SELECT * FROM users WHERE identifier = $1';
  const values = [identifier];
  const { rows } = await db.query(query, values);
  return rows[0];
};

const getOnboardingMetrics = async () => {
  const query = 'SELECT COUNT(*) as new_wallets FROM users';
  const { rows } = await db.query(query);
  return {
    newWallets: parseInt(rows[0].new_wallets, 10),
    activations: parseInt(rows[0].new_wallets, 10),
  };
};

module.exports = {
  createUser,
  getUserByIdentifier,
  getOnboardingMetrics,
};
