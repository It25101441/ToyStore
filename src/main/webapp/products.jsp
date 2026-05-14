<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.toystore.model.Product, com.toystore.model.User, com.toystore.dao.NotificationDAO" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    String loggedInUsername = (String) session.getAttribute("username");
    boolean isAdmin = (loggedInUser != null && loggedInUser.isAdmin());
    boolean isLoggedIn = (loggedInUser != null);

    if (loggedInUsername == null || loggedInUsername.isEmpty()) {
        loggedInUsername = "User";
    }

    int unreadCount = 0;
    int unreadMessageCount = 0;
    if (isLoggedIn) {
        NotificationDAO notifDAO = new NotificationDAO();
        unreadCount = notifDAO.getUnreadCount(loggedInUser.getUserId());
        com.toystore.dao.MessageDAO messageDAO = new com.toystore.dao.MessageDAO();
        unreadMessageCount = messageDAO.getUnreadCount(loggedInUser.getUserId());
    }

    String successMessage = (String) session.getAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");
    String cartMessage = (String) session.getAttribute("cartMessage");
    String cartError = (String) session.getAttribute("cartError");

    if (successMessage != null) session.removeAttribute("successMessage");
    if (errorMessage != null) session.removeAttribute("errorMessage");
    if (cartMessage != null) session.removeAttribute("cartMessage");
    if (cartError != null) session.removeAttribute("cartError");

    String searchKeyword = request.getParameter("search");
    boolean isSearchResult = (searchKeyword != null && !searchKeyword.trim().isEmpty());

    List<Product> products = (List<Product>) request.getAttribute("products");
    Integer productCount = (Integer) request.getAttribute("productCount");
    if (productCount == null && products != null) productCount = products.size();
    if (productCount == null) productCount = 0;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Toy Store - Products</title>
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
            position: sticky;
            top: 0;
            z-index: 100;
            flex-wrap: wrap;
            gap: 1rem;
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

        .nav-icon-large {
            width: 24px;
            height: 24px;
            vertical-align: middle;
            margin-right: 6px;
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
            animation: bounce 0.5s ease;
        }

        @keyframes bounce {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.2); }
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
            letter-spacing: 0.5px;
            display: inline-block;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }

        .admin-warning {
            background: linear-gradient(135deg, #fed7d7, #fff5f5);
            color: #742a2a;
            padding: 12px 20px;
            border-radius: 10px;
            margin-bottom: 1.5rem;
            text-align: center;
            border-left: 4px solid #e53e3e;
            font-weight: 500;
        }

        .container {
            max-width: 1200px;
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

        .search-container {
            display: flex;
            gap: 0.5rem;
            align-items: center;
            background: white;
            padding: 0.25rem 0.5rem;
            border-radius: 40px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .search-icon {
            font-size: 1.2rem;
            color: #667eea;
            padding: 0.5rem;
        }

        .search-input {
            border: none;
            padding: 0.6rem 0.8rem;
            font-size: 0.95rem;
            width: 280px;
            outline: none;
            font-family: inherit;
            background: transparent;
        }

        .search-input:focus {
            outline: none;
        }

        .search-input::placeholder {
            color: #999;
            font-size: 0.85rem;
        }

        .search-btn {
            background: #667eea;
            color: white;
            border: none;
            padding: 0.5rem 1.2rem;
            border-radius: 30px;
            cursor: pointer;
            font-weight: 500;
            transition: all 0.3s;
        }

        .search-btn:hover {
            background: #5a67d8;
            transform: translateY(-1px);
        }

        .clear-search {
            background: #e2e8f0;
            color: #4a5568;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 30px;
            font-size: 0.85rem;
            transition: all 0.3s;
        }

        .clear-search:hover {
            background: #cbd5e0;
        }

        .search-info {
            background: #e6fffa;
            color: #234e52;
            padding: 8px 15px;
            border-radius: 20px;
            font-size: 0.85rem;
            margin-bottom: 1rem;
            display: inline-block;
        }

        .add-product-btn {
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

        .add-product-btn:hover {
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

        .cart-message {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 12px 20px;
            border-radius: 10px;
            margin-bottom: 1rem;
            text-align: center;
            animation: slideIn 0.5s ease;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
        }

        .cart-message a {
            color: #ffd700;
            text-decoration: none;
            font-weight: bold;
            background: rgba(255,255,255,0.2);
            padding: 5px 15px;
            border-radius: 20px;
            transition: all 0.3s;
        }

        .cart-message a:hover {
            background: rgba(255,255,255,0.3);
            transform: scale(1.05);
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

        .products-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 2rem;
        }

        .product-card {
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.3s, box-shadow 0.3s;
        }

        .product-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.15);
        }

        .product-image {
            height: 200px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            position: relative;
        }

        .product-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s;
        }

        .product-card:hover .product-image img {
            transform: scale(1.05);
        }

        .product-image .no-image {
            font-size: 4rem;
            text-align: center;
        }

        .product-info {
            padding: 1.5rem;
        }

        .product-name {
            font-size: 1.2rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
            color: #333;
        }

        .product-description {
            color: #666;
            font-size: 0.9rem;
            margin-bottom: 0.5rem;
            line-height: 1.4;
        }

        .product-rating {
            margin: 0.5rem 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .stars-container {
            display: flex;
            align-items: center;
            gap: 0.25rem;
        }

        .star-filled {
            color: #fbbf24;
        }

        .star-empty {
            color: #ddd;
        }

        .rating-text {
            font-size: 0.75rem;
            color: #666;
        }

        .product-price {
            color: #667eea;
            font-size: 1.3rem;
            font-weight: bold;
            margin: 0.5rem 0;
        }

        .product-stock {
            color: #666;
            font-size: 0.9rem;
            margin-bottom: 1rem;
        }

        .add-to-cart-section {
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #eee;
        }

        .quantity-control {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.5rem;
            margin-bottom: 0.8rem;
        }

        .qty-btn {
            background: #e2e8f0;
            border: none;
            width: 32px;
            height: 32px;
            border-radius: 5px;
            font-size: 1.2rem;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
            color: #4a5568;
        }

        .qty-btn:hover {
            background: #cbd5e0;
            transform: scale(1.05);
        }

        .qty-btn:active {
            transform: scale(0.95);
        }

        .qty-input {
            width: 50px;
            text-align: center;
            padding: 6px;
            border: 1px solid #e2e8f0;
            border-radius: 5px;
            font-size: 1rem;
        }

        .add-to-cart-btn {
            background: #667eea;
            color: white;
            width: 100%;
            padding: 10px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 0.95rem;
            font-weight: 500;
            transition: all 0.3s;
        }

        .add-to-cart-btn:hover {
            background: #5a67d8;
            transform: translateY(-2px);
        }

        .add-to-cart-btn:active {
            transform: translateY(0);
        }

        .out-of-stock-btn {
            background: #a0aec0;
            cursor: not-allowed;
            width: 100%;
            padding: 10px;
            border: none;
            border-radius: 5px;
            color: white;
        }

        .login-prompt {
            text-align: center;
            text-decoration: none;
            display: block;
            background: #667eea;
            color: white;
            padding: 10px;
            border-radius: 5px;
            margin-top: 0.5rem;
            transition: all 0.3s;
        }

        .login-prompt:hover {
            background: #5a67d8;
            transform: translateY(-2px);
        }

        .admin-actions {
            display: flex;
            gap: 0.5rem;
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #eee;
        }

        .edit-btn, .delete-btn {
            flex: 1;
            padding: 8px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            text-align: center;
            font-size: 0.9rem;
            font-weight: 500;
            transition: all 0.3s;
        }

        .edit-btn {
            background: #4299e1;
            color: white;
        }

        .edit-btn:hover {
            background: #3182ce;
            transform: translateY(-2px);
        }

        .delete-btn {
            background: #e53e3e;
            color: white;
        }

        .delete-btn:hover {
            background: #c53030;
            transform: translateY(-2px);
        }

        .view-btn {
            display: inline-block;
            padding: 6px 15px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-size: 0.85rem;
            transition: background 0.3s;
            width: 100%;
            text-align: center;
            margin-top: 0.5rem;
        }

        .view-btn:hover {
            background: #5a67d8;
        }

        .no-products {
            text-align: center;
            padding: 3rem;
            background: white;
            border-radius: 10px;
            grid-column: 1 / -1;
        }

        .no-products p {
            color: #666;
            margin-bottom: 1rem;
        }

        @media (max-width: 768px) {
            .navbar {
                flex-direction: column;
            }
            .products-grid {
                grid-template-columns: 1fr;
            }
            .header {
                flex-direction: column;
                align-items: stretch;
            }
            .search-container {
                width: 100%;
            }
            .search-input {
                flex: 1;
            }
            .quantity-control {
                justify-content: center;
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
                <svg class="nav-icon-large" style="width:28px;height:28px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
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
                        <a href="messages" class="nav-messages-link">
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
        <% if (isAdmin) { %>
            <div class="admin-warning">
                <svg style="width:18px;height:18px;vertical-align:middle;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <strong>Admin Mode Active</strong> | You can manage products and view all customer orders | Shopping cart is disabled for admin accounts
            </div>
        <% } %>

        <div class="header">
            <h1>Our Toys Collection</h1>

            <form action="products" method="get" class="search-container">
                <span class="search-icon">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="11" cy="11" r="8"/>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                    </svg>
                </span>
                <input type="text"
                       name="search"
                       class="search-input"
                       placeholder="Search by product name or category..."
                       value="<%= searchKeyword != null ? searchKeyword : "" %>"
                       autocomplete="off">
                <button type="submit" class="search-btn">Search</button>
                <% if (isSearchResult) { %>
                    <a href="products" class="clear-search">Clear</a>
                <% } %>
            </form>

            <% if (isAdmin) { %>
                <a href="products?action=add" class="add-product-btn">
                    <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="12" y1="5" x2="12" y2="19"/>
                        <line x1="5" y1="12" x2="19" y2="12"/>
                    </svg>
                    Add New Product
                </a>
            <% } %>
        </div>

        <% if (isSearchResult) { %>
            <div class="search-info">
                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"/>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                Found <strong><%= productCount %></strong> product(s) matching "<strong><%= searchKeyword %></strong>"
            </div>
        <% } %>

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

        <% if (cartMessage != null && !cartMessage.isEmpty()) { %>
            <div class="cart-message">
                <span>
                    <svg style="width:16px;height:16px;vertical-align:middle;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="9" cy="21" r="1"/>
                        <circle cx="20" cy="21" r="1"/>
                        <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                    </svg>
                    <%= cartMessage %>
                </span>
                <a href="cart">View Cart →</a>
            </div>
        <% } %>

        <% if (cartError != null && !cartError.isEmpty()) { %>
            <div class="error-message">
                <svg style="width:16px;height:16px;vertical-align:middle;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= cartError %>
            </div>
        <% } %>

        <div class="products-grid">
            <% if (products != null && !products.isEmpty()) {
                for (Product product : products) {
            %>
                <div class="product-card" data-product-id="<%= product.getProductId() %>" data-stock="<%= product.getStockQuantity() %>">
                    <div class="product-image">
                        <img src="<%= product.getImagePath() %>"
                             alt="<%= product.getProductName() %>"
                             onerror="this.onerror=null; this.parentElement.innerHTML='<div class=\'no-image\'>\
                                 <svg width=\'60\' height=\'60\' viewBox=\'0 0 24 24\' fill=\'none\' stroke=\'white\' stroke-width=\'2\' stroke-linecap=\'round\' stroke-linejoin=\'round\'>\
                                     <circle cx=\'12\' cy=\'12\' r=\'10\'/>\
                                     <path d=\'M12 6a6 6 0 0 0-6 6 6 6 0 0 0 6 6 6 6 0 0 0 6-6 6 6 0 0 0-6-6z\'/>\
                                     <circle cx=\'12\' cy=\'12\' r=\'2\'/>\
                                 </svg>\
                             </div>'">
                    </div>
                    <div class="product-info">
                        <div class="product-name"><%= product.getProductName() %></div>
                        <div class="product-description">
                            <%= product.getDescription() != null ? product.getDescription() : "No description available" %>
                        </div>

                        <!-- Rating Display -->
                        <div class="product-rating">
                            <div class="stars-container">
                                <% if (product.getAverageRating() > 0) {
                                    double avgRating = product.getAverageRating();
                                    int fullStars = (int) avgRating;
                                    for (int i = 1; i <= 5; i++) {
                                        if (i <= fullStars) { %>
                                            <svg class="star-filled" style="width:16px;height:16px;display:inline-block;" viewBox="0 0 24 24" fill="#fbbf24" stroke="none">
                                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                            </svg>
                                        <% } else { %>
                                            <svg class="star-empty" style="width:16px;height:16px;display:inline-block;" viewBox="0 0 24 24" fill="none" stroke="#ddd" stroke-width="2">
                                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                            </svg>
                                        <% }
                                    }
                                } else { %>
                                    <% for (int i = 1; i <= 5; i++) { %>
                                        <svg class="star-empty" style="width:16px;height:16px;display:inline-block;" viewBox="0 0 24 24" fill="none" stroke="#ddd" stroke-width="2">
                                            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                        </svg>
                                    <% }
                                } %>
                            </div>
                            <span class="rating-text">
                                <% if (product.getReviewCount() > 0) { %>
                                    <%= String.format("%.1f", product.getAverageRating()) %> ★ (<%= product.getReviewCount() %> <%= product.getReviewCount() == 1 ? "review" : "reviews" %>)
                                <% } else { %>
                                    No reviews yet
                                <% } %>
                            </span>
                        </div>

                        <div class="product-price">$<%= String.format("%.2f", product.getPrice()) %></div>
                        <div class="product-stock">
                            Stock: <%= product.getStockQuantity() %> units
                        </div>

                        <!-- View Details Button - UPDATED to link to product detail page -->
                        <a href="products?id=<%= product.getProductId() %>" class="view-btn">
                            View Details →
                        </a>

                        <% if (isLoggedIn && !isAdmin) { %>
                            <% if (product.getStockQuantity() > 0) { %>
                                <div class="add-to-cart-section">
                                    <div class="quantity-control">
                                        <button type="button" class="qty-btn" onclick="updateQuantity(this, -1, <%= product.getStockQuantity() %>)">−</button>
                                        <input type="number" id="qty_<%= product.getProductId() %>" class="qty-input" value="1" min="1" max="<%= product.getStockQuantity() %>" readonly>
                                        <button type="button" class="qty-btn" onclick="updateQuantity(this, 1, <%= product.getStockQuantity() %>)">+</button>
                                    </div>
                                    <form id="cartForm_<%= product.getProductId() %>" action="cart" method="post" onsubmit="return validateQuantity(<%= product.getProductId() %>, <%= product.getStockQuantity() %>)">
                                        <input type="hidden" name="action" value="add">
                                        <input type="hidden" name="productId" value="<%= product.getProductId() %>">
                                        <input type="hidden" name="quantity" id="hiddenQty_<%= product.getProductId() %>" value="1">
                                        <button type="submit" class="add-to-cart-btn">
                                            <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <circle cx="9" cy="21" r="1"/>
                                                <circle cx="20" cy="21" r="1"/>
                                                <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                                            </svg>
                                            Add to Cart
                                        </button>
                                    </form>
                                </div>
                            <% } else { %>
                                <button class="out-of-stock-btn" disabled>Out of Stock</button>
                            <% } %>
                        <% } else if (!isLoggedIn) { %>
                            <a href="login" class="login-prompt">
                                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                                </svg>
                                Login to Purchase
                            </a>
                        <% } %>

                        <% if (isAdmin) { %>
                            <div class="admin-actions">
                                <a href="products?action=edit&id=<%= product.getProductId() %>" class="edit-btn">
                                    <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3l4 4-7 7H10v-4l7-7z"/>
                                        <path d="M3 21h18"/>
                                    </svg>
                                    Edit
                                </a>
                                <a href="#" onclick="confirmDelete(<%= product.getProductId() %>, '<%= product.getProductName() %>')" class="delete-btn">
                                    <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="3 6 5 6 21 6"/>
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                    </svg>
                                    Delete
                                </a>
                            </div>
                        <% } %>
                    </div>
                </div>
            <% }
                } else {
            %>
                <div class="no-products">
                    <svg style="width:48px;height:48px;margin-bottom:1rem;color:#999;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <p>No products found</p>
                    <% if (isSearchResult) { %>
                        <p>No products matching "<strong><%= searchKeyword %></strong>" were found.</p>
                        <a href="products" style="display: inline-block; margin-top: 15px; color: #667eea;">View all products →</a>
                    <% } else if (isAdmin) { %>
                        <p>No products available at the moment.</p>
                        <a href="products?action=add" class="add-product-btn" style="margin-top: 1rem; display: inline-block;">Add Your First Product</a>
                    <% } else { %>
                        <p>No products available at the moment. Please check back later!</p>
                    <% } %>
                </div>
            <% } %>
        </div>
    </div>

    <script>
        function updateQuantity(button, delta, maxStock) {
            const quantityControl = button.closest('.quantity-control');
            const input = quantityControl.querySelector('.qty-input');
            let currentValue = parseInt(input.value) || 1;
            let newValue = currentValue + delta;

            if (newValue < 1) {
                newValue = 1;
            }
            if (newValue > maxStock) {
                newValue = maxStock;
                showTemporaryMessage('Only ' + maxStock + ' units available in stock', 'error');
            }

            input.value = newValue;

            const productId = input.id.split('_')[1];
            const hiddenInput = document.getElementById('hiddenQty_' + productId);
            if (hiddenInput) {
                hiddenInput.value = newValue;
            }
        }

        function validateQuantity(productId, maxStock) {
            const quantityInput = document.getElementById('qty_' + productId);
            let quantity = parseInt(quantityInput.value) || 1;

            if (quantity < 1) {
                showTemporaryMessage('Please select at least 1 item', 'error');
                quantityInput.value = 1;
                document.getElementById('hiddenQty_' + productId).value = 1;
                return false;
            }

            if (quantity > maxStock) {
                showTemporaryMessage('Only ' + maxStock + ' items available in stock', 'error');
                quantityInput.value = maxStock;
                document.getElementById('hiddenQty_' + productId).value = maxStock;
                return false;
            }

            showTemporaryMessage('Item added to cart!', 'success');
            return true;
        }

        function showTemporaryMessage(message, type) {
            let messageDiv = document.getElementById('tempMessage');
            if (!messageDiv) {
                messageDiv = document.createElement('div');
                messageDiv.id = 'tempMessage';
                const container = document.querySelector('.container');
                const header = document.querySelector('.header');
                container.insertBefore(messageDiv, header.nextSibling);
            }

            messageDiv.className = type === 'success' ? 'success-message' : 'error-message';
            messageDiv.innerHTML = (type === 'success' ? '✓ ' : '⚠️ ') + message;
            messageDiv.style.display = 'block';

            setTimeout(() => {
                messageDiv.style.display = 'none';
            }, 2000);
        }

        function confirmDelete(productId, productName) {
            if (confirm('Are you sure you want to delete "' + productName + '"?\n\nThis action cannot be undone!')) {
                window.location.href = 'products?action=delete&id=' + productId;
            }
            return false;
        }

        document.querySelectorAll('.qty-input').forEach(input => {
            input.addEventListener('change', function() {
                let value = parseInt(this.value) || 1;
                const maxStock = parseInt(this.closest('.product-card').dataset.stock) || 999;
                if (value < 1) value = 1;
                if (value > maxStock) {
                    value = maxStock;
                    showTemporaryMessage('Only ' + maxStock + ' units available', 'error');
                }
                this.value = value;
                const productId = this.id.split('_')[1];
                const hiddenInput = document.getElementById('hiddenQty_' + productId);
                if (hiddenInput) hiddenInput.value = value;
            });
        });

        document.querySelector('.search-input')?.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                this.form.submit();
            }
        });

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