const config = require('../config/config');

class SMSUtil {
  constructor() {
    this.isConfigured = !!(config.twilio.accountSid && config.twilio.authToken);
    
    if (this.isConfigured) {
      try {
        const twilio = require('twilio');
        this.client = twilio(config.twilio.accountSid, config.twilio.authToken);
      } catch (error) {
        console.log('⚠️  Twilio not configured. OTPs will be logged to console.');
        this.isConfigured = false;
      }
    } else {
      console.log('⚠️  Twilio not configured. OTPs will be logged to console.');
    }
  }

  async sendOTP(phoneNumber, otpCode) {
    try {
      const message = `Your healthcare app verification code is: ${otpCode}. Valid for ${config.otp.expireMinutes} minutes.`;
      
      if (this.isConfigured && this.client) {
        await this.client.messages.create({
          body: message,
          from: config.twilio.phoneNumber,
          to: phoneNumber
        });
        console.log(`✅ OTP sent to ${phoneNumber}`);
      } else {
        // Development mode - log OTP to console
        console.log('════════════════════════════════════════');
        console.log(`📱 OTP for ${phoneNumber}: ${otpCode}`);
        console.log('════════════════════════════════════════');
      }
      
      return true;
    } catch (error) {
      console.error('❌ SMS send error:', error.message);
      // Still log OTP in case of error for development
      console.log('════════════════════════════════════════');
      console.log(`📱 OTP for ${phoneNumber}: ${otpCode}`);
      console.log('════════════════════════════════════════');
      return true; // Return true to continue flow in development
    }
  }
}

module.exports = new SMSUtil();