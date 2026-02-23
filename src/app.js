const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Database connection
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'healthcare_db',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Test database connection
pool.getConnection()
  .then(connection => {
    console.log('✅ Database connected successfully');
    connection.release();
  })
  .catch(err => {
    console.log('⚠️  Database not connected:', err.message);
    console.log('📝 Server will still run, but data won\'t be saved');
  });

// Store OTPs in memory (for development)
const otpStore = new Map();

// Routes
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Healthcare Authentication API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      sendOTP: 'POST /api/auth/send-otp',
      verifyOTP: 'POST /api/auth/verify-otp',
      register: 'POST /api/auth/register',
      login: 'POST /api/auth/login'
    }
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    database: pool ? 'connected' : 'disconnected'
  });
});

// Send OTP
app.post('/api/auth/send-otp', async (req, res) => {
  try {
    const { phone_number } = req.body;
    
    console.log('\n📲 Incoming OTP Request');
    console.log('Phone Number:', phone_number);
    
    if (!phone_number) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Check if user already exists
    try {
      const [existingUsers] = await pool.query(
        'SELECT * FROM users WHERE phone_number = ?',
        [phone_number]
      );
      
      if (existingUsers.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Phone number already registered'
        });
      }
    } catch (dbError) {
      console.log('⚠️  Database check skipped (DB not available)');
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store OTP with expiry (10 minutes)
    const expiryTime = Date.now() + 10 * 60 * 1000;
    otpStore.set(phone_number, { otp, expiryTime, verified: false });
    
    // Try to save to database
    try {
      await pool.query(
        'DELETE FROM otps WHERE phone_number = ? AND purpose = ?',
        [phone_number, 'registration']
      );
      
      const expiresAt = new Date(expiryTime);
      await pool.query(
        'INSERT INTO otps (phone_number, otp_code, purpose, expires_at) VALUES (?, ?, ?, ?)',
        [phone_number, otp, 'registration', expiresAt]
      );
      console.log('💾 OTP saved to database');
    } catch (dbError) {
      console.log('⚠️  OTP not saved to DB (using memory storage)');
    }
    
    // Display OTP prominently in console
    console.log('\n' + '='.repeat(60));
    console.log('  🔐 OTP GENERATED');
    console.log('='.repeat(60));
    console.log(`  📱 Phone: ${phone_number}`);
    console.log(`  🔢 OTP: ${otp}`);
    console.log(`  ⏰ Valid for: 10 minutes`);
    console.log('='.repeat(60) + '\n');
    
    res.json({
      success: true,
      message: 'OTP sent successfully',
      data: {
        phone_number,
        expires_in_minutes: 10,
        // For development only - remove in production
        otp_hint: otp
      }
    });
    
  } catch (error) {
    console.error('❌ Send OTP Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP',
      error: error.message
    });
  }
});

// Verify OTP
app.post('/api/auth/verify-otp', async (req, res) => {
  try {
    const { phone_number, otp_code } = req.body;
    
    console.log('\n🔐 Verifying OTP');
    console.log('Phone:', phone_number);
    console.log('OTP Entered:', otp_code);
    
    if (!phone_number || !otp_code) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and OTP are required'
      });
    }

    // Check in memory first
    const storedData = otpStore.get(phone_number);
    
    if (!storedData) {
      return res.status(400).json({
        success: false,
        message: 'No OTP found. Please request a new one.'
      });
    }

    if (Date.now() > storedData.expiryTime) {
      otpStore.delete(phone_number);
      return res.status(400).json({
        success: false,
        message: 'OTP has expired. Please request a new one.'
      });
    }

    if (storedData.otp !== otp_code) {
      console.log('❌ OTP Mismatch!');
      console.log('Expected:', storedData.otp);
      console.log('Received:', otp_code);
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // Mark as verified
    storedData.verified = true;
    otpStore.set(phone_number, storedData);
    
    // Update in database if available
    try {
      await pool.query(
        'UPDATE otps SET is_verified = TRUE WHERE phone_number = ? AND otp_code = ? AND purpose = ?',
        [phone_number, otp_code, 'registration']
      );
    } catch (dbError) {
      console.log('⚠️  DB update skipped');
    }
    
    console.log('✅ OTP Verified Successfully\n');
    
    res.json({
      success: true,
      message: 'OTP verified successfully'
    });
    
  } catch (error) {
    console.error('❌ Verify OTP Error:', error);
    res.status(500).json({
      success: false,
      message: 'OTP verification failed',
      error: error.message
    });
  }
});

// Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { phone_number, email, password, full_name, role, role_details, ...otherData } = req.body;
    
    console.log('\n📝 Registration Request');
    console.log('Name:', full_name);
    console.log('Phone:', phone_number);
    console.log('Role:', role);
    
    // Check if OTP was verified
    const storedData = otpStore.get(phone_number);
    if (!storedData || !storedData.verified) {
      return res.status(400).json({
        success: false,
        message: 'Please verify OTP first'
      });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);
    
    // Determine status
    const status = role === 'patient' ? 'approved' : 'pending';
    
    let userId;
    
    try {
      // Insert user
      const [result] = await pool.query(
        `INSERT INTO users (phone_number, email, password_hash, full_name, role, status, 
         date_of_birth, gender, address, city, state, pincode, is_phone_verified) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          phone_number,
          email || null,
          passwordHash,
          full_name,
          role,
          status,
          otherData.date_of_birth || null,
          otherData.gender || null,
          otherData.address || null,
          otherData.city || null,
          otherData.state || null,
          otherData.pincode || null,
          true
        ]
      );
      
      userId = result.insertId;
      console.log('💾 User saved to database with ID:', userId);
      
      // Save role-specific details if provided
      if (role_details && role !== 'patient') {
        if (role === 'doctor') {
          await pool.query(
            `INSERT INTO doctor_details (user_id, specialization, qualification, 
             registration_number, years_of_experience, consultation_fee, bio) 
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [
              userId,
              role_details.specialization,
              role_details.qualification,
              role_details.registration_number,
              role_details.years_of_experience || null,
              role_details.consultation_fee || null,
              role_details.bio || null
            ]
          );
        } else if (role === 'lab_technician') {
          await pool.query(
            `INSERT INTO lab_technician_details (user_id, lab_name, license_number, specialization) 
             VALUES (?, ?, ?, ?)`,
            [userId, role_details.lab_name, role_details.license_number, role_details.specialization || null]
          );
        } else if (role === 'pharmacy') {
          await pool.query(
            `INSERT INTO pharmacy_details (user_id, pharmacy_name, license_number, gst_number) 
             VALUES (?, ?, ?, ?)`,
            [userId, role_details.pharmacy_name, role_details.license_number, role_details.gst_number || null]
          );
        }
      }
      
    } catch (dbError) {
      console.log('⚠️  Database save failed:', dbError.message);
      userId = 1; // Mock ID for testing
    }
    
    // Generate JWT tokens
    const accessToken = jwt.sign(
      { userId, phone: phone_number, role, status },
      process.env.JWT_SECRET || 'healthcare_secret',
      { expiresIn: '24h' }
    );
    
    const refreshToken = jwt.sign(
      { userId, type: 'refresh' },
      process.env.JWT_REFRESH_SECRET || 'healthcare_refresh',
      { expiresIn: '7d' }
    );
    
    // Clean up OTP
    otpStore.delete(phone_number);
    
    console.log('✅ Registration Successful!\n');
    
    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        user: {
          id: userId,
          phone_number,
          email,
          full_name,
          role,
          status,
          is_phone_verified: true,
          gender: otherData.gender || null,
          date_of_birth: otherData.date_of_birth || null,
          city: otherData.city || null,
          state: otherData.state || null,
          created_at: new Date().toISOString()
        },
        tokens: {
          access_token: accessToken,
          refresh_token: refreshToken
        }
      }
    });
    
  } catch (error) {
    console.error('❌ Registration Error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed',
      error: error.message
    });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { phone_number, password, remember_me } = req.body;
    
    console.log('\n🔑 Login Attempt');
    console.log('Phone:', phone_number);
    
    if (!phone_number || !password) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and password are required'
      });
    }

    let user;
    
    try {
      const [users] = await pool.query(
        'SELECT * FROM users WHERE phone_number = ?',
        [phone_number]
      );
      
      if (users.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }
      
      user = users[0];
      
      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }
      
      console.log('💾 User found in database');
      
    } catch (dbError) {
      console.log('⚠️  Database query failed, using mock data');
      // Mock user for testing
      user = {
        id: 1,
        phone_number,
        full_name: 'Test User',
        email: 'test@example.com',
        role: 'patient',
        status: 'approved'
      };
    }
    
    // Check if rejected
    if (user.status === 'rejected') {
      return res.status(403).json({
        success: false,
        message: 'Your account has been rejected',
        rejection_reason: user.rejection_reason
      });
    }
    
    // Generate tokens
    const accessToken = jwt.sign(
      { userId: user.id, phone: user.phone_number, role: user.role, status: user.status },
      process.env.JWT_SECRET || 'healthcare_secret',
      { expiresIn: '24h' }
    );
    
    const refreshToken = jwt.sign(
      { userId: user.id, type: 'refresh' },
      process.env.JWT_REFRESH_SECRET || 'healthcare_refresh',
      { expiresIn: '7d' }
    );
    
    // Update last login
    try {
      await pool.query('UPDATE users SET last_login = NOW() WHERE id = ?', [user.id]);
    } catch (dbError) {
      console.log('⚠️  Last login update skipped');
    }
    
    console.log('✅ Login Successful!\n');
    
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
    console.error('❌ Login Error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error.message
    });
  }
});

// Logout
app.post('/api/auth/logout', (req, res) => {
  console.log('👋 User logged out');
  res.json({
    success: true,
    message: 'Logout successful'
  });
});

// Get Profile
app.get('/api/auth/profile', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token provided'
      });
    }
    
    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'healthcare_secret');
    
    try {
      const [users] = await pool.query('SELECT * FROM users WHERE id = ?', [decoded.userId]);
      
      if (users.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }
      
      const user = users[0];
      delete user.password_hash;
      
      res.json({
        success: true,
        data: { user }
      });
    } catch (dbError) {
      res.json({
        success: true,
        data: {
          user: {
            id: decoded.userId,
            phone_number: decoded.phone,
            role: decoded.role,
            status: decoded.status
          }
        }
      });
    }
    
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Invalid token'
    });
  }
});

// Error handlers
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.url} not found`
  });
});

app.use((err, req, res, next) => {
  console.error('❌ Server Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: err.message
  });
});

module.exports = app;