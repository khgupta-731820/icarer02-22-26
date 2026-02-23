const db = require('../config/database');
const config = require('../config/config');

class OTP {
  static generateOTP() {
    const digits = '0123456789';
    let otp = '';
    for (let i = 0; i < config.otp.length; i++) {
      otp += digits[Math.floor(Math.random() * 10)];
    }
    return otp;
  }

  static async create(phoneNumber, purpose) {
    const otpCode = this.generateOTP();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + config.otp.expireMinutes);

    // Delete old OTPs for this phone and purpose
    await db.query(
      'DELETE FROM otps WHERE phone_number = ? AND purpose = ?',
      [phoneNumber, purpose]
    );

    await db.query(
      'INSERT INTO otps (phone_number, otp_code, purpose, expires_at) VALUES (?, ?, ?, ?)',
      [phoneNumber, otpCode, purpose, expiresAt]
    );

    return otpCode;
  }

  static async verify(phoneNumber, otpCode, purpose) {
    const [rows] = await db.query(
      `SELECT * FROM otps 
       WHERE phone_number = ? AND otp_code = ? AND purpose = ? 
       AND expires_at > NOW() AND is_verified = FALSE`,
      [phoneNumber, otpCode, purpose]
    );

    if (rows.length === 0) {
      return false;
    }

    // Mark OTP as verified
    await db.query(
      'UPDATE otps SET is_verified = TRUE WHERE id = ?',
      [rows[0].id]
    );

    return true;
  }

  static async isVerified(phoneNumber, purpose) {
    const [rows] = await db.query(
      'SELECT * FROM otps WHERE phone_number = ? AND purpose = ? AND is_verified = TRUE',
      [phoneNumber, purpose]
    );
    return rows.length > 0;
  }

  static async cleanup() {
    // Delete expired OTPs
    await db.query('DELETE FROM otps WHERE expires_at < NOW()');
  }
}

module.exports = OTP;