<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.toystore.model.User, com.toystore.dao.NotificationDAO" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    String loggedInUsername = (String) session.getAttribute("username");
    boolean isAdmin = (loggedInUser != null && loggedInUser.isAdmin());
    boolean isLoggedIn = (loggedInUser != null);

    if (loggedInUsername == null || loggedInUsername.isEmpty()) {
        loggedInUsername = "User";
    }

    if (isAdmin) {
        response.sendRedirect("index.jsp");
        return;
    }

    int unreadCount = 0;
    int unreadMessageCount = 0;
    if (isLoggedIn) {
        NotificationDAO notifDAO = new NotificationDAO();
        unreadCount = notifDAO.getUnreadCount(loggedInUser.getUserId());
        com.toystore.dao.MessageDAO messageDAO = new com.toystore.dao.MessageDAO();
        unreadMessageCount = messageDAO.getUnreadCount(loggedInUser.getUserId());
    }

    String successMessage = (String) session.getAttribute("profileSuccess");
    String errorMessage = (String) session.getAttribute("profileError");
    if (successMessage != null) session.removeAttribute("profileSuccess");
    if (errorMessage != null) session.removeAttribute("profileError");

    User profileUser = (User) request.getAttribute("profileUser");
    if (profileUser == null) profileUser = loggedInUser;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Profile - ToyStore</title>
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

        .container {
            max-width: 800px;
            margin: 2rem auto;
            padding: 0 2rem;
        }

        .profile-card {
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            overflow: hidden;
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

        .profile-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem;
            text-align: center;
        }

        .profile-avatar {
            font-size: 4rem;
            background: rgba(255,255,255,0.2);
            width: 100px;
            height: 100px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1rem;
        }

        .profile-header h2 {
            font-size: 1.5rem;
        }

        .profile-header p {
            opacity: 0.9;
            margin-top: 0.25rem;
        }

        .profile-form {
            padding: 2rem;
        }

        .form-group {
            margin-bottom: 1.5rem;
        }

        label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: #333;
        }

        input, textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            font-size: 1rem;
            transition: all 0.3s;
            font-family: inherit;
        }

        input:focus, textarea:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102,126,234,0.1);
        }

        textarea {
            resize: vertical;
            min-height: 80px;
        }

        input[readonly] {
            background: #f7fafc;
            cursor: not-allowed;
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
        }

        .success-message {
            background: #c6f6d5;
            color: #22543d;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 1.5rem;
            text-align: center;
            border-left: 4px solid #38a169;
            animation: slideIn 0.5s ease;
        }

        .error-message {
            background: #fed7d7;
            color: #742a2a;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 1.5rem;
            text-align: center;
            border-left: 4px solid #e53e3e;
            animation: slideIn 0.5s ease;
        }

        .info-box {
            background: #e6fffa;
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1.5rem;
            border-left: 4px solid #38b2ac;
            font-size: 0.9rem;
            color: #234e52;
        }

        .info-box strong {
            display: block;
            margin-bottom: 5px;
        }

        .update-btn {
            width: 100%;
            background: #48bb78;
            color: white;
            padding: 12px;
            border: none;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
        }

        .update-btn:hover {
            background: #38a169;
            transform: translateY(-2px);
        }

        .update-btn:active {
            transform: translateY(0);
        }

        .checkout-note {
            background: #fef5e7;
            padding: 1rem;
            border-radius: 8px;
            margin-top: 1.5rem;
            text-align: center;
            font-size: 0.9rem;
            color: #975a16;
        }

        .checkout-note a {
            color: #667eea;
            text-decoration: none;
            font-weight: bold;
        }

        .checkout-note a:hover {
            text-decoration: underline;
        }

        @media (max-width: 768px) {
            .navbar {
                flex-direction: column;
            }
            .form-row {
                grid-template-columns: 1fr;
            }
            .profile-form {
                padding: 1.5rem;
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
            <% if (isLoggedIn && !isAdmin) { %>
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
                        <a href="profile" style="color: #667eea; font-weight: bold;" id="dropdownProfile">
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
                        <a href="messages" id="dropdownMessages">
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
        <div class="profile-card">
            <div class="profile-header">
                <div class="profile-avatar">
                    <svg width="60" height="60" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                        <circle cx="12" cy="7" r="4"/>
                    </svg>
                </div>
                <h2><%= profileUser.getFullName() != null && !profileUser.getFullName().isEmpty() ? profileUser.getFullName() : profileUser.getUsername() %></h2>
                <p>Member since <%= new java.text.SimpleDateFormat("MMMM yyyy").format(new java.util.Date()) %></p>
            </div>

            <div class="profile-form">
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

                <div class="info-box">
                    <strong>
                        <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="8" x2="12" y2="12"/>
                            <line x1="12" y1="16" x2="12.01" y2="16"/>
                        </svg>
                        About Your Profile
                    </strong>
                    Your address and contact number will be automatically filled in the checkout page. You can also edit them during checkout.
                </div>

                <form action="profile" method="post">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="userId" value="<%= profileUser.getUserId() %>">

                    <div class="form-group">
                        <label>Full Name *</label>
                        <input type="text" name="fullName" value="<%= profileUser.getFullName() != null ? profileUser.getFullName() : "" %>" required>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label>Username *</label>
                            <input type="text" name="username" value="<%= profileUser.getUsername() %>" required>
                        </div>
                        <div class="form-group">
                            <label>Email *</label>
                            <input type="email" name="email" value="<%= profileUser.getEmail() %>" required>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>
                            <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="5" y="2" width="14" height="20" rx="2" ry="2"/>
                                <line x1="12" y1="18" x2="12" y2="18"/>
                            </svg>
                            Contact Number
                        </label>
                        <input type="tel" name="phone" value="<%= profileUser.getPhone() != null ? profileUser.getPhone() : "" %>" placeholder="e.g., 0712345678 or 011-2345678">
                        <small style="color: #666; font-size: 0.75rem;">This number will be used for order confirmations and delivery updates</small>
                    </div>

                    <div class="form-group">
                        <label>
                            <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                                <circle cx="12" cy="10" r="3"/>
                            </svg>
                            Shipping Address
                        </label>
                        <textarea name="address" placeholder="Enter your full shipping address (Street, City, Postal Code)"><%= profileUser.getAddress() != null ? profileUser.getAddress() : "" %></textarea>
                        <small style="color: #666; font-size: 0.75rem;">This address will be auto-filled during checkout</small>
                    </div>

                    <button type="submit" class="update-btn">
                        <svg style="width:16px;height:16px;vertical-align:middle;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 14.66V20a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h5.34"/>
                            <polygon points="18 2 22 6 12 16 8 16 8 12 18 2"/>
                        </svg>
                        Update Profile
                    </button>
                </form>

                <div class="checkout-note">
                    <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="16" x2="12" y2="12"/>
                        <line x1="12" y1="8" x2="12.01" y2="8"/>
                    </svg>
                    <strong>Tip:</strong> Your saved address and contact number will be automatically filled when you proceed to <a href="cart">checkout</a>. You can also edit them during checkout.
                </div>
            </div>
        </div>
    </div>

    <script>
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

        function updateNotificationCount() {
            fetch('notifications?ajax=count')
                .then(response => response.json())
                .then(data => {
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

        function updateMessageCount() {
            fetch('messages?ajax=count')
                .then(response => response.json())
                .then(data => {
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

        setInterval(updateCartCount, 5000);
        setInterval(updateNotificationCount, 30000);
        setInterval(updateMessageCount, 30000);
        updateCartCount();
        updateNotificationCount();
        updateMessageCount();
    </script>
</body>
</html>