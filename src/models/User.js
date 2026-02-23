const db = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  static async create(userData) {
    const { phone_number, email, password, full_name, role, ...otherData } = userData;
    
    const passwordHash = await bcrypt.hash(password, 10);
    
    // Set status based on role
    const status = role === 'patient' ? 'approved' : 'pending';
    
    const [result] = await db.query(
      `INSERT INTO users 
       (phone_number, email, password_hash, full_name, role, status, 
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
        true // Phone is verified after OTP
      ]
    );
    
    return result.insertId;
  }

  static async createRoleDetails(userId, role, details) {
    try {
      if (role === 'doctor') {
        if (!details.specialization || !details.qualification || !details.registration_number) {
          throw new Error('Missing required doctor details');
        }
        
        await db.query(
          `INSERT INTO doctor_details 
           (user_id, specialization, qualification, registration_number, 
            years_of_experience, consultation_fee, bio) 
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            userId,
            details.specialization,
            details.qualification,
            details.registration_number,
            details.years_of_experience || null,
            details.consultation_fee || null,
            details.bio || null
          ]
        );
      } else if (role === 'lab_technician') {
        if (!details.lab_name || !details.license_number) {
          throw new Error('Missing required lab technician details');
        }
        
        await db.query(
          `INSERT INTO lab_technician_details 
           (user_id, lab_name, license_number, specialization) 
           VALUES (?, ?, ?, ?)`,
          [
            userId,
            details.lab_name,
            details.license_number,
            details.specialization || null
          ]
        );
      } else if (role === 'pharmacy') {
        if (!details.pharmacy_name || !details.license_number) {
          throw new Error('Missing required pharmacy details');
        }
        
        await db.query(
          `INSERT INTO pharmacy_details 
           (user_id, pharmacy_name, license_number, gst_number) 
           VALUES (?, ?, ?, ?)`,
          [
            userId,
            details.pharmacy_name,
            details.license_number,
            details.gst_number || null
          ]
        );
      }
    } catch (error) {
      console.error('Error creating role details:', error);
      throw error;
    }
  }

  static async findByPhone(phoneNumber) {
    const [rows] = await db.query(
      'SELECT * FROM users WHERE phone_number = ?',
      [phoneNumber]
    );
    return rows[0];
  }

  static async findByEmail(email) {
    const [rows] = await db.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );
    return rows[0];
  }

  static async findById(id) {
    const [rows] = await db.query(
      'SELECT * FROM users WHERE id = ?',
      [id]
    );
    return rows[0];
  }

  static async verifyPhone(phoneNumber) {
    await db.query(
      'UPDATE users SET is_phone_verified = TRUE WHERE phone_number = ?',
      [phoneNumber]
    );
  }

  static async updateLastLogin(userId) {
    await db.query(
      'UPDATE users SET last_login = NOW() WHERE id = ?',
      [userId]
    );
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  static async updateStatus(userId, status, rejectionReason = null) {
    await db.query(
      'UPDATE users SET status = ?, rejection_reason = ? WHERE id = ?',
      [status, rejectionReason, userId]
    );
  }

  static async getPendingUsers() {
    const [rows] = await db.query(`
      SELECT u.id, u.phone_number, u.email, u.full_name, u.role, 
             u.status, u.created_at, u.city, u.state,
        dd.specialization as doctor_specialization,
        dd.qualification as doctor_qualification,
        dd.registration_number as doctor_registration,
        ltd.lab_name,
        ltd.license_number as lab_license,
        pd.pharmacy_name,
        pd.license_number as pharmacy_license
      FROM users u
      LEFT JOIN doctor_details dd ON u.id = dd.user_id
      LEFT JOIN lab_technician_details ltd ON u.id = ltd.user_id
      LEFT JOIN pharmacy_details pd ON u.id = pd.user_id
      WHERE u.status = 'pending' AND u.role != 'patient'
      ORDER BY u.created_at DESC
    `);
    return rows;
  }

  static async getAllUsers(filters = {}) {
    let query = `
      SELECT u.id, u.phone_number, u.email, u.full_name, u.role, 
             u.status, u.created_at, u.last_login
      FROM users u
      WHERE 1=1
    `;
    const params = [];

    if (filters.role) {
      query += ' AND u.role = ?';
      params.push(filters.role);
    }

    if (filters.status) {
      query += ' AND u.status = ?';
      params.push(filters.status);
    }

    query += ' ORDER BY u.created_at DESC';

    const [rows] = await db.query(query, params);
    return rows;
  }
}

module.exports = User;