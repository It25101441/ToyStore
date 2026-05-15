<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.toystore.model.Review, com.toystore.model.User, com.toystore.dao.NotificationDAO" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    String loggedInUsername = (String) session.getAttribute("username");
    boolean isAdmin = (loggedInUser != null && loggedInUser.isAdmin());
    boolean isLoggedIn = (loggedInUser != null);

    if (loggedInUsername == null) loggedInUsername = "User";

    int unreadCount = 0;
    int unreadMessageCount = 0;
    if (isLoggedIn) {
        NotificationDAO notifDAO = new NotificationDAO();
        unreadCount = notifDAO.getUnreadCount(loggedInUser.getUserId());
        com.toystore.dao.MessageDAO messageDAO = new com.toystore.dao.MessageDAO();
        unreadMessageCount = messageDAO.getUnreadCount(loggedInUser.getUserId());
    }

    List<Review> reviews = (List<Review>) request.getAttribute("reviews");
    Integer reviewCount = (Integer) request.getAttribute("reviewCount");
    if (reviewCount == null) reviewCount = 0;

    // Debug output
    System.out.println("=== myReviews.jsp loaded ===");
    System.out.println("Logged in user ID: " + (loggedInUser != null ? loggedInUser.getUserId() : "null"));
    System.out.println("Review count from attribute: " + reviewCount);
    if (reviews != null) {
        System.out.println("Reviews list size: " + reviews.size());
        for (int i = 0; i < reviews.size(); i++) {
            Review r = reviews.get(i);
            System.out.println("  Review " + i + ": ID=" + r.getReviewId() +
                               ", Product=" + r.getProductName() +
                               ", Rating=" + r.getRating());
        }
    } else {
        System.out.println("Reviews list is NULL - creating empty list");
        reviews = new java.util.ArrayList<>();
        reviewCount = 0;
    }

    String successMessage = (String) session.getAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");
    if (successMessage != null) session.removeAttribute("successMessage");
    if (errorMessage != null) session.removeAttribute("errorMessage");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Reviews - ToyStore</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }
        .navbar {
            background: white; padding: 1rem 2rem; display: flex;
            justify-content: space-between; align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); flex-wrap: wrap; gap: 1rem;
            position: sticky; top: 0; z-index: 100;
        }
        .logo { font-size: 1.8rem; font-weight: bold; color: #667eea; }
        .logo a { text-decoration: none; color: #667eea; }
        .nav-links { display: flex; gap: 2rem; align-items: center; flex-wrap: wrap; }
        .nav-links a { text-decoration: none; color: #333; font-weight: 500; transition: color 0.3s; }
        .nav-links a:hover { color: #667eea; }
        .nav-icon { width: 18px; height: 18px; vertical-align: middle; margin-right: 4px; stroke: currentColor; fill: none; stroke-width: 2; }
        .nav-notification-link, .nav-messages-link { position: relative; }
        .nav-notification-badge, .nav-messages-badge {
            position: absolute; top: -8px; right: -12px; background: #e53e3e;
            color: white; border-radius: 50%; padding: 2px 6px;
            font-size: 0.7rem; min-width: 18px; text-align: center; font-weight: bold;
        }
        .cart-badge {
            position: absolute; top: -8px; right: -12px; background: #e53e3e;
            color: white; border-radius: 50%; padding: 2px 6px;
            font-size: 0.7rem; min-width: 18px; text-align: center; font-weight: bold;
        }
        .logout-link { color: #e53e3e !important; font-weight: 600; }
        .logout-link:hover { color: #c53030 !important; }
        .user-menu { position: relative; display: inline-block; }
        .user-dropdown-btn {
            display: flex; align-items: center; gap: 0.5rem; background: #f7fafc;
            padding: 0.3rem 0.8rem; border-radius: 20px; cursor: pointer;
            transition: all 0.3s; border: none; font-size: 1rem; font-family: inherit;
        }
        .user-dropdown-btn:hover { background: #e2e8f0; }
        .welcome-text { color: #667eea; font-weight: bold; }
        .dropdown-arrow { font-size: 0.7rem; color: #667eea; transition: transform 0.3s; }
        .user-menu:hover .dropdown-arrow { transform: rotate(180deg); }
        .dropdown-content {
            display: none; position: absolute; right: 0; top: 100%;
            background-color: white; min-width: 220px; box-shadow: 0 8px 16px rgba(0,0,0,0.2);
            border-radius: 10px; z-index: 1000; margin-top: 0.5rem; overflow: hidden;
        }
        .user-menu:hover .dropdown-content { display: block; }
        .dropdown-content a {
            display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem 1rem;
            text-decoration: none; color: #333; transition: background 0.3s;
            border-bottom: 1px solid #f0f0f0;
        }
        .dropdown-content a:last-child { border-bottom: none; }
        .dropdown-content a:hover { background: #f7fafc; color: #667eea; }
        .dropdown-badge {
            background: #e53e3e; color: white; border-radius: 50%; padding: 2px 6px;
            font-size: 0.7rem; margin-left: auto; min-width: 20px; text-align: center;
        }
        .user-info {
            display: flex; align-items: center; gap: 0.5rem; background: #f7fafc;
            padding: 0.3rem 0.8rem; border-radius: 20px;
        }
        .admin-badge {
            background: linear-gradient(135deg, #e53e3e, #c53030); color: white;
            padding: 2px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: bold;
        }
        .container { max-width: 1200px; margin: 2rem auto; padding: 0 2rem; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 1rem; }
        h1 { color: #333; }
        .stats-card {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white; padding: 0.5rem 1rem; border-radius: 10px;
        }
        .success-message {
            background: #c6f6d5; color: #22543d; padding: 12px;
            border-radius: 5px; margin-bottom: 1rem; text-align: center;
            border-left: 4px solid #38a169; animation: slideIn 0.5s ease;
        }
        .error-message {
            background: #fed7d7; color: #742a2a; padding: 12px;
            border-radius: 5px; margin-bottom: 1rem; text-align: center;
            border-left: 4px solid #e53e3e; animation: slideIn 0.5s ease;
        }
        @keyframes slideIn {
            from { opacity: 0; transform: translateY(-20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .reviews-grid {
            display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 1.5rem;
        }
        .review-card {
            background: white; border-radius: 10px; padding: 1.5rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); transition: transform 0.3s;
        }
        .review-card:hover { transform: translateY(-3px); box-shadow: 0 4px 15px rgba(0,0,0,0.15); }
        .product-info {
            display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem;
            padding-bottom: 0.75rem; border-bottom: 1px solid #eee;
        }
        .product-image {
            width: 60px; height: 60px; border-radius: 8px; overflow: hidden;
            background: linear-gradient(135deg, #667eea, #764ba2);
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }
        .product-image img { width: 100%; height: 100%; object-fit: cover; }
        .product-image .no-image { font-size: 1.5rem; color: white; }
        .product-name { font-weight: bold; color: #333; font-size: 1rem; }
        .stars { margin-bottom: 0.75rem; display: flex; gap: 0.25rem; }
        .star-filled { color: #fbbf24; font-size: 1.1rem; }
        .star-empty { color: #ddd; font-size: 1.1rem; }
        .review-comment { color: #666; line-height: 1.5; margin-bottom: 0.75rem; white-space: pre-wrap; word-wrap: break-word; }
        .review-date { font-size: 0.75rem; color: #999; display: flex; align-items: center; gap: 0.25rem; }
        .no-reviews {
            text-align: center; padding: 3rem; background: white;
            border-radius: 10px; grid-column: 1 / -1;
        }
        .no-reviews p { color: #666; margin-bottom: 1rem; }
        .browse-products {
            display: inline-block; padding: 10px 20px; background: #667eea;
            color: white; text-decoration: none; border-radius: 5px;
            transition: background 0.3s;
        }
        .browse-products:hover { background: #5a67d8; }
        .svg-icon { width: 18px; height: 18px; vertical-align: middle; margin-right: 5px; stroke: currentColor; fill: none; stroke-width: 2; }
        .svg-icon-small { width: 14px; height: 14px; vertical-align: middle; margin-right: 3px; stroke: currentColor; fill: none; stroke-width: 2; }
        @media (max-width: 768px) {
            .navbar { flex-direction: column; }
            .reviews-grid { grid-template-columns: 1fr; }
            .dropdown-content { right: auto; left: 0; }
            .product-info { flex-direction: column; text-align: center; }
            .stars { justify-content: center; }
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
                        <a href="reviews" style="color: #667eea; font-weight: bold;" id="dropdownReviews">
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
            <% } else if (!isLoggedIn) { %>
                <a href="login">Login</a>
                <a href="register">Register</a>
            <% } %>
        </div>
    </div>

    <div class="container">
        <div class="header">
            <h1>
                <svg class="svg-icon" style="width:28px;height:28px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                </svg>
                My Reviews
            </h1>
            <div class="stats-card">
                Total Reviews: <%= reviewCount %>
            </div>
        </div>

        <% if (successMessage != null && !successMessage.isEmpty()) { %>
            <div class="success-message">
                <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20 6L9 17l-5-5"/>
                </svg>
                <%= successMessage %>
            </div>
        <% } %>
        <% if (errorMessage != null && !errorMessage.isEmpty()) { %>
            <div class="error-message">
                <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= errorMessage %>
            </div>
        <% } %>

        <div class="reviews-grid">
            <% if (reviews != null && !reviews.isEmpty()) {
                for (Review review : reviews) {
                    String productImageUrl = review.getProductImageUrl();
                    String imagePath = "images/default-toy.png";
                    if (productImageUrl != null && !productImageUrl.trim().isEmpty()) {
                        imagePath = "images/" + productImageUrl;
                    }
            %>
                <div class="review-card">
                    <div class="product-info">
                        <div class="product-image">
                            <img src="<%= imagePath %>"
                                 alt="<%= review.getProductName() != null ? review.getProductName() : "Product" %>"
                                 onerror="this.onerror=null; this.src='images/default-toy.png'">
                        </div>
                        <div class="product-name">
                            <%= review.getProductName() != null ? review.getProductName() : "Product" %>
                        </div>
                    </div>
                    <div class="stars">
                        <% for (int i = 1; i <= 5; i++) { %>
                            <% if (i <= review.getRating()) { %>
                                <span class="star-filled">★</span>
                            <% } else { %>
                                <span class="star-empty">☆</span>
                            <% } %>
                        <% } %>
                    </div>
                    <div class="review-comment">
                        <%= review.getComment() != null ? review.getComment().replace("\n", "<br>") : "" %>
                    </div>
                    <div class="review-date">
                        <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <polyline points="12 6 12 12 16 14"/>
                        </svg>
                        <%= review.getCreatedAt() != null ? review.getCreatedAt() : "" %>
                    </div>
                </div>
            <% }
            } else { %>
                <div class="no-reviews">
                    <svg style="width:48px;height:48px;margin-bottom:1rem;color:#999;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                    </svg>
                    <p>You haven't written any reviews yet.</p>
                    <p>After your orders are delivered, you can write reviews for the products you purchased.</p>
                    <a href="orders" class="browse-products">View My Orders →</a>
                </div>
            <% } %>
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