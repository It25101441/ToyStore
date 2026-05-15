// File: com/toystore/servlet/RegisterServlet.java (updated)
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

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    private UserDAO userDAO = new UserDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("register.jsp").forward(request, response);
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
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            if (email == null || email.trim().isEmpty()) {
                request.setAttribute("error", "Email is required");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            if (password == null || password.trim().isEmpty()) {
                request.setAttribute("error", "Password is required");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            if (!password.equals(confirmPassword)) {
                request.setAttribute("error", "Passwords do not match");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            if (password.length() < 6) {
                request.setAttribute("error", "Password must be at least 6 characters");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Check if username already exists
            User existingUser = userDAO.getUserByUsername(username.trim());
            if (existingUser != null) {
                request.setAttribute("error", "Username already exists. Please choose a different username.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Check if email already exists
            existingUser = userDAO.getUserByEmail(email.trim());
            if (existingUser != null) {
                request.setAttribute("error", "Email already registered. Please use a different email.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Create user (password will be encrypted in DAO)
            User newUser = new User();
            newUser.setUsername(username.trim());
            newUser.setEmail(email.trim());
            newUser.setPassword(password);
            newUser.setFullName(fullName != null ? fullName.trim() : "");

            boolean isRegistered = userDAO.registerUser(newUser);

            if (isRegistered) {
                // Get the newly registered user's details
                User registeredUser = userDAO.loginUser(username.trim(), password);
                int newUserId = registeredUser != null ? registeredUser.getUserId() : -1;
                String customerName = (fullName != null && !fullName.trim().isEmpty()) ? fullName.trim() : username.trim();

                // Send welcome notification to new user
                String welcomeMessage = "🎉 Welcome to ToyStore, " + customerName + "! 🎉\n\n" +
                        "We're thrilled to have you join our toy family! Here's what you can do:\n" +
                        "✨ Browse our amazing collection of toys\n" +
                        "🛒 Add items to your cart and place orders\n" +
                        "📦 Track your orders easily\n" +
                        "🔔 Get notifications about your orders\n\n" +
                        "Start exploring and find the perfect toys for your little ones!\n\n" +
                        "Happy Shopping! 🧸";

                Notification welcomeNotification = new Notification(
                        newUserId,
                        welcomeMessage,
                        "WELCOME",
                        0
                );
                notificationDAO.createNotification(welcomeNotification);

                System.out.println("✅ User registered: " + username.trim() + " (ID: " + newUserId + ")");
                System.out.println("✅ Password encrypted with SHA-256 + salt");

                // Send notification to all admins
                String adminMessage = "🆕 NEW USER REGISTRATION! " + customerName + " (" + username.trim() + ") has joined ToyStore!";
                notificationDAO.createNotificationForAllAdmins(adminMessage, "NEW_USER", newUserId);

                request.setAttribute("success", "Registration successful! Please login.");
                request.getRequestDispatcher("login.jsp").forward(request, response);
            } else {
                request.setAttribute("error", "Registration failed. Please try again.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error: " + e.getMessage());
            request.getRequestDispatcher("register.jsp").forward(request, response);
        }
    }
}