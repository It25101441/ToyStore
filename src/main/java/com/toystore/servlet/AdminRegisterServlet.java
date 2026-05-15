// File: com/toystore/servlet/AdminRegisterServlet.java
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
import java.io.IOException;

@WebServlet("/adminRegister")
public class AdminRegisterServlet extends HttpServlet {

    private UserDAO userDAO = new UserDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            String username = request.getParameter("username");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String confirmPassword = request.getParameter("confirmPassword");
            String fullName = request.getParameter("fullName");

            // Validation
            if (username == null || username.trim().isEmpty()) {
                request.setAttribute("error", "Username is required");
                request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
                return;
            }

            if (email == null || email.trim().isEmpty()) {
                request.setAttribute("error", "Email is required");
                request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
                return;
            }

            if (password == null || password.trim().isEmpty()) {
                request.setAttribute("error", "Password is required");
                request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
                return;
            }

            if (!password.equals(confirmPassword)) {
                request.setAttribute("error", "Passwords do not match");
                request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
                return;
            }

            if (password.length() < 6) {
                request.setAttribute("error", "Password must be at least 6 characters");
                request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
                return;
            }

            // Check if username already exists
            User existingUser = userDAO.getUserByUsername(username.trim());
            if (existingUser != null) {
                request.setAttribute("error", "Username already exists. Please choose a different username.");
                request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
                return;
            }

            // Check if email already exists
            existingUser = userDAO.getUserByEmail(email.trim());
            if (existingUser != null) {
                request.setAttribute("error", "Email already registered. Please use a different email.");
                request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
                return;
            }

            // Create admin user
            User adminUser = new User();
            adminUser.setUsername(username.trim());
            adminUser.setEmail(email.trim());
            adminUser.setPassword(password);
            adminUser.setFullName(fullName != null ? fullName.trim() : "");

            boolean isRegistered = userDAO.registerUserWithRole(adminUser, "admin");

            if (isRegistered) {
                // Get the newly registered admin's details
                User registeredAdmin = userDAO.loginUser(username.trim(), password);
                int newAdminId = registeredAdmin != null ? registeredAdmin.getUserId() : -1;
                String adminName = (fullName != null && !fullName.trim().isEmpty()) ? fullName.trim() : username.trim();

                // Send welcome notification to new admin
                String welcomeMessage = "👑 Welcome to ToyStore Admin Panel, " + adminName + "! 👑\n\n" +
                        "You have been successfully registered as an Administrator.\n\n" +
                        "As an admin, you have the following privileges:\n" +
                        "✨ Manage Products (Add, Edit, Delete)\n" +
                        "✨ View and Manage All Customer Orders\n" +
                        "✨ Update Order Statuses\n" +
                        "✨ Manage User Accounts\n" +
                        "✨ Receive Notifications for New Orders and Registrations\n\n" +
                        "Please keep your credentials secure and use the admin panel responsibly.\n\n" +
                        "Thank you for managing ToyStore! 🧸";

                Notification welcomeNotification = new Notification(
                        newAdminId,
                        welcomeMessage,
                        "ADMIN_WELCOME",
                        0
                );
                notificationDAO.createNotification(welcomeNotification);

                // Send notification to ALL OTHER ADMINS about new admin registration
                String adminNotificationMessage = "🆕 NEW ADMIN REGISTERED: " + adminName + " (Username: " + username.trim() + ", Email: " + email.trim() + ") has joined as an Administrator!";
                notificationDAO.createNotificationForAllAdminsExcept(adminNotificationMessage, "NEW_ADMIN", newAdminId, newAdminId);

                System.out.println("✅ Admin account created: " + username.trim() + " (ID: " + newAdminId + ")");
                System.out.println("✅ Password encrypted with SHA-256 + salt");

                request.setAttribute("success", "Admin account created successfully! Please login with your credentials.");
                request.getRequestDispatcher("login.jsp").forward(request, response);
            } else {
                request.setAttribute("error", "Admin registration failed. Please try again.");
                request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error: " + e.getMessage());
            request.getRequestDispatcher("adminRegister.jsp").forward(request, response);
        }
    }
}