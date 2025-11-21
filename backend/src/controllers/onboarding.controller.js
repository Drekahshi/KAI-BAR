
const hederaService = require('../services/hedera.service');
const userService = require('../services/user.service');

const createAccount = async (req, res) => {
  const { publicKey, identifier } = req.body;
  if (!publicKey || !identifier) {
    return res.status(400).json({
      message: 'Public key and identifier are required',
    });
  }
  try {
    const newAccount = await hederaService.createAccount(publicKey);
    const user = await userService.createUser(identifier, newAccount.accountId);
    res.status(201).json({
      message: 'Account created and user linked successfully',
      data: { user, account: newAccount },
    });
  } catch (error) {
    res.status(500).json({
      message: 'Error creating account',
      error: error.message,
    });
  }
};

const attendanceService = require('../services/attendance.service');

const verifyAttendance = async (req, res) => {
  const { identifier } = req.body;
  if (!identifier) {
    return res.status(400).json({
      message: 'Identifier is required',
    });
  }
  try {
    const user = await userService.getUserByIdentifier(identifier);
    if (!user) {
      return res.status(404).json({
        message: 'User not found',
      });
    }
    await attendanceService.recordAttendance(user.id);
    res.status(200).json({
      message: 'Attendance verified',
    });
  } catch (error) {
    res.status(500).json({
      message: 'Error verifying attendance',
      error: error.message,
    });
  }
};

const getMetrics = async (req, res) => {
  try {
    const metrics = await userService.getOnboardingMetrics();
    res.status(200).json({
      message: 'Metrics retrieved successfully',
      data: metrics,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Error retrieving metrics',
      error: error.message,
    });
  }
};

module.exports = {
  createAccount,
  verifyAttendance,
  getMetrics,
};
