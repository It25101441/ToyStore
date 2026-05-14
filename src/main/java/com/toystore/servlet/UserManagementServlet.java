package com.toystore.servlet;

import com.toystore.dao.UserDAO;
import com.toystore.dao.NotificationDAO;
import com.toystore.model.Notification;
import com.toystore.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;

@WebServlet("/users")
public class UserManagementServlet extends HttpServlet {

    private UserDAO userDAO = new UserDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && user.isAdmin();
    }

    private int getCurrentUserId(HttpSession session) {
        User user = (User) session.getAttribute("user");
        return user != null ? user.getUserId() : -1;
    }

    private String getCurrentAdminName(HttpSession session) {
        User user = (User) session.getAttribute("user");
        if (user != null) {
            if (user.getFullName() != null && !user.getFullName().isEmpty()) {
                return user.getFullName();
            }
            return user.getUsername();
        }
        return "Admin";
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        // Check if user is logged in and is admin
        if (!isAdmin(session)) {
            response.sendRedirect("login");
            return;
        }

        String action = request.getParameter("action");
        String searchKeyword = request.getParameter("search");

        // Get total counts for stats (always from database, not filtered)
        int totalUserCount = userDAO.getUserCount();
        int totalAdminCount = userDAO.getAdminCount();
        int totalCustomerCount = userDAO.getCustomerCount();

        // Handle search
        if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
            List<User> users = userDAO.searchUsers(searchKeyword.trim());

            // Calculate filtered counts from search results
            int filteredAdminCount = 0;
            int filteredCustomerCount = 0;
            for (User u : users) {
                if ("admin".equals(u.getRole())) filteredAdminCount++;
                else filteredCustomerCount++;
            }

            request.setAttribute("users", users);
            request.setAttribute("userCount", users.size());
            request.setAttribute("adminCount", filteredAdminCount);
            request.setAttribute("customerCount", filteredCustomerCount);
            request.setAttribute("searchKeyword", searchKeyword.trim());
            request.setAttribute("isSearchResult", true);
            request.setAttribute("totalUserCount", totalUserCount);
            request.setAttribute("totalAdminCount", totalAdminCount);
            request.setAttribute("totalCustomerCount", totalCustomerCount);
            request.getRequestDispatcher("users.jsp").forward(request, response);
            return;
        }

        if ("edit".equals(action)) {
            int userId = Integer.parseInt(request.getParameter("id"));
            User editUser = userDAO.getUserById(userId);
            List<User> users = userDAO.getAllUsers();

            int adminCount = 0;
            for (User u : users) {
                if ("admin".equals(u.getRole())) adminCount++;
            }
            int customerCount = users.size() - adminCount;

            request.setAttribute("users", users);
            request.setAttribute("editUser", editUser);
            request.setAttribute("userCount", users.size());
            request.setAttribute("adminCount", adminCount);
            request.setAttribute("customerCount", customerCount);
            request.setAttribute("isSearchResult", false);
            request.getRequestDispatcher("users.jsp").forward(request, response);

        } else if ("delete".equals(action)) {
            int userId = Integer.parseInt(request.getParameter("id"));
            int currentUserId = getCurrentUserId(session);
            String currentAdminName = getCurrentAdminName(session);

            // Get user details before deletion for notification
            User userToDelete = userDAO.getUserById(userId);
            String deletedUserName = userToDelete != null ? userToDelete.getUsername() : "Unknown User";
            String deletedUserFullName = (userToDelete != null && userToDelete.getFullName() != null && !userToDelete.getFullName().isEmpty())
                    ? userToDelete.getFullName() : deletedUserName;
            String deletedUserRole = userToDelete != null ? userToDelete.getRole() : "user";

            // Prevent admin from deleting themselves
            if (userId == currentUserId) {
                session.setAttribute("errorMessage", "You cannot delete your own admin account!");
            } else {
                boolean deleted = userDAO.deleteUser(userId);
                if (deleted) {
                    session.setAttribute("successMessage", "User deleted successfully!");

                    // Send notification to all admins about user deletion
                    String roleText = "admin".equals(deletedUserRole) ? "Admin" : "Customer";
                    String notificationMessage = "🗑️ USER DELETED by " + currentAdminName + ": " + roleText + " \"" + deletedUserFullName + "\" (Username: " + deletedUserName + ", ID: #" + userId + ") has been removed from the system.";
                    notificationDAO.createNotificationForAllAdminsExcept(notificationMessage, "USER_DELETED", userId, currentUserId);

                    // Also send notification to the admin who performed the action
                    String selfNotification = "✅ You successfully deleted user: \"" + deletedUserFullName + "\" (Username: " + deletedUserName + ", ID: #" + userId + ")";
                    Notification selfNotif = new Notification(currentUserId, selfNotification, "ADMIN_ACTION", userId);
                    notificationDAO.createNotification(selfNotif);

                } else {
                    session.setAttribute("errorMessage", "Cannot delete user with existing orders!");
                }
            }
            response.sendRedirect("users");

        } else {
            // Show all users
            List<User> users = userDAO.getAllUsers();

            int adminCount = 0;
            for (User u : users) {
                if ("admin".equals(u.getRole())) adminCount++;
            }
            int customerCount = users.size() - adminCount;

            request.setAttribute("users", users);
            request.setAttribute("userCount", users.size());
            request.setAttribute("adminCount", adminCount);
            request.setAttribute("customerCount", customerCount);
            request.setAttribute("isSearchResult", false);
            request.getRequestDispatcher("users.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!isAdmin(session)) {
            response.sendRedirect("login");
            return;
        }

        String action = request.getParameter("action");
        int currentAdminId = getCurrentUserId(session);
        String currentAdminName = getCurrentAdminName(session);

        if ("update".equals(action)) {
            try {
                int userId = Integer.parseInt(request.getParameter("userId"));
                String username = request.getParameter("username");
                String email = request.getParameter("email");
                String fullName = request.getParameter("fullName");
                String address = request.getParameter("address");
                String phone = request.getParameter("phone");
                String role = request.getParameter("role");

                // Get old user details before update for notification
                User oldUser = userDAO.getUserById(userId);
                String oldUsername = oldUser != null ? oldUser.getUsername() : "Unknown";
                String oldFullName = (oldUser != null && oldUser.getFullName() != null && !oldUser.getFullName().isEmpty())
                        ? oldUser.getFullName() : oldUsername;
                String oldRole = oldUser != null ? oldUser.getRole() : "user";
                String oldEmail = oldUser != null ? oldUser.getEmail() : "";
                String oldPhone = oldUser != null ? oldUser.getPhone() : "";
                String oldAddress = oldUser != null ? oldUser.getAddress() : "";

                // Validation
                if (username == null || username.trim().isEmpty()) {
                    session.setAttribute("errorMessage", "Username is required!");
                    response.sendRedirect("users");
                    return;
                }

                if (email == null || email.trim().isEmpty()) {
                    session.setAttribute("errorMessage", "Email is required!");
                    response.sendRedirect("users");
                    return;
                }

                User user = new User();
                user.setUserId(userId);
                user.setUsername(username.trim());
                user.setEmail(email.trim());
                user.setFullName(fullName != null ? fullName.trim() : "");
                user.setAddress(address != null ? address.trim() : "");
                user.setPhone(phone != null ? phone.trim() : "");
                user.setRole(role);

                boolean updated = userDAO.updateUser(user);

                if (updated) {
                    session.setAttribute("successMessage", "User #" + userId + " updated successfully!");

                    // Build notification message with changes
                    StringBuilder changes = new StringBuilder();
                    if (!oldUsername.equals(username.trim())) {
                        changes.append("\n  • Username: \"").append(oldUsername).append("\" → \"").append(username.trim()).append("\"");
                    }
                    if (!oldFullName.equals(fullName != null ? fullName.trim() : "")) {
                        changes.append("\n  • Full Name: \"").append(oldFullName).append("\" → \"").append(fullName != null ? fullName.trim() : "").append("\"");
                    }
                    if (!oldEmail.equals(email.trim())) {
                        changes.append("\n  • Email: \"").append(oldEmail).append("\" → \"").append(email.trim()).append("\"");
                    }
                    if (!oldRole.equals(role)) {
                        String oldRoleText = "admin".equals(oldRole) ? "Admin" : "Customer";
                        String newRoleText = "admin".equals(role) ? "Admin" : "Customer";
                        changes.append("\n  • Role: ").append(oldRoleText).append(" → ").append(newRoleText);
                    }
                    if ((oldPhone == null ? "" : oldPhone).equals(phone != null ? phone.trim() : "")) {
                        // No change
                    } else {
                        changes.append("\n  • Phone: \"").append(oldPhone == null ? "" : oldPhone).append("\" → \"").append(phone != null ? phone.trim() : "").append("\"");
                    }
                    if ((oldAddress == null ? "" : oldAddress).equals(address != null ? address.trim() : "")) {
                        // No change
                    } else {
                        changes.append("\n  • Address: Updated");
                    }

                    String userDisplayName = (fullName != null && !fullName.trim().isEmpty()) ? fullName.trim() : username.trim();
                    String roleText = "admin".equals(role) ? "Admin" : "Customer";

                    String notificationMessage = "✏️ USER UPDATED by " + currentAdminName + ": " + roleText + " \"" + userDisplayName + "\" (ID: #" + userId + ")" + changes.toString();
                    notificationDAO.createNotificationForAllAdminsExcept(notificationMessage, "USER_UPDATED", userId, currentAdminId);

                    // Also send notification to the admin who performed the action
                    String selfNotification = "✅ You successfully updated user: \"" + userDisplayName + "\" (ID: #" + userId + ")" + changes.toString();
                    Notification selfNotif = new Notification(currentAdminId, selfNotification, "ADMIN_ACTION", userId);
                    notificationDAO.createNotification(selfNotif);

                    // If the updated user is not an admin, send them a notification about their profile being updated by admin
                    if (!"admin".equals(role)) {
                        String userNotificationMessage = "📝 Your profile has been updated by an administrator.\n\nUpdated information:\n" +
                                "• Username: " + username.trim() + "\n" +
                                "• Full Name: " + (fullName != null ? fullName.trim() : "") + "\n" +
                                "• Email: " + email.trim() + "\n" +
                                "• Phone: " + (phone != null ? phone.trim() : "Not provided") + "\n" +
                                "• Address: " + (address != null ? address.trim() : "Not provided") + "\n\n" +
                                "If you have any questions, please contact our support team.";
                        Notification userNotif = new Notification(userId, userNotificationMessage, "PROFILE_UPDATED_BY_ADMIN", 0);
                        notificationDAO.createNotification(userNotif);
                    }

                } else {
                    session.setAttribute("errorMessage", "Failed to update user!");
                }
            } catch (NumberFormatException e) {
                session.setAttribute("errorMessage", "Invalid user ID!");
            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("errorMessage", "Error updating user: " + e.getMessage());
            }
            response.sendRedirect("users");
        }
    }
}