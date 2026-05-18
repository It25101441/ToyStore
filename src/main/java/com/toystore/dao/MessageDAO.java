

public class MessageDAO {

    private NotificationDAO notificationDAO = new NotificationDAO();

    // Send a new message
    public boolean sendMessage(Message message) {
        String sql = "INSERT INTO messages (sender_id, receiver_id, subject, message, reply_to_id) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            pstmt.setInt(1, message.getSenderId());
            pstmt.setInt(2, message.getReceiverId());
            pstmt.setString(3, message.getSubject());
            pstmt.setString(4, message.getMessage());
            if (message.getReplyToId() != null) {
                pstmt.setInt(5, message.getReplyToId());
            } else {
                pstmt.setNull(5, Types.INTEGER);
            }

            int result = pstmt.executeUpdate();

            if (result > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    message.setMessageId(rs.getInt(1));
                }
                rs.close();

                // Create notification for receiver
                String senderName = getSenderName(message.getSenderId());
                String notificationMessage = "📧 New message from " + senderName + ": " +
                        (message.getSubject().length() > 50 ? message.getSubject().substring(0, 47) + "..." : message.getSubject());

                Notification notification = new Notification(
                        message.getReceiverId(),
                        notificationMessage,
                        "NEW_MESSAGE",
                        message.getMessageId()
                );
                notificationDAO.createNotification(notification);

                System.out.println("✅ Message sent from user " + message.getSenderId() + " to user " + message.getReceiverId());
                return true;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // Get sender name helper
    private String getSenderName(int senderId) {
        String sql = "SELECT username, full_name FROM users WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, senderId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                String fullName = rs.getString("full_name");
                String username = rs.getString("username");
                if (fullName != null && !fullName.isEmpty()) {
                    return fullName + " (" + username + ")";
                }
                return username != null ? username : "User";
            }
            rs.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return "User " + senderId;
    }

    // Get messages received by a user (inbox)
    public List<Message> getInboxMessages(int userId) {
        List<Message> messages = new ArrayList<>();
        String sql = "SELECT m.*, " +
                "u1.username as sender_username, u1.full_name as sender_fullname, " +
                "u2.username as receiver_username, u2.full_name as receiver_fullname " +
                "FROM messages m " +
                "LEFT JOIN users u1 ON m.sender_id = u1.user_id " +
                "LEFT JOIN users u2 ON m.receiver_id = u2.user_id " +
                "WHERE m.receiver_id = ? " +
                "ORDER BY m.created_at DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Message message = extractMessageFromResultSet(rs);
                messages.add(message);
            }
            rs.close();

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return messages;
    }

    // Get messages sent by a user (sent)
    public List<Message> getSentMessages(int userId) {
        List<Message> messages = new ArrayList<>();
        String sql = "SELECT m.*, " +
                "u1.username as sender_username, u1.full_name as sender_fullname, " +
                "u2.username as receiver_username, u2.full_name as receiver_fullname " +
                "FROM messages m " +
                "LEFT JOIN users u1 ON m.sender_id = u1.user_id " +
                "LEFT JOIN users u2 ON m.receiver_id = u2.user_id " +
                "WHERE m.sender_id = ? " +
                "ORDER BY m.created_at DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Message message = extractMessageFromResultSet(rs);
                messages.add(message);
            }
            rs.close();

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return messages;
    }

    // Get conversation between users for a specific message (original + replies)
    public List<Message> getConversation(int messageId) {
        List<Message> conversation = new ArrayList<>();

        String sql = "SELECT m.*, " +
                "u1.username as sender_username, u1.full_name as sender_fullname, " +
                "u2.username as receiver_username, u2.full_name as receiver_fullname " +
                "FROM messages m " +
                "LEFT JOIN users u1 ON m.sender_id = u1.user_id " +
                "LEFT JOIN users u2 ON m.receiver_id = u2.user_id " +
                "WHERE m.message_id = ? OR m.reply_to_id = ? " +
                "ORDER BY m.created_at ASC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, messageId);
            pstmt.setInt(2, messageId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Message message = extractMessageFromResultSet(rs);
                conversation.add(message);
            }
            rs.close();

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return conversation;
    }

    // Get single message by ID
    public Message getMessageById(int messageId) {
        String sql = "SELECT m.*, " +
                "u1.username as sender_username, u1.full_name as sender_fullname, " +
                "u2.username as receiver_username, u2.full_name as receiver_fullname " +
                "FROM messages m " +
                "LEFT JOIN users u1 ON m.sender_id = u1.user_id " +
                "LEFT JOIN users u2 ON m.receiver_id = u2.user_id " +
                "WHERE m.message_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, messageId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                Message message = extractMessageFromResultSet(rs);
                rs.close();
                return message;
            }
            rs.close();

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // Mark message as read
    public boolean markAsRead(int messageId) {
        String sql = "UPDATE messages SET is_read = TRUE WHERE message_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, messageId);
            return pstmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // Get unread message count for a user
    public int getUnreadCount(int userId) {
        String sql = "SELECT COUNT(*) FROM messages WHERE receiver_id = ? AND is_read = FALSE";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                int count = rs.getInt(1);
                rs.close();
                return count;
            }
            rs.close();

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    // Delete a message (and its replies)
    public boolean deleteMessage(int messageId) {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // Delete replies first
            String deleteRepliesSql = "DELETE FROM messages WHERE reply_to_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(deleteRepliesSql)) {
                pstmt.setInt(1, messageId);
                pstmt.executeUpdate();
            }

            // Delete the message
            String deleteSql = "DELETE FROM messages WHERE message_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(deleteSql)) {
                pstmt.setInt(1, messageId);
                int result = pstmt.executeUpdate();

                if (result > 0) {
                    conn.commit();
                    return true;
                }
            }

            conn.rollback();
            return false;

        } catch (SQLException e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) {}
            }
            return false;
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {}
            }
        }
    }

    // Get all admin users (for customer to send messages to)
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

    // Helper method to extract message from ResultSet
    private Message extractMessageFromResultSet(ResultSet rs) throws SQLException {
        Message message = new Message();
        message.setMessageId(rs.getInt("message_id"));
        message.setSenderId(rs.getInt("sender_id"));
        message.setReceiverId(rs.getInt("receiver_id"));
        message.setSubject(rs.getString("subject"));
        message.setMessage(rs.getString("message"));

        int replyToId = rs.getInt("reply_to_id");
        if (!rs.wasNull()) {
            message.setReplyToId(replyToId);
        }

        message.setRead(rs.getBoolean("is_read"));
        message.setCreatedAt(rs.getTimestamp("created_at"));

        // Set sender name with proper null handling
        String senderUsername = rs.getString("sender_username");
        String senderFullname = rs.getString("sender_fullname");

        if (senderFullname != null && !senderFullname.trim().isEmpty()) {
            message.setSenderName(senderFullname + " (" + (senderUsername != null ? senderUsername : "user") + ")");
        } else if (senderUsername != null && !senderUsername.trim().isEmpty()) {
            message.setSenderName(senderUsername);
        } else {
            message.setSenderName("User " + message.getSenderId());
        }

        // Set receiver name with proper null handling
        String receiverUsername = rs.getString("receiver_username");
        String receiverFullname = rs.getString("receiver_fullname");

        if (receiverFullname != null && !receiverFullname.trim().isEmpty()) {
            message.setReceiverName(receiverFullname + " (" + (receiverUsername != null ? receiverUsername : "user") + ")");
        } else if (receiverUsername != null && !receiverUsername.trim().isEmpty()) {
            message.setReceiverName(receiverUsername);
        } else {
            message.setReceiverName("User " + message.getReceiverId());
        }

        return message;
    }
}
