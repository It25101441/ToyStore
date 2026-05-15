<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.toystore.model.Review, com.toystore.model.User, com.toystore.dao.NotificationDAO" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    String loggedInUsername = (String) session.getAttribute("username");
    boolean isAdmin = (loggedInUser != null && loggedInUser.isAdmin());
    boolean isLoggedIn = (loggedInUser != null);

    if (!isAdmin) {
        response.sendRedirect("products");
        return;
    }

    if (loggedInUsername == null) loggedInUsername = "Admin";

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
    String searchKeyword = (String) request.getAttribute("searchKeyword");
    Boolean isSearchResult = (Boolean) request.getAttribute("isSearchResult");

    if (reviewCount == null) reviewCount = 0;
    if (isSearchResult == null) isSearchResult = false;
    if (searchKeyword == null) searchKeyword = "";

    String successMessage = (String) session.getAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");
    if (successMessage != null) session.removeAttribute("successMessage");
    if (errorMessage != null) session.removeAttribute("errorMessage");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin - All Reviews - ToyStore</title>
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
        .user-info {
            display: flex; align-items: center; gap: 0.5rem; background: #f7fafc;
            padding: 0.3rem 0.8rem; border-radius: 20px;
        }
        .welcome-text { color: #667eea; font-weight: bold; }
        .admin-badge {
            background: linear-gradient(135deg, #e53e3e, #c53030); color: white;
            padding: 2px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: bold;
        }
        .user-menu { position: relative; display: inline-block; }
        .user-dropdown-btn {
            display: flex; align-items: center; gap: 0.5rem; background: #f7fafc;
            padding: 0.3rem 0.8rem; border-radius: 20px; cursor: pointer;
            transition: all 0.3s; border: none; font-size: 1rem; font-family: inherit;
        }
        .user-dropdown-btn:hover { background: #e2e8f0; }
        .dropdown-arrow { font-size: 0.7rem; color: #667eea; transition: transform 0.3s; }
        .user-menu:hover .dropdown-arrow { transform: rotate(180deg); }
        .dropdown-content {
            display: none; position: absolute; right: 0; top: 100%;
            background-color: white; min-width: 240px; box-shadow: 0 8px 16px rgba(0,0,0,0.2);
            border-radius: 10px; z-index: 1000; margin-top: 0.5rem; overflow: hidden;
        }
        .user-menu:hover .dropdown-content { display: block; }
        .dropdown-content a {
            display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem 1rem;
            text-decoration: none; color: #333; transition: background 0.3s;
            border-bottom: 1px solid #f0f0f0; position: relative;
        }
        .dropdown-content a:last-child { border-bottom: none; }
        .dropdown-content a:hover { background: #f7fafc; color: #667eea; }
        .dropdown-badge {
            background: #e53e3e; color: white; border-radius: 50%; padding: 2px 6px;
            font-size: 0.7rem; margin-left: auto; min-width: 20px; text-align: center;
            display: inline-block;
        }
        .dropdown-icon {
            width: 18px; height: 18px; stroke: currentColor; fill: none; stroke-width: 2;
        }
        .container { max-width: 1400px; margin: 2rem auto; padding: 0 2rem; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 1rem; }
        h1 { color: #333; }
        .admin-warning {
            background: linear-gradient(135deg, #fed7d7, #fff5f5); color: #742a2a;
            padding: 12px 20px; border-radius: 10px; margin-bottom: 1.5rem;
            text-align: center; border-left: 4px solid #e53e3e; font-weight: 500;
        }
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

        /* Search Bar Styles */
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

        .reviews-table {
            background: white; border-radius: 10px; overflow-x: auto;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 1rem; text-align: left; border-bottom: 1px solid #eee; }
        th { background: #667eea; color: white; font-weight: 600; }
        tr:hover { background: #f7fafc; }
        .product-image {
            width: 50px; height: 50px; border-radius: 8px; overflow: hidden;
            background: linear-gradient(135deg, #667eea, #764ba2);
            display: flex; align-items: center; justify-content: center;
        }
        .product-image img { width: 100%; height: 100%; object-fit: cover; }
        .stars { white-space: nowrap; }
        .star-filled { color: #fbbf24; }
        .star-empty { color: #ddd; }
        .review-comment { max-width: 250px; white-space: normal; word-wrap: break-word; }
        .delete-btn {
            background: #e53e3e; color: white; padding: 5px 12px;
            border: none; border-radius: 5px; cursor: pointer;
            transition: background 0.3s; text-decoration: none; display: inline-block;
        }
        .delete-btn:hover { background: #c53030; }
        .no-reviews { text-align: center; padding: 3rem; color: #666; }
        .svg-icon { width: 18px; height: 18px; vertical-align: middle; margin-right: 5px; stroke: currentColor; fill: none; stroke-width: 2; }
        .svg-icon-small { width: 14px; height: 14px; vertical-align: middle; margin-right: 3px; stroke: currentColor; fill: none; stroke-width: 2; }
        .logout-link {
            color: #e53e3e !important; font-weight: 600;
        }
        .logout-link:hover {
            color: #c53030 !important;
        }
        @media (max-width: 768px) {
            .navbar { flex-direction: column; }
            .reviews-table { font-size: 0.85rem; }
            th, td { padding: 0.5rem; }
            .review-comment { max-width: 150px; }
            .dropdown-content { right: auto; left: 0; }
            .header { flex-direction: column; align-items: stretch; }
            .search-container { width: 100%; }
            .search-input { flex: 1; }
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
                    <a href="reviews?action=admin" style="color: #667eea; font-weight: bold;">
                        <svg class="dropdown-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                        </svg>
                        All Reviews
                    </a>
                    <a href="messages" class="nav-messages-link">
                        <svg class="dropdown-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                        </svg>
                        Messages
                        <% if (unreadMessageCount > 0) { %>
                            <span class="dropdown-badge" id="dropdownMsgBadge"><%= unreadMessageCount %></span>
                        <% } %>
                    </a>
                    <a href="notifications" class="nav-notification-link">
                        <svg class="dropdown-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                        </svg>
                        Notifications
                        <% if (unreadCount > 0) { %>
                            <span class="dropdown-badge" id="dropdownNotifBadge"><%= unreadCount %></span>
                        <% } %>
                    </a>
                    <a href="logout" class="logout-link" style="border-top: 1px solid #f0f0f0; margin-top: 5px;">
                        <svg class="dropdown-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                            <polyline points="16 17 21 12 16 7"/>
                            <line x1="21" y1="12" x2="9" y2="12"/>
                        </svg>
                        Logout
                    </a>
                </div>
            </div>
        </div>
    </div>

    <div class="container">
        <div class="admin-warning">
            <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"/>
                <line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            <strong>Admin Mode Active</strong> | You are viewing all customer reviews | You can delete inappropriate reviews
        </div>

        <div class="header">
            <h1>
                <svg class="svg-icon" style="width:28px;height:28px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                </svg>
                All Customer Reviews
            </h1>

            <!-- SEARCH BAR -->
            <form action="reviews" method="get" class="search-container">
                <input type="hidden" name="action" value="admin">
                <span class="search-icon">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="11" cy="11" r="8"/>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                    </svg>
                </span>
                <input type="text"
                       name="search"
                       class="search-input"
                       placeholder="Search by customer name or product name..."
                       value="<%= searchKeyword != null ? searchKeyword : "" %>"
                       autocomplete="off">
                <button type="submit" class="search-btn">Search</button>
                <% if (isSearchResult) { %>
                    <a href="reviews?action=admin" class="clear-search">Clear</a>
                <% } %>
            </form>

            <div class="stats-card">
                Total Reviews: <%= reviewCount %>
            </div>
        </div>

        <!-- Search Info -->
        <% if (isSearchResult && searchKeyword != null && !searchKeyword.isEmpty()) { %>
            <div class="search-info">
                <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"/>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                Showing <strong><%= reviewCount %></strong> review(s) for "<strong><%= searchKeyword %></strong>"
            </div>
        <% } %>

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

        <div class="reviews-table">
            <% if (reviews != null && !reviews.isEmpty()) { %>
                <table>
                    <thead>
                        <tr>
                            <th>Product</th>
                            <th>Customer</th>
                            <th>Rating</th>
                            <th>Review</th>
                            <th>Date</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Review review : reviews) { %>
                            <tr>
                                <td>
                                    <div style="display: flex; align-items: center; gap: 0.5rem;">
                                        <div class="product-image">
                                            <img src="<%= review.getProductImageUrl() != null && !review.getProductImageUrl().isEmpty() ? "images/" + review.getProductImageUrl() : "images/default-toy.png" %>"
                                                 alt="<%= review.getProductName() %>"
                                                 onerror="this.parentElement.innerHTML='<div class=\'no-image\'><svg width=\'30\' height=\'30\' viewBox=\'0 0 24 24\' fill=\'none\' stroke=\'white\' stroke-width=\'2\'><circle cx=\'12\' cy=\'12\' r=\'10\'/><path d=\'M12 6a6 6 0 0 0-6 6 6 6 0 0 0 6 6 6 6 0 0 0 6-6 6 6 0 0 0-6-6z\'/><circle cx=\'12\' cy=\'12\' r=\'2\'/></svg></div>'">
                                        </div>
                                        <span><%= review.getProductName() %></span>
                                    </div>
                                </td>
                                <td><%= review.getDisplayName() %> (<%= review.getUserName() != null ? review.getUserName() : "N/A" %>)</td>
                                <td class="stars">
                                    <% for (int i = 1; i <= 5; i++) { %>
                                        <% if (i <= review.getRating()) { %>
                                            <svg class="star-filled" style="width:16px;height:16px;display:inline-block;" viewBox="0 0 24 24" fill="currentColor" stroke="none">
                                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                            </svg>
                                        <% } else { %>
                                            <svg class="star-empty" style="width:16px;height:16px;display:inline-block;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                            </svg>
                                        <% } %>
                                    <% } %>
                                </td>
                                <td class="review-comment"><%= review.getComment().length() > 100 ? review.getComment().substring(0, 97) + "..." : review.getComment() %></td>
                                <td><%= review.getCreatedAt() %></td>
                                <td>
                                    <button onclick="deleteReview(<%= review.getReviewId() %>, '<%= review.getProductName().replace("'", "\\'") %>')" class="delete-btn">
                                        <svg class="svg-icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <polyline points="3 6 5 6 21 6"/>
                                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                        </svg>
                                        Delete
                                    </button>
                                </td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } else { %>
                <div class="no-reviews">
                    <svg style="width:48px;height:48px;margin-bottom:1rem;color:#999;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                    </svg>
                    <p><%= isSearchResult ? "No reviews found matching \"" + searchKeyword + "\"" : "No reviews have been written by customers yet." %></p>
                    <% if (isSearchResult) { %>
                        <p style="margin-top: 10px;">Try searching with different keywords.</p>
                        <a href="reviews?action=admin" style="display: inline-block; margin-top: 15px; color: #667eea;">View all reviews →</a>
                    <% } else { %>
                        <p>When customers submit reviews, they will appear here.</p>
                    <% } %>
                </div>
            <% } %>
        </div>
    </div>

    <script>
        function deleteReview(reviewId, productName) {
            if (confirm('Are you sure you want to delete this review for "' + productName + '"?\n\nThis action cannot be undone and the user will be notified.')) {
                window.location.href = 'reviews?action=delete&id=' + reviewId;
            }
        }

        // Function to update notification count in dropdown
        function updateNotificationCount() {
            fetch('notifications?ajax=count')
                .then(response => response.json())
                .then(data => {
                    console.log('Notification count:', data.unreadCount);

                    // Update dropdown notification badge
                    const dropdownNotifBadge = document.getElementById('dropdownNotifBadge');
                    if (dropdownNotifBadge) {
                        if (data.unreadCount > 0) {
                            dropdownNotifBadge.textContent = data.unreadCount;
                            dropdownNotifBadge.style.display = 'inline-block';
                        } else {
                            dropdownNotifBadge.style.display = 'none';
                        }
                    } else {
                        // If badge doesn't exist, create it
                        const notificationsLink = document.querySelector('.dropdown-content a[href="notifications"]');
                        if (notificationsLink && data.unreadCount > 0) {
                            const badge = document.createElement('span');
                            badge.className = 'dropdown-badge';
                            badge.id = 'dropdownNotifBadge';
                            badge.textContent = data.unreadCount;
                            notificationsLink.appendChild(badge);
                        }
                    }
                })
                .catch(error => console.error('Error fetching notification count:', error));
        }

        // Function to update message count in dropdown
        function updateMessageCount() {
            fetch('messages?ajax=count')
                .then(response => response.json())
                .then(data => {
                    console.log('Message count:', data.unreadMessageCount);

                    // Update dropdown message badge
                    const dropdownMsgBadge = document.getElementById('dropdownMsgBadge');
                    if (dropdownMsgBadge) {
                        if (data.unreadMessageCount > 0) {
                            dropdownMsgBadge.textContent = data.unreadMessageCount;
                            dropdownMsgBadge.style.display = 'inline-block';
                        } else {
                            dropdownMsgBadge.style.display = 'none';
                        }
                    } else {
                        // If badge doesn't exist, create it
                        const messagesLink = document.querySelector('.dropdown-content a[href="messages"]');
                        if (messagesLink && data.unreadMessageCount > 0) {
                            const badge = document.createElement('span');
                            badge.className = 'dropdown-badge';
                            badge.id = 'dropdownMsgBadge';
                            badge.textContent = data.unreadMessageCount;
                            messagesLink.appendChild(badge);
                        }
                    }
                })
                .catch(error => console.error('Error fetching message count:', error));
        }

        // Update counts every 30 seconds
        setInterval(updateNotificationCount, 30000);
        setInterval(updateMessageCount, 30000);

        // Initial load
        updateNotificationCount();
        updateMessageCount();

        // Allow Enter key to submit search
        document.querySelector('.search-input')?.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                this.form.submit();
            }
        });
    </script>
</body>
</html>