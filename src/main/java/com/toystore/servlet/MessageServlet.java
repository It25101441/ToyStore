package com.toystore.servlet;

import com.toystore.dao.MessageDAO;
import com.toystore.dao.UserDAO;
import com.toystore.model.Message;
import com.toystore.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/messages")
public class MessageServlet extends HttpServlet {

    private MessageDAO messageDAO = new MessageDAO();
    private UserDAO userDAO = new UserDAO();

    private boolean isLoggedIn(HttpSession session) {
        return session != null && session.getAttribute("user") != null;
    }

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && user.isAdmin();
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
            int count = messageDAO.getUnreadCount(userId);
            out.print("{\"unreadMessageCount\": " + count + "}");
            out.flush();
            return;
        }

        if ("view".equals(action)) {
            String idParam = request.getParameter("id");
            if (idParam == null || idParam.trim().isEmpty()) {
                response.sendRedirect("messages");
                return;
            }

            int messageId = Integer.parseInt(idParam);
            Message message = messageDAO.getMessageById(messageId);

            if (message != null) {
                if (message.getReceiverId() == userId && !message.isRead()) {
                    messageDAO.markAsRead(messageId);
                }

                List<Message> conversation = messageDAO.getConversation(messageId);
                request.setAttribute("message", message);
                request.setAttribute("conversation", conversation);
                request.setAttribute("isAdmin", isAdmin(session));
                request.setAttribute("currentUserId", userId);
                request.getRequestDispatcher("messageDetail.jsp").forward(request, response);
            } else {
                response.sendRedirect("messages");
            }

        } else if ("reply".equals(action)) {
            String idParam = request.getParameter("id");
            if (idParam == null || idParam.trim().isEmpty()) {
                response.sendRedirect("messages");
                return;
            }

            int messageId = Integer.parseInt(idParam);
            Message originalMessage = messageDAO.getMessageById(messageId);

            if (originalMessage != null) {
                // Get the original sender's ID and name
                int recipientId = originalMessage.getSenderId();
                String recipientName = originalMessage.getSenderName();
                String replySubject = originalMessage.getSubject();

                // Format subject
                if (replySubject != null && !replySubject.startsWith("Re: ")) {
                    replySubject = "Re: " + replySubject;
                }

                // Get the recipient user details for better display
                User recipientUser = userDAO.getUserById(recipientId);
                String displayName = recipientName;

                if (recipientUser != null) {
                    if (recipientUser.getFullName() != null && !recipientUser.getFullName().isEmpty()) {
                        displayName = recipientUser.getFullName() + " (" + recipientUser.getUsername() + ")";
                    } else {
                        displayName = recipientUser.getUsername();
                    }
                }

                // Create recipients list with the original sender for reply
                List<User> recipients = new ArrayList<>();
                if (recipientUser != null) {
                    recipients.add(recipientUser);
                } else {
                    // Create a placeholder user
                    User placeholder = new User();
                    placeholder.setUserId(recipientId);
                    placeholder.setUsername(recipientName != null ? recipientName : "User " + recipientId);
                    placeholder.setFullName(recipientName != null ? recipientName : "User " + recipientId);
                    recipients.add(placeholder);
                }

                // Set attributes directly on request and forward
                request.setAttribute("isReply", true);
                request.setAttribute("replyToId", String.valueOf(messageId));
                request.setAttribute("replySubject", replySubject);
                request.setAttribute("defaultRecipientId", recipientId);
                request.setAttribute("defaultRecipientName", displayName);
                request.setAttribute("originalMessage", originalMessage);
                request.setAttribute("isAdmin", isAdmin(session));
                request.setAttribute("recipients", recipients);

                System.out.println("=== REPLY DEBUG ===");
                System.out.println("recipientId: " + recipientId);
                System.out.println("displayName: " + displayName);
                System.out.println("replySubject: " + replySubject);
                System.out.println("recipients size: " + recipients.size());

                // Forward directly to composeMessage.jsp
                request.getRequestDispatcher("composeMessage.jsp").forward(request, response);

            } else {
                session.setAttribute("messageError", "Message not found!");
                response.sendRedirect("messages");
            }

        } else if ("delete".equals(action)) {
            String idParam = request.getParameter("id");
            if (idParam == null || idParam.trim().isEmpty()) {
                response.sendRedirect("messages");
                return;
            }

            int messageId = Integer.parseInt(idParam);
            boolean deleted = messageDAO.deleteMessage(messageId);

            if (deleted) {
                session.setAttribute("messageSuccess", "Message deleted successfully!");
            } else {
                session.setAttribute("messageError", "Failed to delete message!");
            }
            response.sendRedirect("messages");

        } else if ("compose".equals(action)) {
            // New message (not a reply)
            boolean isUserAdmin = isAdmin(session);
            int currentUserId = getUserId(session);

            if (isUserAdmin) {
                // Admin can send to all other users - show dropdown
                List<User> recipients = new ArrayList<>();
                List<User> allUsers = userDAO.getAllUsers();
                for (User u : allUsers) {
                    if (u.getUserId() != currentUserId) {
                        recipients.add(u);
                    }
                }
                request.setAttribute("recipients", recipients);
                request.setAttribute("isAdmin", true);
                request.setAttribute("isReply", false);
            } else {
                // Regular user - only send to admins, NO DROPDOWN
                List<User> admins = messageDAO.getAllAdmins();
                request.setAttribute("recipients", admins);
                request.setAttribute("isAdmin", false);
                request.setAttribute("isReply", false);
            }

            request.getRequestDispatcher("composeMessage.jsp").forward(request, response);

        } else {
            String tab = request.getParameter("tab");
            if (tab == null) tab = "inbox";

            List<Message> inboxMessages = messageDAO.getInboxMessages(userId);
            List<Message> sentMessages = messageDAO.getSentMessages(userId);
            int unreadCount = messageDAO.getUnreadCount(userId);

            request.setAttribute("inboxMessages", inboxMessages);
            request.setAttribute("sentMessages", sentMessages);
            request.setAttribute("unreadCount", unreadCount);
            request.setAttribute("activeTab", tab);
            request.setAttribute("isAdmin", isAdmin(session));
            request.getRequestDispatcher("messages.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!isLoggedIn(session)) {
            response.sendRedirect("login");
            return;
        }

        int userId = getUserId(session);
        String action = request.getParameter("action");

        if ("send".equals(action)) {
            String receiverIdParam = request.getParameter("receiverId");
            String subject = request.getParameter("subject");
            String messageText = request.getParameter("message");
            String replyToIdParam = request.getParameter("replyToId");

            if (receiverIdParam == null || receiverIdParam.trim().isEmpty()) {
                session.setAttribute("messageError", "Please select a recipient!");
                response.sendRedirect("messages");
                return;
            }

            if (subject == null || subject.trim().isEmpty()) {
                session.setAttribute("messageError", "Subject is required!");
                response.sendRedirect("messages");
                return;
            }

            if (messageText == null || messageText.trim().isEmpty()) {
                session.setAttribute("messageError", "Message cannot be empty!");
                response.sendRedirect("messages");
                return;
            }

            int receiverId = Integer.parseInt(receiverIdParam);

            if (receiverId == userId) {
                session.setAttribute("messageError", "You cannot send a message to yourself!");
                response.sendRedirect("messages");
                return;
            }

            Message message = new Message();
            message.setSenderId(userId);
            message.setReceiverId(receiverId);
            message.setSubject(subject.trim());
            message.setMessage(messageText.trim());

            if (replyToIdParam != null && !replyToIdParam.isEmpty()) {
                message.setReplyToId(Integer.parseInt(replyToIdParam));
            }

            boolean sent = messageDAO.sendMessage(message);

            if (sent) {
                session.setAttribute("messageSuccess", "Message sent successfully!");
                response.sendRedirect("messages");
            } else {
                session.setAttribute("messageError", "Failed to send message. Please try again.");
                response.sendRedirect("messages");
            }
        }
    }
}
