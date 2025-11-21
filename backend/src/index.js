
const express = require('express');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

const onboardingRoutes = require('./routes/onboarding.routes');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/v1', onboardingRoutes);

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

module.exports = app;
