<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.toystore.model.Order, com.toystore.model.OrderItem, com.toystore.model.User, com.toystore.dao.NotificationDAO, com.toystore.dao.ReviewDAO" %>
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

    List<Order> orders = (List<Order>) request.getAttribute("orders");
    boolean isAdminView = (Boolean) request.getAttribute("isAdmin") != null && (Boolean) request.getAttribute("isAdmin");
    boolean isSearchResult = (Boolean) request.getAttribute("isSearchResult") != null && (Boolean) request.getAttribute("isSearchResult");
    String searchKeyword = (String) request.getAttribute("searchKeyword");
    Integer orderCount = (Integer) request.getAttribute("orderCount");
    if (orderCount == null && orders != null) orderCount = orders.size();
    if (orderCount == null) orderCount = 0;

    String successMessage = (String) session.getAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");

    if (successMessage != null) session.removeAttribute("successMessage");
    if (errorMessage != null) session.removeAttribute("errorMessage");

    // Create ReviewDAO for checking review status
    ReviewDAO reviewDAO = new ReviewDAO();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Toy Store - <%= isAdminView ? "All Orders" : "My Orders" %></title>
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
            letter-spacing: 0.5px;
            display: inline-block;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }

        .container {
            max-width: 1400px;
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

        .admin-stats {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 1rem;
            border-radius: 10px;
            margin-bottom: 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 1rem;
        }

        .stats-card {
            background: rgba(255,255,255,0.2);
            padding: 0.5rem 1rem;
            border-radius: 10px;
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

        .order-card {
            background: white;
            border-radius: 10px;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.3s;
        }

        .order-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.15);
        }

        .order-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-bottom: 1rem;
            border-bottom: 2px solid #eee;
            margin-bottom: 1rem;
            flex-wrap: wrap;
            gap: 1rem;
        }

        .order-id {
            font-weight: bold;
            color: #667eea;
            font-size: 1.1rem;
        }

        .order-status {
            padding: 5px 12px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 0.9rem;
        }

        .status-pending {
            background: #fed7d7;
            color: #c53030;
        }

        .status-processing {
            background: #feebc8;
            color: #c05621;
        }

        .status-shipped {
            background: #c6f6d5;
            color: #276749;
        }

        .status-delivered {
            background: #c6f6d5;
            color: #276749;
        }

        .order-date {
            color: #666;
            font-size: 0.9rem;
        }

        .customer-info {
            background: #f7fafc;
            padding: 0.75rem 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            border-left: 4px solid #667eea;
        }

        .contact-info {
            background: #e6fffa;
            padding: 0.75rem 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            border-left: 3px solid #38b2ac;
        }

        .customer-name {
            font-size: 1rem;
            font-weight: bold;
            color: #333;
        }

        .customer-name span {
            color: #667eea;
        }

        .shipping-address {
            background: #fff5f0;
            padding: 0.75rem 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            border-left: 3px solid #ed8936;
        }

        .shipping-address strong {
            color: #ed8936;
        }

        .order-items {
            margin: 1rem 0;
        }

        .order-items strong {
            display: block;
            margin-bottom: 0.5rem;
            color: #555;
        }

        .order-item {
            padding: 0.75rem 0;
            border-bottom: 1px solid #f0f0f0;
            display: flex;
            align-items: center;
            gap: 1rem;
            flex-wrap: wrap;
        }

        .order-item-image {
            width: 50px;
            height: 50px;
            border-radius: 8px;
            overflow: hidden;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .order-item-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .order-item-image .no-image {
            font-size: 1.2rem;
        }

        .order-item-details {
            flex: 1;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 0.5rem;
        }

        .order-item-name {
            font-weight: 500;
            color: #333;
        }

        .order-item-price {
            color: #667eea;
            font-weight: 500;
        }

        .order-total {
            text-align: right;
            font-weight: bold;
            font-size: 1.2rem;
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #eee;
            color: #667eea;
        }

        .review-section {
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #eee;
        }

        .review-btn {
            background: #667eea;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            text-decoration: none;
            font-size: 0.85rem;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: all 0.3s;
        }

        .review-btn:hover {
            background: #5a67d8;
            transform: translateY(-2px);
        }

        .reviewed-badge {
            background: #c6f6d5;
            color: #22543d;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.85rem;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }

        .status-update {
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #eee;
            display: flex;
            gap: 0.5rem;
            align-items: center;
            flex-wrap: wrap;
        }

        .status-select {
            padding: 5px 10px;
            border-radius: 5px;
            border: 1px solid #ddd;
        }

        .update-status-btn {
            background: #667eea;
            color: white;
            border: none;
            padding: 5px 15px;
            border-radius: 5px;
            cursor: pointer;
        }

        .update-status-btn:hover {
            background: #5a67d8;
        }

        .no-orders {
            text-align: center;
            padding: 3rem;
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .browse-products {
            display: inline-block;
            padding: 10px 20px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 1rem;
        }

        .browse-products:hover {
            background: #5a67d8;
        }

        @media (max-width: 768px) {
            .navbar {
                flex-direction: column;
            }
            .order-header {
                flex-direction: column;
                align-items: flex-start;
            }
            .admin-stats {
                flex-direction: column;
                text-align: center;
            }
            .order-item-details {
                flex-direction: column;
                align-items: flex-start;
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
                <a href="orders" style="color: #667eea; font-weight: bold;">
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
                        <a href="orders" style="color: #667eea; font-weight: bold;" id="dropdownOrders">
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
        <div class="header">
            <h1>
                <svg style="width:28px;height:28px;vertical-align:middle;margin-right:10px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                </svg>
                <%= isAdminView ? "All Customer Orders" : "My Orders" %>
            </h1>

            <% if (isAdminView) { %>
                <form action="orders" method="get" class="search-container">
                    <span class="search-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="11" cy="11" r="8"/>
                            <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                        </svg>
                    </span>
                    <input type="text"
                           name="search"
                           class="search-input"
                           placeholder="Search by Order ID or Username..."
                           value="<%= searchKeyword != null ? searchKeyword : "" %>"
                           autocomplete="off">
                    <button type="submit" class="search-btn">Search</button>
                    <% if (searchKeyword != null && !searchKeyword.isEmpty()) { %>
                        <a href="orders" class="clear-search">Clear</a>
                    <% } %>
                </form>
            <% } %>
        </div>

        <% if (isAdminView && searchKeyword != null && !searchKeyword.isEmpty()) { %>
            <div class="search-info">
                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"/>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                Showing <strong><%= orderCount %></strong> order(s) for "<strong><%= searchKeyword %></strong>"
            </div>
        <% } %>

        <% if (isAdminView && orders != null && !orders.isEmpty()) {
            int totalOrders = orders.size();
            double totalRevenue = 0;
            int pendingOrders = 0;
            for (Order order : orders) {
                totalRevenue += order.getTotalAmount();
                if (order.getOrderStatus().equals("Pending")) pendingOrders++;
            }
        %>
            <div class="admin-stats">
                <div class="stats-card">
                    <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/>
                        <line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                    Showing Orders: <%= totalOrders %>
                </div>
                <div class="stats-card">
                    <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="4" x2="12" y2="12"/>
                        <line x1="12" y1="12" x2="16" y2="16"/>
                    </svg>
                    Total Revenue: $<%= String.format("%.2f", totalRevenue) %>
                </div>
                <div class="stats-card">
                    <svg style="width:16px;height:16px;vertical-align:middle;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    Pending Orders: <%= pendingOrders %>
                </div>
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

        <% if (orders != null && !orders.isEmpty()) {
            for (Order order : orders) {
                String statusClass = "";
                if (order.getOrderStatus().equals("Pending")) statusClass = "status-pending";
                else if (order.getOrderStatus().equals("Processing")) statusClass = "status-processing";
                else if (order.getOrderStatus().equals("Shipped")) statusClass = "status-shipped";
                else if (order.getOrderStatus().equals("Delivered")) statusClass = "status-delivered";

                User customer = order.getCustomer();
                String customerName = "N/A";

                if (customer != null) {
                    if (customer.getFullName() != null && !customer.getFullName().isEmpty()) {
                        customerName = customer.getFullName();
                    } else if (customer.getUsername() != null && !customer.getUsername().isEmpty()) {
                        customerName = customer.getUsername();
                    } else {
                        customerName = "Customer #" + order.getUserId();
                    }
                }
        %>
            <div class="order-card">
                <div class="order-header">
                    <div>
                        <span class="order-id">Order #<%= order.getOrderId() %></span>
                        <div class="order-date">
                            <svg style="width:14px;height:14px;vertical-align:middle;margin-right:4px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                                <line x1="16" y1="2" x2="16" y2="6"/>
                                <line x1="8" y1="2" x2="8" y2="6"/>
                                <line x1="3" y1="10" x2="21" y2="10"/>
                            </svg>
                            Placed on: <%= order.getOrderDate() %>
                        </div>
                    </div>
                    <div>
                        <span class="order-status <%= statusClass %>"><%= order.getOrderStatus() %></span>
                    </div>
                </div>

                <% if (isAdminView) { %>
                    <div class="customer-info">
                        <span class="customer-name">
                            <svg style="width:16px;height:16px;vertical-align:middle;margin-right:6px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                <circle cx="12" cy="7" r="4"/>
                            </svg>
                            Customer: <span><%= customerName %></span> (Username: <%= customer != null ? customer.getUsername() : "N/A" %>)
                        </span>
                    </div>

                    <% if (order.getContactNumber() != null && !order.getContactNumber().isEmpty()) { %>
                        <div class="contact-info">
                            <svg style="width:16px;height:16px;vertical-align:middle;margin-right:6px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="5" y="2" width="14" height="20" rx="2" ry="2"/>
                                <line x1="12" y1="18" x2="12" y2="18"/>
                            </svg>
                            Contact Number: <%= order.getContactNumber() %>
                        </div>
                    <% } %>
                <% } %>

                <div class="shipping-address">
                    <svg style="width:16px;height:16px;vertical-align:middle;margin-right:6px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                        <circle cx="12" cy="10" r="3"/>
                    </svg>
                    <strong>Shipping Address:</strong><br>
                    <%= order.getShippingAddress() != null ? order.getShippingAddress().replace("\n", "<br>") : "No shipping address provided" %>
                </div>

                <div style="background: #fef5e7; padding: 0.5rem 1rem; border-radius: 8px; margin-bottom: 1rem;">
                    <svg style="width:16px;height:16px;vertical-align:middle;margin-right:6px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/>
                        <circle cx="7" cy="18" r="2"/>
                        <circle cx="17" cy="18" r="2"/>
                    </svg>
                    Payment Method: <%= order.getPaymentMethod() != null ? order.getPaymentMethod() : "Not specified" %>
                </div>

                <div class="order-items">
                    <strong>
                        <svg style="width:16px;height:16px;vertical-align:middle;margin-right:6px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="9" cy="21" r="1"/>
                            <circle cx="20" cy="21" r="1"/>
                            <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                        </svg>
                        Items Ordered:
                    </strong>
                    <% if (order.getOrderItems() != null) {
                        for (OrderItem item : order.getOrderItems()) {
                            if (item != null) {
                                String imagePath = item.getImagePath();
                    %>
                        <div class="order-item">
                            <div class="order-item-image">
                                <img src="<%= imagePath %>"
                                     alt="<%= item.getProductName() %>"
                                     onerror="this.onerror=null; this.parentElement.innerHTML='<div class=\'no-image\'>\
                                         <svg width=\'30\' height=\'30\' viewBox=\'0 0 24 24\' fill=\'none\' stroke=\'white\' stroke-width=\'2\' stroke-linecap=\'round\' stroke-linejoin=\'round\'>\
                                             <circle cx=\'12\' cy=\'12\' r=\'10\'/>\
                                             <path d=\'M12 6a6 6 0 0 0-6 6 6 6 0 0 0 6 6 6 6 0 0 0 6-6 6 6 0 0 0-6-6z\'/>\
                                             <circle cx=\'12\' cy=\'12\' r=\'2\'/>\
                                         </svg>\
                                     </div>'">
                            </div>
                            <div class="order-item-details">
                                <span class="order-item-name"><%= item.getQuantity() %>x <%= item.getProductName() %></span>
                                <span class="order-item-price">$<%= String.format("%.2f", item.getPriceAtTime() * item.getQuantity()) %></span>
                            </div>
                        </div>
                    <%      }
                        }
                    } %>
                </div>

                <div class="order-total">
                    <strong>Total Amount:</strong> $<%= String.format("%.2f", order.getTotalAmount()) %>
                </div>

                <!-- FIXED REVIEW SECTION - Shows review button only if not already reviewed -->
                <% if (!isAdminView && "Delivered".equals(order.getOrderStatus())) {
                    boolean hasReviewableItems = false;

                    // First pass: check if any items are not yet reviewed
                    for (OrderItem item : order.getOrderItems()) {
                        if (item != null) {
                            boolean alreadyReviewed = reviewDAO.hasUserReviewedProduct(loggedInUser.getUserId(), item.getProductId(), order.getOrderId());
                            if (!alreadyReviewed) {
                                hasReviewableItems = true;
                                break;
                            }
                        }
                    }

                    if (hasReviewableItems) { %>
                        <div class="review-section">
                            <strong>Write a Review:</strong>
                            <div style="display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.5rem;">
                                <% for (OrderItem item : order.getOrderItems()) {
                                    if (item != null) {
                                        boolean alreadyReviewed = reviewDAO.hasUserReviewedProduct(loggedInUser.getUserId(), item.getProductId(), order.getOrderId());
                                        if (!alreadyReviewed) { %>
                                            <a href="reviews?action=write&orderId=<%= order.getOrderId() %>&productId=<%= item.getProductId() %>" class="review-btn">
                                                <svg style="width:14px;height:14px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                                </svg>
                                                Review <%= item.getProductName() %>
                                            </a>
                                        <% } else { %>
                                            <span class="reviewed-badge">
                                                <svg style="width:14px;height:14px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                    <path d="M20 6L9 17l-5-5"/>
                                                </svg>
                                                <%= item.getProductName() %> - Reviewed ✓
                                            </span>
                                        <% }
                                    }
                                } %>
                            </div>
                        </div>
                <% }
                } %>

                <% if (isAdminView) { %>
                    <form action="orders" method="get" class="status-update">
                        <input type="hidden" name="action" value="updateStatus">
                        <input type="hidden" name="orderId" value="<%= order.getOrderId() %>">
                        <label><strong>Update Status:</strong></label>
                        <select name="status" class="status-select">
                            <option value="Pending" <%= order.getOrderStatus().equals("Pending") ? "selected" : "" %>>Pending</option>
                            <option value="Processing" <%= order.getOrderStatus().equals("Processing") ? "selected" : "" %>>Processing</option>
                            <option value="Shipped" <%= order.getOrderStatus().equals("Shipped") ? "selected" : "" %>>Shipped</option>
                            <option value="Delivered" <%= order.getOrderStatus().equals("Delivered") ? "selected" : "" %>>Delivered</option>
                        </select>
                        <button type="submit" class="update-status-btn">Update Status</button>
                    </form>
                <% } %>
            </div>
        <% }
            } else {
        %>
            <div class="no-orders">
                <svg style="width:64px;height:64px;margin-bottom:1rem;color:#999;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                </svg>
                <h2><%= isAdminView ? "No Orders Found" : "No Orders Yet" %></h2>
                <p><%= isAdminView ? (searchKeyword != null && !searchKeyword.isEmpty() ? "No orders match your search criteria \"" + searchKeyword + "\"." : "No customers have placed orders yet.") : "You haven't placed any orders yet. Start shopping to see your orders here!" %></p>
                <% if (isAdminView && searchKeyword != null && !searchKeyword.isEmpty()) { %>
                    <a href="orders" class="browse-products">View All Orders →</a>
                <% } else if (!isAdminView) { %>
                    <a href="products" class="browse-products">Browse Products →</a>
                <% } %>
            </div>
        <% } %>
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

        document.querySelector('.search-input')?.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                this.form.submit();
            }
        });
    </script>
</body>
</html>