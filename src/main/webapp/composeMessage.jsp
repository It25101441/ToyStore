<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.toystore.model.User, com.toystore.model.Message, com.toystore.dao.NotificationDAO" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    String loggedInUsername = (String) session.getAttribute("username");
    boolean isAdmin = (loggedInUser != null && loggedInUser.isAdmin());
    boolean isLoggedIn = (loggedInUser != null);

    if (loggedInUsername == null) loggedInUsername = "User";

    // Get unread notification count
    int unreadCount = 0;
    if (isLoggedIn) {
        NotificationDAO notifDAO = new NotificationDAO();
        unreadCount = notifDAO.getUnreadCount(loggedInUser.getUserId());
    }

    // Get attributes from request (set by servlet)
    Boolean isReply = (Boolean) request.getAttribute("isReply");
    String replyToId = (String) request.getAttribute("replyToId");
    String replySubject = (String) request.getAttribute("replySubject");
    Integer defaultRecipientId = (Integer) request.getAttribute("defaultRecipientId");
    String defaultRecipientName = (String) request.getAttribute("defaultRecipientName");
    Message originalMessage = (Message) request.getAttribute("originalMessage");
    List<User> recipients = (List<User>) request.getAttribute("recipients");

    // Default values
    if (isReply == null) isReply = false;

    // Ensure recipients is never null
    if (recipients == null) {
        recipients = new java.util.ArrayList<>();
    }

    // Format subject for reply
    if (replySubject != null && !replySubject.startsWith("Re: ")) {
        replySubject = "Re: " + replySubject;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= isReply ? "Reply to Message" : "New Message" %> - ToyStore</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 2rem;
        }

        .form-container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            width: 100%;
            max-width: 650px;
        }

        h2 {
            text-align: center;
            color: #667eea;
            margin-bottom: 1.5rem;
        }

        .form-group {
            margin-bottom: 1rem;
        }

        label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 500;
            color: #333;
        }

        input, select, textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 1rem;
            font-family: inherit;
        }

        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: #667eea;
        }

        select:disabled, input[readonly] {
            background: #f5f5f5;
            cursor: not-allowed;
        }

        textarea {
            resize: vertical;
            min-height: 150px;
        }

        .original-message {
            background: #f7fafc;
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1.5rem;
            border-left: 4px solid #667eea;
        }

        .original-message p {
            margin: 5px 0;
            font-size: 0.9rem;
        }

        .original-message .quote-text {
            background: #edf2f7;
            padding: 8px;
            border-radius: 5px;
            margin-top: 8px;
            font-style: italic;
            color: #4a5568;
            max-height: 150px;
            overflow-y: auto;
            white-space: pre-wrap;
            word-wrap: break-word;
        }

        button {
            width: 100%;
            background: #48bb78;
            color: white;
            padding: 12px;
            border: none;
            border-radius: 5px;
            font-size: 1rem;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.3s;
            margin-top: 1rem;
        }

        button:hover {
            background: #38a169;
        }

        .back-link {
            display: block;
            text-align: center;
            margin-top: 1rem;
            color: #667eea;
            text-decoration: none;
        }

        .back-link:hover {
            text-decoration: underline;
        }

        .error-message {
            background: #fed7d7;
            color: #742a2a;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 1rem;
            text-align: center;
            border-left: 4px solid #e53e3e;
        }

        .success-message {
            background: #c6f6d5;
            color: #22543d;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 1rem;
            text-align: center;
            border-left: 4px solid #38a169;
        }

        .recipient-display {
            background: #f7fafc;
            padding: 12px;
            border-radius: 5px;
            border: 1px solid #e2e8f0;
            color: #2d3748;
            font-weight: 500;
            font-size: 1rem;
        }

        .info-message {
            background: #e6fffa;
            padding: 8px 12px;
            border-radius: 5px;
            margin-top: 8px;
            font-size: 0.85rem;
            color: #234e52;
        }

        .svg-icon {
            width: 20px;
            height: 20px;
            vertical-align: middle;
            margin-right: 8px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        .svg-icon-small {
            width: 14px;
            height: 14px;
            vertical-align: middle;
            margin-right: 4px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        @media (max-width: 768px) {
            .form-container {
                padding: 1.5rem;
                margin: 1rem;
            }
        }
    </style>
</head>
<body>
    <div class="form-container">
        <h2>
            <% if (isReply) { %>
                <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                </svg>
                Reply to Message
            <% } else { %>
                <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19"/>
                    <line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
                New Message
            <% } %>
        </h2>

        <%
            String errorMsg = (String) session.getAttribute("messageError");
            String successMsg = (String) session.getAttribute("messageSuccess");
            if (errorMsg != null) {
                session.removeAttribute("messageError");
        %>
            <div class="error-message">
                <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= errorMsg %>
            </div>
        <% } else if (successMsg != null) {
                session.removeAttribute("messageSuccess");
        %>
            <div class="success-message">
                <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20 6L9 17l-5-5"/>
                </svg>
                <%= successMsg %>
            </div>
        <% } %>

        <% if (originalMessage != null) { %>
            <div class="original-message">
                <p>
                    <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                        <circle cx="12" cy="7" r="4"/>
                    </svg>
                    <strong>Original Message from:</strong> <%= originalMessage.getSenderName() %>
                </p>
                <p>
                    <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                        <polyline points="22,6 12,13 2,6"/>
                    </svg>
                    <strong>Subject:</strong> <%= originalMessage.getSubject() %>
                </p>
                <p><strong>Message:</strong></p>
                <div class="quote-text">
                    <%= originalMessage.getMessage().replace("\n", "<br>") %>
                </div>
            </div>
        <% } %>

        <form action="messages" method="post">
            <input type="hidden" name="action" value="send">
            <% if (replyToId != null && !replyToId.isEmpty()) { %>
                <input type="hidden" name="replyToId" value="<%= replyToId %>">
            <% } %>

            <div class="form-group">
                <label>
                    <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="1 6 12 13 23 6 12 3 1 6"/>
                        <line x1="1" y1="18" x2="7" y2="14"/>
                        <line x1="23" y1="18" x2="17" y2="14"/>
                        <line x1="12" y1="13" x2="12" y2="21"/>
                    </svg>
                    To:
                </label>

                <% if (isReply && defaultRecipientId != null) {
                    // REPLY MODE - show recipient as readonly field
                    String displayName = defaultRecipientName;
                    if (displayName == null || displayName.isEmpty()) {
                        displayName = "User " + defaultRecipientId;
                    }
                %>
                    <input type="text" value="<%= displayName %>" readonly>
                    <input type="hidden" name="receiverId" value="<%= defaultRecipientId %>">
                    <div class="info-message">
                        <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="16" x2="12" y2="12"/>
                            <line x1="12" y1="8" x2="12.01" y2="8"/>
                        </svg>
                        Replying to the sender of the original message.
                    </div>

                <% } else if (isAdmin) {
                    // ADMIN MODE - show dropdown to select recipient
                %>
                    <select name="receiverId" required>
                        <option value="">Select Recipient</option>
                        <% for (User user : recipients) {
                            if (user.getUserId() != loggedInUser.getUserId()) {
                                String displayName = "";
                                if (user.getFullName() != null && !user.getFullName().isEmpty()) {
                                    displayName = user.getFullName() + " (" + user.getUsername() + ")";
                                } else {
                                    displayName = user.getUsername();
                                }
                        %>
                            <option value="<%= user.getUserId() %>">
                                <%= displayName %>
                            </option>
                        <%      }
                        } %>
                    </select>

                <% } else {
                    // USER MODE (non-admin) - show "Admin" as readonly field, NO DROPDOWN
                    String adminDisplayName = "Admin Support Team";
                    Integer adminId = null;
                    if (recipients != null && !recipients.isEmpty()) {
                        adminId = recipients.get(0).getUserId();
                        User firstAdmin = recipients.get(0);
                        if (firstAdmin.getFullName() != null && !firstAdmin.getFullName().isEmpty()) {
                            adminDisplayName = firstAdmin.getFullName() + " (" + firstAdmin.getUsername() + ")";
                        } else {
                            adminDisplayName = firstAdmin.getUsername();
                        }
                    }
                %>
                    <input type="text" value="<%= adminDisplayName %>" readonly>
                    <% if (adminId != null) { %>
                        <input type="hidden" name="receiverId" value="<%= adminId %>">
                    <% } %>
                    <div class="info-message">
                        <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="16" x2="12" y2="12"/>
                            <line x1="12" y1="8" x2="12.01" y2="8"/>
                        </svg>
                        Your message will be sent to our admin team. We'll respond as soon as possible.
                    </div>

                <% } %>
            </div>

            <div class="form-group">
                <label>
                    <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                        <polyline points="22,6 12,13 2,6"/>
                    </svg>
                    Subject:
                </label>
                <input type="text" name="subject" value="<%= replySubject != null ? replySubject : "" %>" required>
            </div>

            <div class="form-group">
                <label>
                    <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                    </svg>
                    Message:
                </label>
                <textarea name="message" required placeholder="<%= isReply ? "Type your reply here..." : "Type your message here..." %>" rows="6"></textarea>
            </div>

            <button type="submit">
                <% if (isReply) { %>
                    <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                    </svg>
                    Send Reply
                <% } else { %>
                    <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="22" y1="2" x2="11" y2="13"/>
                        <polygon points="22 2 15 22 11 13 2 9 22 2"/>
                    </svg>
                    Send Message
                <% } %>
            </button>
        </form>
        <a href="messages" class="back-link">
            <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="19" y1="12" x2="5" y2="12"/>
                <polyline points="12 19 5 12 12 5"/>
            </svg>
            Back to Messages
        </a>
    </div>
</body>
</html>