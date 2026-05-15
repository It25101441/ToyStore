<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.toystore.model.Message, com.toystore.model.User, com.toystore.dao.NotificationDAO" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    String loggedInUsername = (String) session.getAttribute("username");
    boolean isAdmin = (loggedInUser != null && loggedInUser.isAdmin());
    boolean isLoggedIn = (loggedInUser != null);

    if (loggedInUsername == null) loggedInUsername = "User";

    int unreadCount = 0;
    if (isLoggedIn) {
        NotificationDAO notifDAO = new NotificationDAO();
        unreadCount = notifDAO.getUnreadCount(loggedInUser.getUserId());
    }

    List<Message> inboxMessages = (List<Message>) request.getAttribute("inboxMessages");
    List<Message> sentMessages = (List<Message>) request.getAttribute("sentMessages");
    Integer unreadMessageCount = (Integer) request.getAttribute("unreadCount");
    String activeTab = (String) request.getAttribute("activeTab");
    if (activeTab == null) activeTab = "inbox";
    if (unreadMessageCount == null) unreadMessageCount = 0;

    String successMessage = (String) session.getAttribute("messageSuccess");
    String errorMessage = (String) session.getAttribute("messageError");
    if (successMessage != null) session.removeAttribute("messageSuccess");
    if (errorMessage != null) session.removeAttribute("messageError");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= isAdmin ? "Messages" : "Contact Us" %> - ToyStore</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }

        .navbar {
            background: white;
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            flex-wrap: wrap;
            gap: 1rem;
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .logo {
            font-size: 1.8rem;
            font-weight: bold;
            color: #667eea;
        }

        .logo a {
            text-decoration: none;
            color: #667eea;
        }

        .nav-links {
            display: flex;
            gap: 2rem;
            align-items: center;
            flex-wrap: wrap;
        }

        .nav-links a {
            text-decoration: none;
            color: #333;
            font-weight: 500;
            transition: color 0.3s;
        }

        .nav-links a:hover {
            color: #667eea;
        }

        .nav-icon {
            width: 18px;
            height: 18px;
            vertical-align: middle;
            margin-right: 4px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        .nav-notification-link, .nav-messages-link {
            position: relative;
        }

        .nav-notification-badge, .nav-messages-badge {
            position: absolute;
            top: -8px;
            right: -12px;
            background: #e53e3e;
            color: white;
            border-radius: 50%;
            padding: 2px 6px;
            font-size: 0.7rem;
            min-width: 18px;
            text-align: center;
            font-weight: bold;
        }

        .cart-badge {
            position: absolute;
            top: -8px;
            right: -12px;
            background: #e53e3e;
            color: white;
            border-radius: 50%;
            padding: 2px 6px;
            font-size: 0.7rem;
            min-width: 18px;
            text-align: center;
            font-weight: bold;
        }

        .logout-link {
            color: #e53e3e !important;
            font-weight: 600;
        }

        .logout-link:hover {
            color: #c53030 !important;
        }

        .user-menu {
            position: relative;
            display: inline-block;
        }

        .user-dropdown-btn {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            background: #f7fafc;
            padding: 0.3rem 0.8rem;
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.3s;
            border: none;
            font-size: 1rem;
            font-family: inherit;
        }

        .user-dropdown-btn:hover {
            background: #e2e8f0;
        }

        .welcome-text {
            color: #667eea;
            font-weight: bold;
        }

        .dropdown-arrow {
            font-size: 0.7rem;
            color: #667eea;
            transition: transform 0.3s;
        }

        .user-menu:hover .dropdown-arrow {
            transform: rotate(180deg);
        }

        .dropdown-content {
            display: none;
            position: absolute;
            right: 0;
            top: 100%;
            background-color: white;
            min-width: 220px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.2);
            border-radius: 10px;
            z-index: 1000;
            margin-top: 0.5rem;
            overflow: hidden;
        }

        .user-menu:hover .dropdown-content {
            display: block;
        }

        .dropdown-content a {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.75rem 1rem;
            text-decoration: none;
            color: #333;
            transition: background 0.3s;
            border-bottom: 1px solid #f0f0f0;
        }

        .dropdown-content a:last-child {
            border-bottom: none;
        }

        .dropdown-content a:hover {
            background: #f7fafc;
            color: #667eea;
        }

        .dropdown-badge {
            background: #e53e3e;
            color: white;
            border-radius: 50%;
            padding: 2px 6px;
            font-size: 0.7rem;
            margin-left: auto;
            min-width: 20px;
            text-align: center;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            background: #f7fafc;
            padding: 0.3rem 0.8rem;
            border-radius: 20px;
        }

        .admin-badge {
            background: linear-gradient(135deg, #e53e3e, #c53030);
            color: white;
            padding: 2px 10px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: bold;
        }

        .container {
            max-width: 1000px;
            margin: 2rem auto;
            padding: 0 2rem;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            flex-wrap: wrap;
            gap: 1rem;
        }

        h1 {
            color: #333;
        }

        .compose-btn {
            background: #48bb78;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: background 0.3s;
        }

        .compose-btn:hover {
            background: #38a169;
        }

        .success-message {
            background: #c6f6d5;
            color: #22543d;
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 1rem;
            text-align: center;
            border-left: 4px solid #38a169;
            animation: slideIn 0.5s ease;
        }

        .error-message {
            background: #fed7d7;
            color: #742a2a;
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 1rem;
            text-align: center;
            border-left: 4px solid #e53e3e;
            animation: slideIn 0.5s ease;
        }

        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .tabs {
            display: flex;
            gap: 0.5rem;
            margin-bottom: 1.5rem;
            border-bottom: 2px solid #e2e8f0;
        }

        .tab-btn {
            padding: 10px 20px;
            background: none;
            border: none;
            font-size: 1rem;
            cursor: pointer;
            color: #666;
            transition: all 0.3s;
            position: relative;
        }

        .tab-btn.active {
            color: #667eea;
            font-weight: bold;
        }

        .tab-btn.active::after {
            content: '';
            position: absolute;
            bottom: -2px;
            left: 0;
            right: 0;
            height: 2px;
            background: #667eea;
        }

        .tab-btn:hover {
            color: #667eea;
        }

        .badge {
            background: #e53e3e;
            color: white;
            border-radius: 50%;
            padding: 2px 6px;
            font-size: 0.7rem;
            margin-left: 5px;
        }

        .messages-list {
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .message-item {
            padding: 1rem 1.5rem;
            border-bottom: 1px solid #eee;
            transition: background 0.3s;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 0.5rem;
        }

        .message-item:hover {
            background: #f7fafc;
        }

        .message-item.unread {
            background: #ebf8ff;
            border-left: 4px solid #667eea;
        }

        .message-info {
            flex: 1;
        }

        .message-subject {
            font-weight: bold;
            color: #333;
            margin-bottom: 0.25rem;
        }

        .message-meta {
            font-size: 0.8rem;
            color: #999;
        }

        .message-preview {
            font-size: 0.85rem;
            color: #666;
            margin-top: 0.25rem;
        }

        .message-actions {
            display: flex;
            gap: 0.5rem;
        }

        .reply-btn, .delete-btn {
            padding: 5px 12px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 0.8rem;
            text-decoration: none;
            display: inline-block;
        }

        .reply-btn {
            background: #667eea;
            color: white;
        }

        .reply-btn:hover {
            background: #5a67d8;
        }

        .delete-btn {
            background: #e53e3e;
            color: white;
        }

        .delete-btn:hover {
            background: #c53030;
        }

        .no-messages {
            text-align: center;
            padding: 3rem;
            color: #666;
        }

        .no-messages p {
            margin-bottom: 1rem;
        }

        .no-messages a {
            color: #667eea;
            text-decoration: none;
        }

        @media (max-width: 768px) {
            .navbar {
                flex-direction: column;
            }
            .message-item {
                flex-direction: column;
                align-items: flex-start;
            }
            .message-actions {
                align-self: flex-end;
            }
            .tabs {
                justify-content: center;
            }
            .header {
                flex-direction: column;
                text-align: center;
            }
            .dropdown-content {
                right: auto;
                left: 0;
            }
        }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="logo">
            <a href="index.jsp">
                <svg class="nav-icon" style="width:24px;height:24px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <path d="M12 6a6 6 0 0 0-6 6 6 6 0 0 0 6 6 6 6 0 0 0 6-6 6 6 0 0 0-6-6z"/>
                    <circle cx="12" cy="12" r="2"/>
                </svg>
                ToyStore
            </a>
        </div>
        <div class="nav-links">
            <a href="index.jsp">Home</a>
            <a href="products">Products</a>
            <% if (isLoggedIn && isAdmin) { %>
                <a href="orders">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/>
                        <line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                    All Orders
                </a>
                <a href="users">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                        <circle cx="12" cy="7" r="4"/>
                    </svg>
                    All Users
                </a>
                <!-- Admin Dropdown Menu -->
                <div class="user-menu">
                    <button class="user-dropdown-btn">
                        <svg class="nav-icon" style="width:16px;height:16px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                            <circle cx="12" cy="7" r="4"/>
                        </svg>
                        <span class="welcome-text"><%= loggedInUsername %></span>
                        <span class="admin-badge">ADMIN</span>
                        <span class="dropdown-arrow">▼</span>
                    </button>
                    <div class="dropdown-content">
                        <a href="reviews?action=admin">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                            </svg>
                            All Reviews
                        </a>
                        <a href="messages" style="color: #667eea; font-weight: bold;" class="nav-messages-link">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                            </svg>
                            Messages
                            <% if (unreadMessageCount > 0) { %>
                                <span class="dropdown-badge"><%= unreadMessageCount %></span>
                            <% } %>
                        </a>
                        <a href="notifications" class="nav-notification-link">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                                <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                            </svg>
                            Notifications
                            <% if (unreadCount > 0) { %>
                                <span class="dropdown-badge"><%= unreadCount %></span>
                            <% } %>
                        </a>
                        <a href="logout" class="logout-link" style="border-top: 1px solid #f0f0f0; margin-top: 5px; color: #e53e3e !important;">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                                <polyline points="16 17 21 12 16 7"/>
                                <line x1="21" y1="12" x2="9" y2="12"/>
                            </svg>
                            Logout
                        </a>
                    </div>
                </div>
            <% } else if (isLoggedIn && !isAdmin) { %>
                <a href="cart" id="cartLink" style="position: relative;">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="9" cy="21" r="1"/>
                        <circle cx="20" cy="21" r="1"/>
                        <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                    </svg>
                    Cart
                    <span id="cartBadge" class="cart-badge" style="display: none;"></span>
                </a>
                <div class="user-menu">
                    <button class="user-dropdown-btn">
                        <span class="welcome-text">
                            <svg class="nav-icon" style="width:16px;height:16px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                <circle cx="12" cy="7" r="4"/>
                            </svg>
                            <%= loggedInUsername %>
                        </span>
                        <span class="dropdown-arrow">▼</span>
                    </button>
                    <div class="dropdown-content">
                        <a href="profile" id="dropdownProfile">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                <circle cx="12" cy="7" r="4"/>
                            </svg>
                            My Profile
                        </a>
                        <a href="orders" id="dropdownOrders">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                                <line x1="16" y1="2" x2="16" y2="6"/>
                                <line x1="8" y1="2" x2="8" y2="6"/>
                                <line x1="3" y1="10" x2="21" y2="10"/>
                            </svg>
                            My Orders
                        </a>
                        <a href="reviews" id="dropdownReviews">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                            </svg>
                            My Reviews
                        </a>
                        <a href="messages" style="color: #667eea; font-weight: bold;" id="dropdownMessages">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                            </svg>
                            Contact Us
                            <% if (unreadMessageCount > 0) { %>
                                <span class="dropdown-badge" id="dropdownMsgBadge"><%= unreadMessageCount %></span>
                            <% } %>
                        </a>
                        <a href="notifications" id="dropdownNotifications">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                                <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                            </svg>
                            Notifications
                            <% if (unreadCount > 0) { %>
                                <span class="dropdown-badge" id="dropdownNotifBadge"><%= unreadCount %></span>
                            <% } %>
                        </a>
                        <a href="logout" class="logout-link" style="border-top: 1px solid #f0f0f0; margin-top: 5px; color: #e53e3e !important;">
                            <svg class="dropdown-icon" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                                <polyline points="16 17 21 12 16 7"/>
                                <line x1="21" y1="12" x2="9" y2="12"/>
                            </svg>
                            Logout
                        </a>
                    </div>
                </div>
            <% } else { %>
                <a href="login">Login</a>
                <a href="register">Register</a>
            <% } %>
        </div>
    </div>

    <div class="container">
        <div class="header">
            <h1>
                <svg style="width:28px;height:28px;vertical-align:middle;margin-right:10px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                </svg>
                <%= isAdmin ? "Messages" : "Contact Us" %>
            </h1>
            <a href="messages?action=compose" class="compose-btn">
                <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19"/>
                    <line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
                <%= isAdmin ? "New Message" : "Send Inquiry" %>
            </a>
        </div>

        <% if (successMessage != null && !successMessage.isEmpty()) { %>
            <div class="success-message">
                <svg style="width:16px;height:16px;vertical-align:middle;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20 6L9 17l-5-5"/>
                </svg>
                <%= successMessage %>
            </div>
        <% } %>
        <% if (errorMessage != null && !errorMessage.isEmpty()) { %>
            <div class="error-message">
                <svg style="width:16px;height:16px;vertical-align:middle;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= errorMessage %>
            </div>
        <% } %>

        <div class="tabs">
            <button class="tab-btn <%= activeTab.equals("inbox") ? "active" : "" %>" onclick="switchTab('inbox')">
                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/>
                    <path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>
                </svg>
                Inbox
                <% if (unreadMessageCount > 0) { %>
                    <span class="badge" id="inboxBadge"><%= unreadMessageCount %></span>
                <% } %>
            </button>
            <button class="tab-btn <%= activeTab.equals("sent") ? "active" : "" %>" onclick="switchTab('sent')">
                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="22" y1="2" x2="11" y2="13"/>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"/>
                </svg>
                Sent
            </button>
        </div>

        <div id="inboxTab" class="messages-list" style="<%= activeTab.equals("inbox") ? "display: block" : "display: none" %>">
            <% if (inboxMessages != null && !inboxMessages.isEmpty()) { %>
                <% for (Message msg : inboxMessages) {
                    String unreadClass = msg.isRead() ? "" : "unread";
                %>
                    <div class="message-item <%= unreadClass %>" onclick="viewMessage(<%= msg.getMessageId() %>)">
                        <div class="message-info">
                            <div class="message-subject">
                                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                                    <polyline points="22,6 12,13 2,6"/>
                                </svg>
                                <%= msg.getSubject() %>
                                <% if (!msg.isRead()) { %>
                                    <span style="background: #667eea; color: white; padding: 2px 6px; border-radius: 10px; font-size: 0.7rem; margin-left: 8px;">NEW</span>
                                <% } %>
                            </div>
                            <div class="message-meta">
                                From: <%= msg.getSenderName() %> | <%= msg.getCreatedAt() %>
                            </div>
                            <div class="message-preview">
                                <%= msg.getMessage().length() > 80 ? msg.getMessage().substring(0, 77) + "..." : msg.getMessage() %>
                            </div>
                        </div>
                        <div class="message-actions" onclick="event.stopPropagation()">
                            <a href="messages?action=reply&id=<%= msg.getMessageId() %>" class="reply-btn">
                                <svg style="width:12px;height:12px;vertical-align:middle;margin-right:4px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                                </svg>
                                Reply
                            </a>
                            <button onclick="deleteMessage(<%= msg.getMessageId() %>)" class="delete-btn">
                                <svg style="width:12px;height:12px;vertical-align:middle;margin-right:4px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="3 6 5 6 21 6"/>
                                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                </svg>
                                Delete
                            </button>
                        </div>
                    </div>
                <% } %>
            <% } else { %>
                <div class="no-messages">
                    <svg style="width:48px;height:48px;margin-bottom:1rem;color:#999;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                    </svg>
                    <p><%= isAdmin ? "No messages in your inbox." : "No inquiries in your inbox." %></p>
                    <a href="messages?action=compose"><%= isAdmin ? "Send a message →" : "Send an inquiry →" %></a>
                </div>
            <% } %>
        </div>

        <div id="sentTab" class="messages-list" style="<%= activeTab.equals("sent") ? "display: block" : "display: none" %>">
            <% if (sentMessages != null && !sentMessages.isEmpty()) { %>
                <% for (Message msg : sentMessages) { %>
                    <div class="message-item" onclick="viewMessage(<%= msg.getMessageId() %>)">
                        <div class="message-info">
                            <div class="message-subject">
                                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <line x1="22" y1="2" x2="11" y2="13"/>
                                    <polygon points="22 2 15 22 11 13 2 9 22 2"/>
                                </svg>
                                <%= msg.getSubject() %>
                            </div>
                            <div class="message-meta">
                                To: <%= msg.getReceiverName() %> | <%= msg.getCreatedAt() %>
                            </div>
                            <div class="message-preview">
                                <%= msg.getMessage().length() > 80 ? msg.getMessage().substring(0, 77) + "..." : msg.getMessage() %>
                            </div>
                        </div>
                        <div class="message-actions" onclick="event.stopPropagation()">
                            <button onclick="deleteMessage(<%= msg.getMessageId() %>)" class="delete-btn">
                                <svg style="width:12px;height:12px;vertical-align:middle;margin-right:4px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="3 6 5 6 21 6"/>
                                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                </svg>
                                Delete
                            </button>
                        </div>
                    </div>
                <% } %>
            <% } else { %>
                <div class="no-messages">
                    <svg style="width:48px;height:48px;margin-bottom:1rem;color:#999;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="22" y1="2" x2="11" y2="13"/>
                        <polygon points="22 2 15 22 11 13 2 9 22 2"/>
                    </svg>
                    <p><%= isAdmin ? "No sent messages." : "No sent inquiries." %></p>
                    <a href="messages?action=compose"><%= isAdmin ? "Send a message →" : "Send an inquiry →" %></a>
                </div>
            <% } %>
        </div>
    </div>

    <script>
        function switchTab(tab) {
            const inboxTab = document.getElementById('inboxTab');
            const sentTab = document.getElementById('sentTab');
            const inboxBtn = document.querySelector('.tab-btn:first-child');
            const sentBtn = document.querySelector('.tab-btn:last-child');

            if (tab === 'inbox') {
                inboxTab.style.display = 'block';
                sentTab.style.display = 'none';
                inboxBtn.classList.add('active');
                sentBtn.classList.remove('active');
            } else {
                inboxTab.style.display = 'none';
                sentTab.style.display = 'block';
                inboxBtn.classList.remove('active');
                sentBtn.classList.add('active');
            }
        }

        function viewMessage(messageId) {
            window.location.href = 'messages?action=view&id=' + messageId;
        }

        function deleteMessage(messageId) {
            if (confirm('Are you sure you want to delete this message?')) {
                window.location.href = 'messages?action=delete&id=' + messageId;
            }
        }

        function updateCartCount() {
            fetch('cart?ajax=count')
                .then(response => response.json())
                .then(data => {
                    const cartBadge = document.getElementById('cartBadge');
                    if (cartBadge) {
                        if (data.cartItemCount > 0) {
                            cartBadge.textContent = data.cartItemCount;
                            cartBadge.style.display = 'inline-block';
                        } else {
                            cartBadge.style.display = 'none';
                        }
                    }
                })
                .catch(error => console.error('Error fetching cart count:', error));
        }

        function updateMessageCount() {
            fetch('messages?ajax=count')
                .then(response => response.json())
                .then(data => {
                    const navMsgBadge = document.getElementById('navMessagesBadge');
                    if (navMsgBadge) {
                        if (data.unreadMessageCount > 0) {
                            navMsgBadge.textContent = data.unreadMessageCount;
                            navMsgBadge.style.display = 'inline-block';
                        } else {
                            navMsgBadge.style.display = 'none';
                        }
                    }

                    const inboxBadge = document.getElementById('inboxBadge');
                    if (inboxBadge) {
                        if (data.unreadMessageCount > 0) {
                            inboxBadge.textContent = data.unreadMessageCount;
                            inboxBadge.style.display = 'inline-block';
                        } else {
                            inboxBadge.style.display = 'none';
                        }
                    }

                    const dropdownMsgBadge = document.getElementById('dropdownMsgBadge');
                    if (dropdownMsgBadge) {
                        if (data.unreadMessageCount > 0) {
                            dropdownMsgBadge.textContent = data.unreadMessageCount;
                            dropdownMsgBadge.style.display = 'inline-block';
                        } else {
                            dropdownMsgBadge.style.display = 'none';
                        }
                    }
                })
                .catch(error => console.error('Error fetching message count:', error));
        }

        function updateNotificationCount() {
            fetch('notifications?ajax=count')
                .then(response => response.json())
                .then(data => {
                    const navNotifBadge = document.getElementById('navNotifBadge');
                    if (navNotifBadge) {
                        if (data.unreadCount > 0) {
                            navNotifBadge.textContent = data.unreadCount;
                            navNotifBadge.style.display = 'inline-block';
                        } else {
                            navNotifBadge.style.display = 'none';
                        }
                    }

                    const dropdownNotifBadge = document.getElementById('dropdownNotifBadge');
                    if (dropdownNotifBadge) {
                        if (data.unreadCount > 0) {
                            dropdownNotifBadge.textContent = data.unreadCount;
                            dropdownNotifBadge.style.display = 'inline-block';
                        } else {
                            dropdownNotifBadge.style.display = 'none';
                        }
                    }
                })
                .catch(error => console.error('Error fetching notification count:', error));
        }

        setInterval(updateCartCount, 5000);
        setInterval(updateMessageCount, 30000);
        setInterval(updateNotificationCount, 30000);
        updateCartCount();
        updateMessageCount();
        updateNotificationCount();
    </script>
</body>
</html>