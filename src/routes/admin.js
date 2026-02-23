const express = require('express');
const { body } = require('express-validator');
const adminController = require('../controllers/adminController');
const { authMiddleware, roleMiddleware } = require('../middleware/auth');
const validate = require('../middleware/validation');

const router = express.Router();

// All routes require authentication and admin role
router.use(authMiddleware);
router.use(roleMiddleware('admin'));

// Routes
router.get('/pending-users', adminController.getPendingUsers);
router.post('/approve-user/:user_id', adminController.approveUser);
router.post('/reject-user/:user_id', [
  body('reason').optional().isString(),
  validate
], adminController.rejectUser);
router.get('/users', adminController.getAllUsers);

module.exports = router;