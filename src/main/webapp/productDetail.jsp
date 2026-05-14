<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.toystore.model.User, com.toystore.model.Product, com.toystore.model.Review, com.toystore.dao.ReviewDAO, com.toystore.dao.NotificationDAO, com.toystore.dao.ProductDAO, java.util.List, java.util.ArrayList" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    String loggedInUsername = (String) session.getAttribute("username");
    boolean isAdmin = (loggedInUser != null && loggedInUser.isAdmin());
    boolean isLoggedIn = (loggedInUser != null);

    if (loggedInUsername == null || loggedInUsername.isEmpty()) {
        loggedInUsername = "User";
    }

    // Get product from request attribute (set by servlet)
    Product product = (Product) request.getAttribute("product");
    List<Review> reviews = (List<Review>) request.getAttribute("reviews");
    Double averageRating = (Double) request.getAttribute("averageRating");
    Integer reviewCount = (Integer) request.getAttribute("reviewCount");

    if (product == null) {
        response.sendRedirect("products");
        return;
    }

    // Get unread counts
    int unreadCount = 0;
    int unreadMessageCount = 0;
    if (isLoggedIn) {
        NotificationDAO notifDAO = new NotificationDAO();
        unreadCount = notifDAO.getUnreadCount(loggedInUser.getUserId());
        com.toystore.dao.MessageDAO messageDAO = new com.toystore.dao.MessageDAO();
        unreadMessageCount = messageDAO.getUnreadCount(loggedInUser.getUserId());
    }

    // Get ONLY products from the same category for carousel (excluding current product)
    ProductDAO productDAO = new ProductDAO();
    List<Product> allProducts = productDAO.getAllProductsWithRatings();
    List<Product> sameCategoryProducts = new ArrayList<>();
    String currentCategory = product.getCategory();

    if (currentCategory != null && !currentCategory.isEmpty()) {
        for (Product p : allProducts) {
            if (p.getProductId() != product.getProductId() &&
                currentCategory.equals(p.getCategory())) {
                sameCategoryProducts.add(p);
            }
        }
    }

    // Only calculate slides if there are products in the same category
    int totalProducts = sameCategoryProducts.size();
    int itemsPerSlide = 4;
    int totalSlides = totalProducts > 0 ? (int) Math.ceil((double) totalProducts / itemsPerSlide) : 0;

    // Helper function to mask reviewer name
    java.util.function.Function<String, String> maskName = (fullName) -> {
        if (fullName == null || fullName.trim().isEmpty()) {
            return "Customer";
        }
        String name = fullName.trim();
        // If name is only 1 character
        if (name.length() == 1) {
            return name;
        }
        // If name is 2 characters
        if (name.length() == 2) {
            return name.charAt(0) + "*";
        }
        // For names with 3 or more characters: show first letter, then asterisks for middle, then last letter
        String firstChar = String.valueOf(name.charAt(0));
        String lastChar = String.valueOf(name.charAt(name.length() - 1));
        int asteriskCount = name.length() - 2;
        String asterisks = new String(new char[asteriskCount]).replace('\0', '*');
        return firstChar + asterisks + lastChar;
    };
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= product.getProductName() %> - ToyStore</title>
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
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 2rem;
        }

        .back-link {
            display: inline-block;
            margin-bottom: 1rem;
            color: #667eea;
            text-decoration: none;
        }

        .back-link:hover {
            text-decoration: underline;
        }

        .product-detail {
            background: white;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
            padding: 2rem;
        }

        .product-image {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            min-height: 300px;
        }

        .product-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .product-info h1 {
            font-size: 1.8rem;
            color: #333;
            margin-bottom: 0.5rem;
        }

        .product-price {
            font-size: 1.8rem;
            font-weight: bold;
            color: #667eea;
            margin: 1rem 0;
        }

        .product-description {
            color: #666;
            line-height: 1.6;
            margin-bottom: 1rem;
        }

        .product-stock {
            margin-bottom: 1rem;
            padding: 0.5rem;
            border-radius: 5px;
            display: inline-block;
        }

        .in-stock {
            background: #c6f6d5;
            color: #22543d;
        }

        .out-of-stock {
            background: #fed7d7;
            color: #742a2a;
        }

        .rating-summary {
            display: flex;
            align-items: center;
            gap: 1rem;
            margin: 1rem 0;
            padding: 1rem;
            background: #f7fafc;
            border-radius: 10px;
        }

        .average-rating {
            font-size: 2rem;
            font-weight: bold;
            color: #667eea;
        }

        .stars-large {
            font-size: 1.5rem;
        }

        .star-filled {
            color: #fbbf24;
        }

        .star-empty {
            color: #ddd;
        }

        .add-to-cart-section {
            margin-top: 1.5rem;
            padding-top: 1rem;
            border-top: 1px solid #eee;
        }

        .quantity-control {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 1rem;
        }

        .qty-btn {
            background: #e2e8f0;
            border: none;
            width: 36px;
            height: 36px;
            border-radius: 5px;
            font-size: 1.2rem;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
        }

        .qty-btn:hover {
            background: #cbd5e0;
        }

        .qty-input {
            width: 60px;
            text-align: center;
            padding: 8px;
            border: 1px solid #e2e8f0;
            border-radius: 5px;
            font-size: 1rem;
        }

        .add-to-cart-btn {
            background: #667eea;
            color: white;
            width: 100%;
            padding: 12px;
            border: none;
            border-radius: 5px;
            font-size: 1rem;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.3s;
        }

        .add-to-cart-btn:hover {
            background: #5a67d8;
        }

        .login-prompt {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 1rem;
        }

        /* Reviews Section */
        .reviews-section {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
        }

        .reviews-section h2 {
            color: #333;
            margin-bottom: 1.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .review-card {
            border-bottom: 1px solid #eee;
            padding: 1.5rem 0;
        }

        .review-card:last-child {
            border-bottom: none;
        }

        .review-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 0.75rem;
            flex-wrap: wrap;
            gap: 0.5rem;
        }

        .reviewer-name {
            font-weight: bold;
            color: #667eea;
        }

        .review-stars {
            display: flex;
            gap: 0.25rem;
        }

        .review-date {
            font-size: 0.75rem;
            color: #999;
        }

        .review-comment {
            color: #444;
            line-height: 1.5;
            white-space: pre-wrap;
            word-wrap: break-word;
        }

        .no-reviews {
            text-align: center;
            padding: 2rem;
            color: #666;
        }

        /* Carousel Section */
        .carousel-section {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .section-title {
            text-align: center;
            font-size: 1.8rem;
            color: #333;
            margin-bottom: 1.5rem;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
            flex-wrap: wrap;
        }

        .section-title span {
            color: #667eea;
        }

        .category-badge {
            background: #667eea;
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-left: 10px;
        }

        .carousel-container {
            position: relative;
            overflow: hidden;
            border-radius: 15px;
            background: #f8f9fa;
            padding: 2rem 0;
        }

        .carousel-track-container {
            overflow: hidden;
            position: relative;
        }

        .carousel-track {
            display: flex;
            transition: transform 0.5s ease-in-out;
            list-style: none;
            padding: 0;
            margin: 0;
        }

        .carousel-slide {
            flex: 0 0 100%;
            min-width: 0;
            padding: 0 2rem;
        }

        .carousel-content {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 1.5rem;
        }

        .carousel-item {
            background: white;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 3px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s, box-shadow 0.3s;
            text-align: center;
            padding: 1rem;
        }

        .carousel-item:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }

        .carousel-item-image {
            width: 100%;
            height: 180px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            margin-bottom: 1rem;
        }

        .carousel-item-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s;
        }

        .carousel-item:hover .carousel-item-image img {
            transform: scale(1.05);
        }

        .carousel-item-name {
            font-size: 1rem;
            font-weight: bold;
            color: #333;
            margin-bottom: 0.5rem;
        }

        .carousel-item-price {
            font-size: 1.2rem;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 0.5rem;
        }

        .carousel-item-stock {
            font-size: 0.8rem;
            color: #666;
            margin-bottom: 0.8rem;
        }

        .carousel-item-rating {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 0.25rem;
            margin-bottom: 0.8rem;
        }

        .carousel-item-stars {
            display: flex;
            gap: 0.1rem;
        }

        .carousel-star-filled {
            color: #fbbf24;
            font-size: 0.8rem;
        }

        .carousel-star-empty {
            color: #ddd;
            font-size: 0.8rem;
        }

        .view-detail-btn {
            display: inline-block;
            padding: 6px 15px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-size: 0.85rem;
            transition: background 0.3s;
        }

        .view-detail-btn:hover {
            background: #5a67d8;
        }

        .carousel-btn {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            background: rgba(102, 126, 234, 0.8);
            color: white;
            border: none;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 1.2rem;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s;
            z-index: 10;
        }

        .carousel-btn:hover {
            background: #667eea;
            transform: translateY(-50%) scale(1.1);
        }

        .carousel-btn-left { left: 10px; }
        .carousel-btn-right { right: 10px; }

        .carousel-dots {
            display: flex;
            justify-content: center;
            gap: 0.8rem;
            margin-top: 1.5rem;
        }

        .dot-btn {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: #cbd5e0;
            cursor: pointer;
            transition: all 0.3s;
            border: none;
        }

        .dot-btn.active {
            background: #667eea;
            transform: scale(1.2);
        }

        @media (max-width: 1024px) {
            .carousel-content {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 768px) {
            .navbar {
                flex-direction: column;
            }
            .product-detail {
                grid-template-columns: 1fr;
            }
            .dropdown-content {
                right: auto;
                left: 0;
            }
            .carousel-content {
                grid-template-columns: 1fr;
            }
            .carousel-btn {
                width: 35px;
                height: 35px;
                font-size: 1rem;
            }
            .section-title {
                font-size: 1.3rem;
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
                <a href="orders">All Orders</a>
                <a href="users">All Users</a>
                <div class="user-menu">
                    <button class="user-dropdown-btn">
                        <span class="welcome-text"><%= loggedInUsername %></span>
                        <span class="admin-badge">ADMIN</span>
                        <span class="dropdown-arrow">▼</span>
                    </button>
                    <div class="dropdown-content">
                        <a href="reviews?action=admin">All Reviews</a>
                        <a href="messages">Messages</a>
                        <a href="notifications">Notifications</a>
                        <a href="logout" class="logout-link">Logout</a>
                    </div>
                </div>
            <% } else if (isLoggedIn && !isAdmin) { %>
                <a href="cart" id="cartLink" style="position: relative;">
                    Cart
                    <span id="cartBadge" class="cart-badge" style="display: none;"></span>
                </a>
                <div class="user-menu">
                    <button class="user-dropdown-btn">
                        <span class="welcome-text"><%= loggedInUsername %></span>
                        <span class="dropdown-arrow">▼</span>
                    </button>
                    <div class="dropdown-content">
                        <a href="profile">My Profile</a>
                        <a href="orders">My Orders</a>
                        <a href="reviews">My Reviews</a>
                        <a href="messages">Contact Us</a>
                        <a href="notifications">Notifications</a>
                        <a href="logout" class="logout-link">Logout</a>
                    </div>
                </div>
            <% } else { %>
                <a href="login">Login</a>
                <a href="register">Register</a>
            <% } %>
        </div>
    </div>

    <div class="container">
        <a href="products" class="back-link">← Back to Products</a>

        <div class="product-detail">
            <div class="product-image">
                <img src="<%= product.getImagePath() %>"
                     alt="<%= product.getProductName() %>"
                     onerror="this.src='images/default-toy.png'">
            </div>
            <div class="product-info">
                <h1><%= product.getProductName() %></h1>
                <div class="product-price">$<%= String.format("%.2f", product.getPrice()) %></div>
                <div class="product-description">
                    <%= product.getDescription() != null ? product.getDescription().replace("\n", "<br>") : "No description available" %>
                </div>
                <div class="product-stock <%= product.getStockQuantity() > 0 ? "in-stock" : "out-of-stock" %>">
                    <% if (product.getStockQuantity() > 0) { %>
                        ✓ In Stock (<%= product.getStockQuantity() %> units available)
                    <% } else { %>
                        ✗ Out of Stock
                    <% } %>
                </div>

                <!-- Rating Summary -->
                <div class="rating-summary">
                    <div class="average-rating">
                        <%= String.format("%.1f", averageRating != null ? averageRating : 0) %>
                    </div>
                    <div class="stars-large">
                        <% if (averageRating != null && averageRating > 0) {
                            int fullStars = (int) Math.floor(averageRating);
                            boolean hasHalfStar = (averageRating - fullStars) >= 0.5;
                            for (int i = 1; i <= 5; i++) {
                                if (i <= fullStars) { %>
                                    <span class="star-filled">★</span>
                                <% } else if (hasHalfStar && i == fullStars + 1) { %>
                                    <span class="star-filled">½</span>
                                <% } else { %>
                                    <span class="star-empty">☆</span>
                                <% }
                            }
                        } else { %>
                            <% for (int i = 1; i <= 5; i++) { %>
                                <span class="star-empty">☆</span>
                            <% } %>
                        <% } %>
                    </div>
                    <div>
                        <%= reviewCount != null ? reviewCount : 0 %> <%= (reviewCount != null && reviewCount == 1) ? "review" : "reviews" %>
                    </div>
                </div>

                <!-- Add to Cart Section (for non-admin logged in users) -->
                <% if (isLoggedIn && !isAdmin && product.getStockQuantity() > 0) { %>
                    <div class="add-to-cart-section">
                        <div class="quantity-control">
                            <button type="button" class="qty-btn" onclick="updateQuantity(-1, <%= product.getStockQuantity() %>)">−</button>
                            <input type="number" id="quantity" class="qty-input" value="1" min="1" max="<%= product.getStockQuantity() %>">
                            <button type="button" class="qty-btn" onclick="updateQuantity(1, <%= product.getStockQuantity() %>)">+</button>
                        </div>
                        <form action="cart" method="post" onsubmit="return validateQuantity(<%= product.getStockQuantity() %>)">
                            <input type="hidden" name="action" value="add">
                            <input type="hidden" name="productId" value="<%= product.getProductId() %>">
                            <input type="hidden" name="quantity" id="hiddenQuantity" value="1">
                            <button type="submit" class="add-to-cart-btn">Add to Cart</button>
                        </form>
                    </div>
                <% } else if (!isLoggedIn) { %>
                    <a href="login" class="login-prompt">Login to Purchase</a>
                <% } else if (isAdmin) { %>
                    <div class="add-to-cart-section">
                        <button class="add-to-cart-btn" disabled style="background: #a0aec0; cursor: not-allowed;">Admin accounts cannot purchase</button>
                    </div>
                <% } else if (product.getStockQuantity() == 0) { %>
                    <div class="add-to-cart-section">
                        <button class="add-to-cart-btn" disabled style="background: #a0aec0; cursor: not-allowed;">Out of Stock</button>
                    </div>
                <% } %>
            </div>
        </div>

        <!-- Reviews Section - ALL USERS CAN SEE THIS (WITH MASKED REVIEWER NAMES) -->
        <div class="reviews-section">
            <h2>
                <svg style="width:24px;height:24px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                </svg>
                Customer Reviews
            </h2>

            <% if (reviews != null && !reviews.isEmpty()) { %>
                <% for (Review review : reviews) {
                    String maskedReviewerName = maskName.apply(review.getDisplayName());
                %>
                    <div class="review-card">
                        <div class="review-header">
                            <span class="reviewer-name">
                                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:4px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                    <circle cx="12" cy="7" r="4"/>
                                </svg>
                                <%= maskedReviewerName %>
                            </span>
                            <div class="review-stars">
                                <% for (int i = 1; i <= 5; i++) { %>
                                    <% if (i <= review.getRating()) { %>
                                        <span class="star-filled" style="font-size:1rem;">★</span>
                                    <% } else { %>
                                        <span class="star-empty" style="font-size:1rem;">☆</span>
                                    <% } %>
                                <% } %>
                            </div>
                            <span class="review-date">
                                <svg style="width:12px;height:12px;vertical-align:middle;margin-right:4px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <circle cx="12" cy="12" r="10"/>
                                    <polyline points="12 6 12 12 16 14"/>
                                </svg>
                                <%= review.getCreatedAt() %>
                            </span>
                        </div>
                        <div class="review-comment">
                            <%= review.getComment().replace("\n", "<br>") %>
                        </div>
                    </div>
                <% } %>
            <% } else { %>
                <div class="no-reviews">
                    <svg style="width:48px;height:48px;margin-bottom:1rem;color:#999;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                    </svg>
                    <p>No reviews yet for this product.</p>
                    <% if (isLoggedIn && !isAdmin) { %>
                        <p>Be the first to write a review after your order is delivered!</p>
                    <% } %>
                </div>
            <% } %>
        </div>

        <!-- Similar Products Carousel Section - ONLY SHOW IF THERE ARE SAME CATEGORY PRODUCTS -->
        <% if (totalProducts > 0) { %>
        <div class="carousel-section">
            <h2 class="section-title">
                <svg style="width:28px;height:28px;margin-right:8px;vertical-align:middle;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                </svg>
                <span>More in</span> <%= currentCategory != null ? currentCategory : "This Category" %>
            </h2>
            <div class="carousel-container" id="similarCarousel">
                <button class="carousel-btn carousel-btn-left" id="similarPrevBtn">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="15 18 9 12 15 6"/>
                    </svg>
                </button>
                <button class="carousel-btn carousel-btn-right" id="similarNextBtn">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"/>
                    </svg>
                </button>

                <div class="carousel-track-container">
                    <ul class="carousel-track" id="similarCarouselTrack">
                        <% for (int slideIdx = 0; slideIdx < totalSlides; slideIdx++) { %>
                            <li class="carousel-slide">
                                <div class="carousel-content">
                                    <%
                                        int startIdx = slideIdx * itemsPerSlide;
                                        int endIdx = Math.min(startIdx + itemsPerSlide, totalProducts);
                                        for (int i = startIdx; i < endIdx; i++) {
                                            Product similarProduct = sameCategoryProducts.get(i);
                                    %>
                                        <div class="carousel-item">
                                            <div class="carousel-item-image">
                                                <img src="<%= similarProduct.getImagePath() %>"
                                                     alt="<%= similarProduct.getProductName() %>"
                                                     onerror="this.onerror=null; this.src='images/default-toy.png'">
                                            </div>
                                            <div class="carousel-item-name"><%= similarProduct.getProductName() %></div>
                                            <div class="carousel-item-price">$<%= String.format("%.2f", similarProduct.getPrice()) %></div>

                                            <!-- Rating display for carousel item -->
                                            <div class="carousel-item-rating">
                                                <div class="carousel-item-stars">
                                                    <% if (similarProduct.getAverageRating() > 0) {
                                                        double avgRating = similarProduct.getAverageRating();
                                                        int fullStars = (int) avgRating;
                                                        for (int s = 1; s <= 5; s++) {
                                                            if (s <= fullStars) { %>
                                                                <span class="carousel-star-filled">★</span>
                                                            <% } else { %>
                                                                <span class="carousel-star-empty">☆</span>
                                                            <% }
                                                        }
                                                    } else { %>
                                                        <% for (int s = 1; s <= 5; s++) { %>
                                                            <span class="carousel-star-empty">☆</span>
                                                        <% } %>
                                                    <% } %>
                                                </div>
                                                <span style="font-size: 0.7rem; color: #666;">(<%= similarProduct.getReviewCount() %>)</span>
                                            </div>

                                            <div class="carousel-item-stock">
                                                <% if (similarProduct.getStockQuantity() > 0) { %>
                                                    <svg style="width:12px;height:12px;vertical-align:middle;margin-right:3px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                        <path d="M20 6L9 17l-5-5"/>
                                                    </svg>
                                                    In Stock
                                                <% } else { %>
                                                    <svg style="width:12px;height:12px;vertical-align:middle;margin-right:3px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                        <line x1="18" y1="6" x2="6" y2="18"/>
                                                        <line x1="6" y1="6" x2="18" y2="18"/>
                                                    </svg>
                                                    Out of Stock
                                                <% } %>
                                            </div>
                                            <a href="products?id=<%= similarProduct.getProductId() %>" class="view-detail-btn">
                                                View Details →
                                            </a>
                                        </div>
                                    <% } %>
                                </div>
                            </li>
                        <% } %>
                    </ul>
                </div>
            </div>

            <div class="carousel-dots" id="similarCarouselDots">
                <% for (int i = 0; i < totalSlides; i++) { %>
                    <button class="dot-btn <%= i == 0 ? "active" : "" %>" data-slide="<%= i %>"></button>
                <% } %>
            </div>
        </div>
        <% } %>
        <!-- No message shown when no same category products - carousel section is completely omitted -->
    </div>

    <script>
        let currentQuantity = 1;
        const maxStock = <%= product.getStockQuantity() %>;

        function updateQuantity(delta, maxStock) {
            currentQuantity = parseInt(document.getElementById('quantity').value) || 1;
            let newValue = currentQuantity + delta;
            if (newValue < 1) newValue = 1;
            if (newValue > maxStock) newValue = maxStock;
            document.getElementById('quantity').value = newValue;
            document.getElementById('hiddenQuantity').value = newValue;
        }

        function validateQuantity(maxStock) {
            let quantity = parseInt(document.getElementById('quantity').value) || 1;
            if (quantity < 1) {
                alert('Please select at least 1 item');
                return false;
            }
            if (quantity > maxStock) {
                alert('Only ' + maxStock + ' items available in stock');
                return false;
            }
            return true;
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

        setInterval(updateCartCount, 5000);
        updateCartCount();

        // ========== SIMILAR PRODUCTS CAROUSEL SCRIPT (SAME CATEGORY ONLY) ==========
        const track = document.getElementById('similarCarouselTrack');
        const slides = Array.from(track ? track.children : []);
        const nextBtn = document.getElementById('similarNextBtn');
        const prevBtn = document.getElementById('similarPrevBtn');
        const dotsNav = document.getElementById('similarCarouselDots');
        const dots = Array.from(dotsNav ? dotsNav.children : []);

        if (slides.length > 0) {
            let currentIndex = 0;
            let autoSlideInterval;

            const slideWidth = slides[0].getBoundingClientRect().width;

            const setSlidePosition = (slide, index) => {
                slide.style.left = slideWidth * index + 'px';
            };
            slides.forEach(setSlidePosition);

            const moveToSlide = (track, currentSlide, targetSlide, targetIndex) => {
                track.style.transform = 'translateX(-' + targetSlide.style.left + ')';
                currentSlide.classList.remove('current-slide');
                targetSlide.classList.add('current-slide');
                currentIndex = targetIndex;
                updateDots(targetIndex);
            };

            const updateDots = (currentIndex) => {
                if (dots) {
                    dots.forEach((dot, index) => {
                        dot.classList.toggle('active', index === currentIndex);
                    });
                }
            };

            const updateButtons = () => {
                if (prevBtn) {
                    prevBtn.style.opacity = currentIndex === 0 ? '0.5' : '1';
                    prevBtn.disabled = currentIndex === 0;
                }
                if (nextBtn) {
                    nextBtn.style.opacity = currentIndex === slides.length - 1 ? '0.5' : '1';
                    nextBtn.disabled = currentIndex === slides.length - 1;
                }
            };

            const goToNextSlide = () => {
                if (currentIndex < slides.length - 1) {
                    const currentSlide = slides[currentIndex];
                    const nextSlide = slides[currentIndex + 1];
                    moveToSlide(track, currentSlide, nextSlide, currentIndex + 1);
                    updateButtons();
                } else {
                    const currentSlide = slides[currentIndex];
                    const firstSlide = slides[0];
                    moveToSlide(track, currentSlide, firstSlide, 0);
                    updateButtons();
                }
            };

            const goToPrevSlide = () => {
                if (currentIndex > 0) {
                    const currentSlide = slides[currentIndex];
                    const prevSlide = slides[currentIndex - 1];
                    moveToSlide(track, currentSlide, prevSlide, currentIndex - 1);
                    updateButtons();
                } else {
                    const currentSlide = slides[currentIndex];
                    const lastSlide = slides[slides.length - 1];
                    moveToSlide(track, currentSlide, lastSlide, slides.length - 1);
                    updateButtons();
                }
            };

            const startAutoSlide = () => {
                autoSlideInterval = setInterval(goToNextSlide, 5000);
            };

            const stopAutoSlide = () => {
                clearInterval(autoSlideInterval);
            };

            if (nextBtn) nextBtn.addEventListener('click', () => {
                stopAutoSlide();
                goToNextSlide();
                startAutoSlide();
            });

            if (prevBtn) prevBtn.addEventListener('click', () => {
                stopAutoSlide();
                goToPrevSlide();
                startAutoSlide();
            });

            if (dotsNav) {
                dotsNav.addEventListener('click', (e) => {
                    const targetDot = e.target.closest('.dot-btn');
                    if (!targetDot) return;

                    stopAutoSlide();
                    const targetIndex = parseInt(targetDot.getAttribute('data-slide'));
                    const currentSlide = slides[currentIndex];
                    const targetSlide = slides[targetIndex];
                    moveToSlide(track, currentSlide, targetSlide, targetIndex);
                    updateButtons();
                    startAutoSlide();
                });
            }

            const carouselContainer = document.getElementById('similarCarousel');
            if (carouselContainer) {
                carouselContainer.addEventListener('mouseenter', stopAutoSlide);
                carouselContainer.addEventListener('mouseleave', startAutoSlide);
            }

            slides[0].classList.add('current-slide');
            updateButtons();
            startAutoSlide();

            window.addEventListener('resize', () => {
                const newSlideWidth = slides[0].getBoundingClientRect().width;
                slides.forEach((slide, index) => {
                    slide.style.left = newSlideWidth * index + 'px';
                });
                const currentSlide = slides[currentIndex];
                track.style.transform = 'translateX(-' + currentSlide.style.left + ')';
            });
        }
    </script>
</body>
</html>