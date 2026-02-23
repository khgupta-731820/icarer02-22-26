const jwt = require('jsonwebtoken');
const config = require('../config/config');
const db = require('../config/database');

class TokenUtil {
  // Generate access token
  static generateAccessToken(user) {
    const payload = {
      userId: user.id,
      phone: user.phone_number,
      role: user.role,
      status: user.status
    };

    return jwt.sign(payload, config.jwt.secret, {
      expiresIn: config.jwt.expire
    });
  }

  // Generate refresh token
  static generateRefreshToken(user) {
    const payload = {
      userId: user.id,
      type: 'refresh'
    };

    return jwt.sign(payload, config.jwt.refreshSecret, {
      expiresIn: config.jwt.refreshExpire
    });
  }

  // Save refresh token to database
  static async saveRefreshToken(userId, token) {
    try {
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

      await db.query(
        'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, ?)',
        [userId, token, expiresAt]
      );
    } catch (error) {
      console.error('Error saving refresh token:', error);
    }
  }

  // Verify access token
  static verifyAccessToken(token) {
    try {
      return jwt.verify(token, config.jwt.secret);
    } catch (error) {
      throw new Error('Invalid or expired token');
    }
  }

  // Verify refresh token
  static async verifyRefreshToken(token) {
    try {
      const decoded = jwt.verify(token, config.jwt.refreshSecret);
      
      // Check if token exists in database
      const [rows] = await db.query(
        'SELECT * FROM refresh_tokens WHERE token = ? AND expires_at > NOW()',
        [token]
      );

      if (rows.length === 0) {
        throw new Error('Invalid refresh token');
      }

      return decoded;
    } catch (error) {
      throw new Error('Invalid or expired refresh token');
    }
  }

  // Delete refresh token
  static async deleteRefreshToken(token) {
    try {
      await db.query('DELETE FROM refresh_tokens WHERE token = ?', [token]);
    } catch (error) {
      console.error('Error deleting refresh token:', error);
    }
  }

  // Delete all user refresh tokens
  static async deleteUserTokens(userId) {
    try {
      await db.query('DELETE FROM refresh_tokens WHERE user_id = ?', [userId]);
    } catch (error) {
      console.error('Error deleting user tokens:', error);
    }
  }
}

module.exports = TokenUtil;