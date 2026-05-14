package com.toystore.dao;

import com.toystore.model.Notification;
import com.toystore.model.User;
import com.toystore.utils.DBConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class NotificationDAO {

    public boolean createNotification(Notification notification) {
        String sql = "INSERT INTO notifications (user_id, message, type, is_read, related_id) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            pstmt.setInt(1, notification.getUserId());
            pstmt.setString(2, notification.getMessage());
            pstmt.setString(3, notification.getType());
            pstmt.setBoolean(4, notification.isRead());
            pstmt.setInt(5, notification.getRelatedId());

            int result = pstmt.executeUpdate();
            if (result > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    notification.setNotificationId(rs.getInt(1));
                }
                rs.close();
                System.out.println("Notification created for user: " + notification.getUserId() + " - Type: " + notification.getType());
                return true;
            }
            return false;
        } catch (SQLException e) {
            System.out.println("Error creating notification: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public boolean createNotificationForAdmin(int adminId, String message, String type, int relatedId) {
        String sql = "INSERT INTO notifications (user_id, message, type, is_read, related_id) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, adminId);
            pstmt.setString(2, message);
            pstmt.setString(3, type);
            pstmt.setBoolean(4, false);
            pstmt.setInt(5, relatedId);

            int result = pstmt.executeUpdate();
            System.out.println("Notification created for admin ID: " + adminId + " - Type: " + type);
            return result > 0;
        } catch (SQLException e) {
            System.out.println("Error creating notification for admin: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public boolean createNotificationForAllAdmins(String message, String type, int relatedId) {
        String sql = "INSERT INTO notifications (user_id, message, type, is_read, related_id) " +
                "SELECT user_id, ?, ?, FALSE, ? FROM users WHERE role = 'admin'";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, message);
            pstmt.setString(2, type);
            pstmt.setInt(3, relatedId);

            int result = pstmt.executeUpdate();
            System.out.println("Created " + result + " admin notifications for: " + message);
            return result > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean createNotificationForAllAdminsExcept(String message, String type, int relatedId, int excludeAdminId) {
        String sql = "INSERT INTO notifications (user_id, message, type, is_read, related_id) " +
                "SELECT user_id, ?, ?, FALSE, ? FROM users WHERE role = 'admin' AND user_id != ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, message);
            pstmt.setString(2, type);
            pstmt.setInt(3, relatedId);
            pstmt.setInt(4, excludeAdminId);

            int result = pstmt.executeUpdate();
            System.out.println("Created " + result + " admin notifications (excluding admin " + excludeAdminId + ") for: " + message);
            return result > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<Integer> getAdminUserIds() {
        List<Integer> adminIds = new ArrayList<>();
        String sql = "SELECT user_id FROM users WHERE role = 'admin'";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                adminIds.add(rs.getInt("user_id"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return adminIds;
    }

    public List<User> getAllAdmins() {
        List<User> admins = new ArrayList<>();
        String sql = "SELECT user_id, username, full_name, email FROM users WHERE role = 'admin'";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                User admin = new User();
                admin.setUserId(rs.getInt("user_id"));
                admin.setUsername(rs.getString("username"));
                admin.setFullName(rs.getString("full_name"));
                admin.setEmail(rs.getString("email"));
                admins.add(admin);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return admins;
    }

    public int getUnreadCount(int userId) {
        String sql = "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = FALSE";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public List<Notification> getNotificationsByUserId(int userId) {
        List<Notification> notifications = new ArrayList<>();
        String sql = "SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Notification notification = new Notification();
                notification.setNotificationId(rs.getInt("notification_id"));
                notification.setUserId(rs.getInt("user_id"));
                notification.setMessage(rs.getString("message"));
                notification.setType(rs.getString("type"));
                notification.setRead(rs.getBoolean("is_read"));
                notification.setCreatedAt(rs.getTimestamp("created_at"));
                notification.setRelatedId(rs.getInt("related_id"));
                notifications.add(notification);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return notifications;
    }

    public boolean markAsRead(int notificationId) {
        String sql = "UPDATE notifications SET is_read = TRUE WHERE notification_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, notificationId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean markAllAsRead(int userId) {
        String sql = "UPDATE notifications SET is_read = TRUE WHERE user_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean deleteNotification(int notificationId) {
        String sql = "DELETE FROM notifications WHERE notification_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, notificationId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}