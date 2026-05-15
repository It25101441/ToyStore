// File: com/toystore/servlet/ProfileServlet.java
package com.toystore.servlet;

import com.toystore.dao.UserDAO;
import com.toystore.dao.NotificationDAO;
import com.toystore.model.User;
import com.toystore.model.Notification;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/profile")
public class ProfileServlet extends HttpServlet {

    private UserDAO userDAO = new UserDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();

    private boolean isLoggedIn(HttpSession session) {
        return session != null && session.getAttribute("user") != null;
    }

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && user.isAdmin();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!isLoggedIn(session)) {
            response.sendRedirect("login");
            return;
        }

        // BLOCK ADMIN FROM ACCESSING PROFILE
        if (isAdmin(session)) {
            session.setAttribute("errorMessage", "Admin accounts don't have a customer profile. Admin is for managing products and orders only.");
            response.sendRedirect("index.jsp");
            return;
        }

        User user = (User) session.getAttribute("user");
        request.setAttribute("profileUser", user);
        request.getRequestDispatcher("profile.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!isLoggedIn(session)) {
            response.sendRedirect("login");
            return;
        }

        if (isAdmin(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        String action = request.getParameter("action");

        if ("update".equals(action)) {
            try {
                int userId = Integer.parseInt(request.getParameter("userId"));
                String fullName = request.getParameter("fullName");
                String username = request.getParameter("username");
                String email = request.getParameter("email");
                String address = request.getParameter("address");
                String phone = request.getParameter("phone");

                // Validation
                if (fullName == null || fullName.trim().isEmpty()) {
                    session.setAttribute("profileError", "Full name is required!");
                    response.sendRedirect("profile");
                    return;
                }

                if (username == null || username.trim().isEmpty()) {
                    session.setAttribute("profileError", "Username is required!");
                    response.sendRedirect("profile");
                    return;
                }

                if (email == null || email.trim().isEmpty()) {
                    session.setAttribute("profileError", "Email is required!");
                    response.sendRedirect("profile");
                    return;
                }

                User user = new User();
                user.setUserId(userId);
                user.setFullName(fullName.trim());
                user.setUsername(username.trim());
                user.setEmail(email.trim());
                user.setAddress(address != null ? address.trim() : "");
                user.setPhone(phone != null ? phone.trim() : "");
                user.setRole("user");

                boolean updated = userDAO.updateUser(user);

                if (updated) {
                    // Update session attributes
                    session.setAttribute("fullName", fullName.trim());
                    session.setAttribute("username", username.trim());

                    // Update the user object in session
                    User updatedUser = userDAO.getUserById(userId);
                    session.setAttribute("user", updatedUser);

                    session.setAttribute("profileSuccess", "Profile updated successfully!");

                    // Create notification for profile update
                    Notification profileNotification = new Notification(
                            userId,
                            "✅ Your profile information has been updated successfully!",
                            "PROFILE_UPDATE",
                            0
                    );
                    notificationDAO.createNotification(profileNotification);

                    System.out.println("✅ Profile updated for user: " + username + " (ID: " + userId + ")");
                } else {
                    session.setAttribute("profileError", "Failed to update profile. Please try again.");
                }

            } catch (NumberFormatException e) {
                session.setAttribute("profileError", "Invalid user ID!");
            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("profileError", "Error updating profile: " + e.getMessage());
            }
            response.sendRedirect("profile");
        }
    }
}