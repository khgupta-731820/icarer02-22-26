const User = require('../models/User');
const OTP = require('../models/OTP');
const TokenUtil = require('../utils/token');
const SMSUtil = require('../utils/sms');
const db = require('../config/database');

class AuthController {
  // Send OTP for registration
  async sendRegistrationOTP(req, res) {
    try {
      const { phone_number } = req.body;

      // Check if user already exists
      const existingUser = await User.findByPhone(phone_number);
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Phone number already registered'
        });
      }

      // Generate and send OTP
      const otpCode = await OTP.create(phone_number, 'registration');
      await SMSUtil.sendOTP(phone_number, otpCode);

      res.json({
        success: true,
        message: 'OTP sent successfully',
        data: {
          phone_number,
          expires_in_minutes: 10
        }
      });
    } catch (error) {
      console.error('Send OTP error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to send OTP',
        error: error.message
      });
    }
  }

  // Verify OTP
  async verifyOTP(req, res) {
    try {
      const { phone_number, otp_code } = req.body;

      const isValid = await OTP.verify(phone_number, otp_code, 'registration');

      if (!isValid) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or expired OTP'
        });
      }

      res.json({
        success: true,
        message: 'OTP verified successfully'
      });
    } catch (error) {
      console.error('Verify OTP error:', error);
      res.status(500).json({
        success: false,
        message: 'OTP verification failed',
        error: error.message
      });
    }
  }

  // Register user
  async register(req, res) {
    try {
      const { phone_number, email, password, full_name, role, role_details, ...otherData } = req.body;

      // Verify that OTP was verified
      const isOTPVerified = await OTP.isVerified(phone_number, 'registration');

      if (!isOTPVerified) {
        return res.status(400).json({
          success: false,
          message: 'Please verify OTP first'
        });
      }

      // Check if phone already exists
      const existingPhone = await User.findByPhone(phone_number);
      if (existingPhone) {
        return res.status(400).json({
          success: false,
          message: 'Phone number already registered'
        });
      }

      // Check if email already exists
      if (email) {
        const existingEmail = await User.findByEmail(email);
        if (existingEmail) {
          return res.status(400).json({
            success: false,
            message: 'Email already registered'
          });
        }
      }

      // Create user
      const userId = await User.create({
        phone_number,
        email,
        password,
        full_name,
        role,
        ...otherData
      });

      // Create role-specific details if provided
      if (role_details && role !== 'patient' && role !== 'admin') {
        await User.createRoleDetails(userId, role, role_details);
      }

      // Get created user
      const user = await User.findById(userId);

      // Generate tokens
      const accessToken = TokenUtil.generateAccessToken(user);
      const refreshToken = TokenUtil.generateRefreshToken(user);
      await TokenUtil.saveRefreshToken(userId, refreshToken);

      // Remove password from response
      delete user.password_hash;

      res.status(201).json({
        success: true,
        message: 'Registration successful',
        data: {
          user,
          tokens: {
            access_token: accessToken,
            refresh_token: refreshToken
          }
        }
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Registration failed',
        error: error.message
      });
    }
  }

  // Login
  async login(req, res) {
    try {
      const { phone_number, password, remember_me } = req.body;

      // Find user
      const user = await User.findByPhone(phone_number);
      
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Verify password
      const isPasswordValid = await User.verifyPassword(password, user.password_hash);
      
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Check if account is rejected
      if (user.status === 'rejected') {
        return res.status(403).json({
          success: false,
          message: 'Your account has been rejected',
          rejection_reason: user.rejection_reason
        });
      }

      // Update last login
      await User.updateLastLogin(user.id);

      // Generate tokens
      const accessToken = TokenUtil.generateAccessToken(user);
      const refreshToken = TokenUtil.generateRefreshToken(user);
      
      if (remember_me) {
        await TokenUtil.saveRefreshToken(user.id, refreshToken);
      }

      // Remove password from response
      delete user.password_hash;

      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user,
          tokens: {
            access_token: accessToken,
            refresh_token: remember_me ? refreshToken : null
          }
        }
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Login failed',
        error: error.message
      });
    }
  }

  // Refresh token
  async refreshToken(req, res) {
    try {
      const { refresh_token } = req.body;

      if (!refresh_token) {
        return res.status(400).json({
          success: false,
          message: 'Refresh token required'
        });
      }

      // Verify refresh token
      const decoded = await TokenUtil.verifyRefreshToken(refresh_token);

      // Get user
      const user = await User.findById(decoded.userId);
      
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'User not found'
        });
      }

      // Generate new access token
      const accessToken = TokenUtil.generateAccessToken(user);

      res.json({
        success: true,
        data: {
          access_token: accessToken
        }
      });
    } catch (error) {
      console.error('Refresh token error:', error);
      res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }
  }

  // Logout
  async logout(req, res) {
    try {
      const { refresh_token } = req.body;

      if (refresh_token) {
        await TokenUtil.deleteRefreshToken(refresh_token);
      }

      res.json({
        success: true,
        message: 'Logout successful'
      });
    } catch (error) {
      console.error('Logout error:', error);
      res.status(500).json({
        success: false,
        message: 'Logout failed'
      });
    }
  }

  // Get current user profile
  async getProfile(req, res) {
    try {
      const user = await User.findById(req.user.userId);
      
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      delete user.password_hash;

      res.json({
        success: true,
        data: { user }
      });
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch profile'
      });
    }
  }
}

module.exports = new AuthController();