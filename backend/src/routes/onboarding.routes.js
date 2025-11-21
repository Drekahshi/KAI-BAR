
const express = require('express');
const router = express.Router();
const onboardingController = require('../controllers/onboarding.controller');

router.post('/onboard', onboardingController.createAccount);
router.post('/verify-attendance', onboardingController.verifyAttendance);
router.get('/metrics/onboarding', onboardingController.getMetrics);

module.exports = router;
