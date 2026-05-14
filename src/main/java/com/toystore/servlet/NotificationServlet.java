package com.toystore.servlet;

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
import java.io.PrintWriter;
import java.util.List;

@WebServlet("/notifications")
public class NotificationServlet extends HttpServlet {

    private NotificationDAO notificationDAO = new NotificationDAO();

    private boolean isLoggedIn(HttpSession session) {
        return session != null && session.getAttribute("user") != null;
    }

    private int getUserId(HttpSession session) {
        User user = (User) session.getAttribute("user");
        return user != null ? user.getUserId() : -1;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!isLoggedIn(session)) {
            response.sendRedirect("login");
            return;
        }

        int userId = getUserId(session);
        String action = request.getParameter("action");

        // Check if this is an AJAX request for unread count
        String ajax = request.getParameter("ajax");
        if ("count".equals(ajax)) {
            response.setContentType("application/json");
            PrintWriter out = response.getWriter();
            int count = notificationDAO.getUnreadCount(userId);
            out.print("{\"unreadCount\": " + count + "}");
            out.flush();
            return;
        }

        if ("markRead".equals(action)) {
            int notificationId = Integer.parseInt(request.getParameter("id"));
            notificationDAO.markAsRead(notificationId);
            response.sendRedirect("notifications");

        } else if ("markAllRead".equals(action)) {
            notificationDAO.markAllAsRead(userId);
            response.sendRedirect("notifications");

        } else if ("delete".equals(action)) {
            int notificationId = Integer.parseInt(request.getParameter("id"));
            notificationDAO.deleteNotification(notificationId);
            response.sendRedirect("notifications");

        } else {
            // Show all notifications
            List<Notification> notifications = notificationDAO.getNotificationsByUserId(userId);
            int unreadCount = notificationDAO.getUnreadCount(userId);

            request.setAttribute("notifications", notifications);
            request.setAttribute("unreadCount", unreadCount);
            request.getRequestDispatcher("notifications.jsp").forward(request, response);
        }
    }
}