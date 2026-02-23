require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  env: process.env.NODE_ENV || 'development',
  jwt: {
    secret: process.env.JWT_SECRET || 'default_secret_key',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'default_refresh_secret',
    expire: process.env.JWT_EXPIRE || '24h',
    refreshExpire: process.env.JWT_REFRESH_EXPIRE || '7d'
  },
  otp: {
    expireMinutes: parseInt(process.env.OTP_EXPIRE_MINUTES) || 10,
    length: parseInt(process.env.OTP_LENGTH) || 6
  },
  twilio: {
    accountSid: process.env.TWILIO_ACCOUNT_SID,
    authToken: process.env.TWILIO_AUTH_TOKEN,
    phoneNumber: process.env.TWILIO_PHONE_NUMBER
  }
};