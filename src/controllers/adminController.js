const User = require('../models/User');

class AdminController {
  // Get pending users
  async getPendingUsers(req, res) {
    try {
      const users = await User.getPendingUsers();

      res.json({
        success: true,
        data: { users }
      });
    } catch (error) {
      console.error('Get pending users error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch pending users'
      });
    }
  }

  // Approve user
  async approveUser(req, res) {
    try {
      const { user_id } = req.params;

      const user = await User.findById(user_id);
      
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      if (user.status !== 'pending') {
        return res.status(400).json({
          success: false,
          message: 'User is not in pending status'
        });
      }

      await User.updateStatus(user_id, 'approved');

      res.json({
        success: true,
        message: 'User approved successfully'
      });
    } catch (error) {
      console.error('Approve user error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to approve user'
      });
    }
  }

  // Reject user
  async rejectUser(req, res) {
    try {
      const { user_id } = req.params;
      const { reason } = req.body;

      const user = await User.findById(user_id);
      
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      if (user.status !== 'pending') {
        return res.status(400).json({
          success: false,
          message: 'User is not in pending status'
        });
      }

      await User.updateStatus(user_id, 'rejected', reason);

      res.json({
        success: true,
        message: 'User rejected successfully'
      });
    } catch (error) {
      console.error('Reject user error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to reject user'
      });
    }
  }

  // Get all users
  async getAllUsers(req, res) {
    try {
      const { role, status } = req.query;
      
      const users = await User.getAllUsers({ role, status });

      res.json({
        success: true,
        data: { users }
      });
    } catch (error) {
      console.error('Get all users error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch users'
      });
    }
  }
}

module.exports = new AdminController();