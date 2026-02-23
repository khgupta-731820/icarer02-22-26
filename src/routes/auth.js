// routes/auth.js

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database'); // Your database connection

// POST /api/auth/login
router.post('/login', async (req, res) => {
    try {
        const { phone, password } = req.body;

        console.log('=== LOGIN REQUEST ===');
        console.log('Phone:', phone);

        if (!phone || !password) {
            return res.status(400).json({
                success: false,
                message: 'Phone number and password are required'
            });
        }

        // Clean phone number
        let cleanPhone = phone.replace(/[\s\-\(\)]/g, '');

        // Try multiple phone formats to match database
        const phoneVariants = [
            cleanPhone,
            cleanPhone.startsWith('+') ? cleanPhone.substring(3) : cleanPhone,
            cleanPhone.startsWith('+91') ? cleanPhone : `+91${cleanPhone}`,
            cleanPhone.startsWith('0') ? cleanPhone.substring(1) : cleanPhone,
        ];

        console.log('Trying phone variants:', phoneVariants);

        // Query database - adjust for your database type
        let user = null;

        // For MySQL/MariaDB:
        for (const phoneVariant of phoneVariants) {
            const [rows] = await db.execute(
                'SELECT * FROM users WHERE phone = ? LIMIT 1',
                [phoneVariant]
            );
            if (rows.length > 0) {
                user = rows[0];
                break;
            }
        }

        // // For MongoDB:
        // user = await User.findOne({ 
        //     phone: { $in: phoneVariants } 
        // });

        // // For PostgreSQL:
        // const result = await db.query(
        //     'SELECT * FROM users WHERE phone = ANY($1) LIMIT 1',
        //     [phoneVariants]
        // );
        // user = result.rows[0];

        if (!user) {
            console.log('User not found for any phone variant');
            return res.status(401).json({
                success: false,
                message: 'Invalid phone number or password'
            });
        }

        console.log('User found:', user.name, 'Role:', user.role);

        // Check password
        let passwordMatch = false;

        if (user.password.startsWith('$2')) {
            // Password is hashed with bcrypt
            passwordMatch = await bcrypt.compare(password, user.password);
        } else {
            // Plain text password (NOT recommended for production!)
            passwordMatch = (password === user.password);
            
            // Hash it for future use
            if (passwordMatch) {
                const hashedPassword = await bcrypt.hash(password, 10);
                await db.execute(
                    'UPDATE users SET password = ? WHERE id = ?',
                    [hashedPassword, user.id]
                );
                console.log('Password has been hashed for user:', user.id);
            }
        }

        if (!passwordMatch) {
            console.log('Password mismatch');
            return res.status(401).json({
                success: false,
                message: 'Invalid phone number or password'
            });
        }

        // Generate JWT token
        const token = jwt.sign(
            {
                id: user.id,
                phone: user.phone,
                role: user.role,
                name: user.name
            },
            process.env.JWT_SECRET || 'your-secret-key-change-in-production',
            { expiresIn: '7d' }
        );

        console.log('Login successful for:', user.name);

        res.json({
            success: true,
            message: 'Login successful',
            token: token,
            user: {
                id: user.id,
                name: user.name,
                phone: user.phone,
                role: user.role,
                email: user.email || null,
            }
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error. Please try again later.'
        });
    }
});

module.exports = router;