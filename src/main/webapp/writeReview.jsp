<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.toystore.model.Product, com.toystore.model.User, com.toystore.dao.NotificationDAO" %>
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

    Integer orderId = (Integer) request.getAttribute("orderId");
    Integer productId = (Integer) request.getAttribute("productId");
    Product product = (Product) request.getAttribute("product");

    if (orderId == null || productId == null || product == null) {
        response.sendRedirect("orders");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Write a Review - ToyStore</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 2rem;
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
            border-radius: 10px;
            margin-bottom: 2rem;
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
        .form-container {
            background: white; padding: 2rem; border-radius: 10px;
            max-width: 700px; margin: 0 auto; box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        h2 { color: #667eea; margin-bottom: 1.5rem; text-align: center; }
        .product-info {
            background: #f7fafc; padding: 1rem; border-radius: 10px;
            display: flex; align-items: center; gap: 1rem; margin-bottom: 1.5rem;
            flex-wrap: wrap;
        }
        .product-image {
            width: 80px; height: 80px; border-radius: 10px; overflow: hidden;
            background: linear-gradient(135deg, #667eea, #764ba2);
            display: flex; align-items: center; justify-content: center;
        }
        .product-image img { width: 100%; height: 100%; object-fit: cover; }
        .product-details h3 { margin-bottom: 0.25rem; }
        .product-details p { color: #666; font-size: 0.9rem; }
        .rating-section { margin-bottom: 1.5rem; text-align: center; }
        .rating-label { font-weight: bold; margin-bottom: 0.5rem; display: block; }
        .stars {
            display: flex; justify-content: center; gap: 0.5rem; flex-direction: row-reverse;
        }
        .star-input {
            display: none;
        }
        .star-label {
            font-size: 2rem; color: #ddd; cursor: pointer; transition: color 0.2s;
        }
        .star-label:hover, .star-label:hover ~ .star-label {
            color: #fbbf24;
        }
        .star-input:checked ~ .star-label {
            color: #fbbf24;
        }
        .form-group { margin-bottom: 1.5rem; }
        label { display: block; margin-bottom: 0.5rem; font-weight: 500; }
        textarea {
            width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px;
            font-size: 1rem; font-family: inherit; resize: vertical; min-height: 120px;
        }
        textarea:focus { outline: none; border-color: #667eea; }
        button {
            width: 100%; background: #48bb78; color: white; padding: 12px;
            border: none; border-radius: 8px; font-size: 1rem; font-weight: bold;
            cursor: pointer; transition: background 0.3s;
        }
        button:hover { background: #38a169; }
        .back-link {
            display: block; text-align: center; margin-top: 1rem;
            color: #667eea; text-decoration: none;
        }
        .back-link:hover { text-decoration: underline; }
        .svg-icon { width: 20px; height: 20px; vertical-align: middle; margin-right: 8px; stroke: currentColor; fill: none; stroke-width: 2; }
        .svg-icon-small { width: 14px; height: 14px; vertical-align: middle; margin-right: 4px; stroke: currentColor; fill: none; stroke-width: 2; }
        @media (max-width: 768px) {
            .navbar { flex-direction: column; }
            .form-container { padding: 1.5rem; margin: 1rem; }
            .dropdown-content { right: auto; left: 0; }
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
            <% } else if (!isLoggedIn) { %>
                <a href="login">Login</a>
                <a href="register">Register</a>
            <% } %>
        </div>
    </div>

    <div class="form-container">
        <h2>
            <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
            Write a Review
        </h2>

        <div class="product-info">
            <div class="product-image">
                <img src="<%= product.getImagePath() %>"
                     alt="<%= product.getProductName() %>"
                     onerror="this.parentElement.innerHTML='<div class=\'no-image\'><svg width=\'40\' height=\'40\' viewBox=\'0 0 24 24\' fill=\'none\' stroke=\'white\' stroke-width=\'2\'><circle cx=\'12\' cy=\'12\' r=\'10\'/><path d=\'M12 6a6 6 0 0 0-6 6 6 6 0 0 0 6 6 6 6 0 0 0 6-6 6 6 0 0 0-6-6z\'/><circle cx=\'12\' cy=\'12\' r=\'2\'/></svg></div>'">
            </div>
            <div class="product-details">
                <h3><%= product.getProductName() %></h3>
                <p>Price: $<%= String.format("%.2f", product.getPrice()) %></p>
            </div>
        </div>

        <form action="reviews" method="post">
            <input type="hidden" name="action" value="submit">
            <input type="hidden" name="orderId" value="<%= orderId %>">
            <input type="hidden" name="productId" value="<%= productId %>">

            <div class="rating-section">
                <span class="rating-label">Your Rating</span>
                <div class="stars">
                    <input type="radio" name="rating" id="star5" value="5" class="star-input" required>
                    <label for="star5" class="star-label">★</label>
                    <input type="radio" name="rating" id="star4" value="4" class="star-input">
                    <label for="star4" class="star-label">★</label>
                    <input type="radio" name="rating" id="star3" value="3" class="star-input">
                    <label for="star3" class="star-label">★</label>
                    <input type="radio" name="rating" id="star2" value="2" class="star-input">
                    <label for="star2" class="star-label">★</label>
                    <input type="radio" name="rating" id="star1" value="1" class="star-input">
                    <label for="star1" class="star-label">★</label>
                </div>
            </div>

            <div class="form-group">
                <label>Your Review</label>
                <textarea name="comment" placeholder="Share your experience with this product..." required></textarea>
            </div>

            <button type="submit">
                <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                </svg>
                Submit Review
            </button>
        </form>
        <a href="orders" class="back-link">← Back to Orders</a>
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

        setInterval(updateCartCount, 5000);
        updateCartCount();
    </script>
</body>
</html>