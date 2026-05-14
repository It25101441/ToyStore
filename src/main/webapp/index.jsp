<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.toystore.model.User, com.toystore.dao.ProductDAO, com.toystore.model.Product, com.toystore.dao.NotificationDAO, java.util.List" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    String loggedInUsername = (String) session.getAttribute("username");
    boolean isAdmin = (loggedInUser != null && loggedInUser.isAdmin());
    boolean isLoggedIn = (loggedInUser != null);

    if (loggedInUsername == null || loggedInUsername.isEmpty()) {
        loggedInUsername = "User";
    }

    // Get unread notification count
    int unreadCount = 0;
    int unreadMessageCount = 0;
    if (isLoggedIn) {
        NotificationDAO notifDAO = new NotificationDAO();
        unreadCount = notifDAO.getUnreadCount(loggedInUser.getUserId());

        // Get unread message count
        com.toystore.dao.MessageDAO messageDAO = new com.toystore.dao.MessageDAO();
        unreadMessageCount = messageDAO.getUnreadCount(loggedInUser.getUserId());
    }

    // Fetch products for carousel
    ProductDAO productDAO = new ProductDAO();
    List<Product> allProducts = productDAO.getAllProducts();
    List<Product> featuredProducts = allProducts;
    if (allProducts.size() > 8) {
        featuredProducts = allProducts.subList(0, 8);
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Toy Store - Home</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .navbar {
            background: rgba(255, 255, 255, 0.95);
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
            animation: bounce 0.5s ease;
        }

        @keyframes bounce {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.2); }
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

        /* Hero Slideshow Section */
        .hero-slideshow {
            position: relative;
            height: 85vh;
            overflow: hidden;
        }

        .hero-slide {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
            opacity: 0;
            transition: opacity 1.5s ease-in-out;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            color: white;
        }

        .hero-slide.active {
            opacity: 1;
        }

        .hero-slide1 { background-image: linear-gradient(rgba(0,0,0,0.4), rgba(0,0,0,0.4)), url('https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=1920&h=800&fit=crop'); }
        .hero-slide3 { background-image: linear-gradient(rgba(0,0,0,0.4), rgba(0,0,0,0.4)), url('https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=1920&h=800&fit=crop'); }
        .hero-slide4 { background-image: linear-gradient(rgba(0,0,0,0.4), rgba(0,0,0,0.4)), url('https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?w=1920&h=800&fit=crop'); }

        .hero-content {
            max-width: 800px;
            padding: 2rem;
            background: rgba(0,0,0,0.3);
            border-radius: 20px;
            backdrop-filter: blur(5px);
            animation: fadeInUp 0.8s ease;
        }

        .hero-content h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
        }

        .hero-content p {
            font-size: 1.2rem;
            margin-bottom: 2rem;
        }

        .hero-btn {
            display: inline-block;
            padding: 12px 30px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 50px;
            font-weight: bold;
            transition: transform 0.3s, box-shadow 0.3s;
            margin: 0 10px;
        }

        .hero-btn:hover {
            transform: translateY(-3px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.3);
            background: #5a67d8;
        }

        .hero-btn-outline {
            background: transparent;
            border: 2px solid white;
        }

        .hero-btn-outline:hover {
            background: white;
            color: #667eea;
        }

        .hero-dots {
            position: absolute;
            bottom: 20px;
            left: 0;
            right: 0;
            text-align: center;
            z-index: 10;
        }

        .hero-dot {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: rgba(255,255,255,0.5);
            margin: 0 5px;
            cursor: pointer;
            transition: all 0.3s;
            border: none;
        }

        .hero-dot.active {
            background: #667eea;
            transform: scale(1.2);
        }

        .hero-arrow {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            background: rgba(102, 126, 234, 0.7);
            color: white;
            border: none;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 1.5rem;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s;
            z-index: 10;
        }

        .hero-arrow:hover {
            background: #667eea;
            transform: translateY(-50%) scale(1.1);
        }

        .hero-arrow-left { left: 20px; }
        .hero-arrow-right { right: 20px; }

        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* Product Carousel Section */
        .carousel-section {
            padding: 4rem 2rem;
            background: white;
        }

        .section-title {
            text-align: center;
            font-size: 2rem;
            color: #333;
            margin-bottom: 2rem;
        }

        .section-title span {
            color: #667eea;
        }

        .carousel-container {
            max-width: 1200px;
            margin: 0 auto;
            position: relative;
            overflow: hidden;
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
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

        .view-btn {
            display: inline-block;
            padding: 6px 15px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-size: 0.85rem;
            transition: background 0.3s;
        }

        .view-btn:hover {
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

        /* Features Section */
        .features {
            background: #f8f9fa;
            padding: 4rem 2rem;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 2rem;
            max-width: 1200px;
            margin: 0 auto;
        }

        .feature {
            text-align: center;
            padding: 2rem;
            transition: transform 0.3s;
        }

        .feature:hover {
            transform: translateY(-5px);
        }

        .feature h3 {
            color: #667eea;
            margin-bottom: 1rem;
        }

        /* About Section */
        .about-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 5rem 2rem;
            text-align: center;
        }

        .about-container {
            max-width: 1000px;
            margin: 0 auto;
        }

        .about-container h2 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
        }

        .about-container p {
            font-size: 1.1rem;
            line-height: 1.8;
            margin-bottom: 2rem;
            opacity: 0.95;
        }

        .about-stats {
            display: flex;
            justify-content: center;
            gap: 3rem;
            flex-wrap: wrap;
            margin-top: 2rem;
        }

        .stat {
            text-align: center;
        }

        .stat-number {
            font-size: 2rem;
            font-weight: bold;
        }

        .stat-label {
            font-size: 0.9rem;
            opacity: 0.9;
        }

        /* Footer */
        .footer {
            background: #1a202c;
            color: #cbd5e0;
            padding: 3rem 2rem 1.5rem;
            margin-top: auto;
        }

        .footer-content {
            max-width: 1200px;
            margin: 0 auto;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 2rem;
            margin-bottom: 2rem;
        }

        .footer-section h3 {
            color: white;
            margin-bottom: 1rem;
            font-size: 1.2rem;
        }

        .footer-section p {
            line-height: 1.6;
            font-size: 0.9rem;
        }

        .footer-section a {
            color: #cbd5e0;
            text-decoration: none;
        }

        .footer-section a:hover {
            color: #667eea;
        }

        .social-links {
            display: flex;
            gap: 1rem;
            margin-top: 1rem;
        }

        .social-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 40px;
            height: 40px;
            background: #2d3748;
            color: white;
            border-radius: 50%;
            text-decoration: none;
            transition: all 0.3s;
            font-size: 1.2rem;
        }

        .social-btn:hover {
            transform: translateY(-3px);
        }

        .social-btn.facebook:hover { background: #1877f2; }
        .social-btn.twitter:hover { background: #1da1f2; }
        .social-btn.instagram:hover { background: #e4405f; }
        .social-btn.youtube:hover { background: #ff0000; }

        .footer-bottom {
            text-align: center;
            padding-top: 1.5rem;
            border-top: 1px solid #2d3748;
            font-size: 0.85rem;
        }

        .nav-icon, .hero-icon, .feature-icon, .stat-icon, .social-icon, .dropdown-icon {
            width: 20px;
            height: 20px;
            vertical-align: middle;
            display: inline-block;
            stroke-width: 1.5;
            stroke: currentColor;
            fill: none;
        }
        .nav-icon-large, .hero-icon-large, .feature-icon-large {
            width: 32px;
            height: 32px;
            vertical-align: middle;
            stroke-width: 1.5;
        }
        .footer-icon {
            width: 20px;
            height: 20px;
            vertical-align: middle;
            margin-right: 5px;
            fill: none;
            stroke: currentColor;
            stroke-width: 1.5;
        }
        .social-icon {
            width: 20px;
            height: 20px;
            fill: currentColor;
            stroke: none;
        }
        .no-image {
            font-size: 1.8rem;
        }
        .product-image .no-image, .carousel-item-image .no-image {
            font-size: 2rem;
        }

        @media (max-width: 1024px) {
            .carousel-content {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 768px) {
            .hero-content h1 {
                font-size: 1.8rem;
            }
            .hero-content p {
                font-size: 1rem;
            }
            .navbar {
                flex-direction: column;
            }
            .nav-links {
                justify-content: center;
            }
            .carousel-content {
                grid-template-columns: 1fr;
            }
            .carousel-btn {
                width: 35px;
                height: 35px;
                font-size: 1rem;
            }
            .hero-arrow {
                width: 35px;
                height: 35px;
                font-size: 1rem;
            }
            .about-stats {
                gap: 1.5rem;
            }
            .footer-content {
                grid-template-columns: 1fr;
                text-align: center;
            }
            .social-links {
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
                <svg class="nav-icon-large" style="width:28px;height:28px;margin-right:5px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
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

    <!-- Hero Slideshow Section -->
    <div class="hero-slideshow">
        <button class="hero-arrow hero-arrow-left" id="heroPrevBtn">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="15 18 9 12 15 6"/>
            </svg>
        </button>
        <button class="hero-arrow hero-arrow-right" id="heroNextBtn">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="9 18 15 12 9 6"/>
            </svg>
        </button>

        <div class="hero-slide hero-slide1 active">
            <div class="hero-content">
                <h1>Welcome to ToyStore</h1>
                <p>Where every child's dream comes true! Discover the magic of play.</p>
                <div>
                    <a href="products" class="hero-btn">
                        <svg class="hero-icon-large" style="width:20px;height:20px;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="9" cy="21" r="1"/>
                            <circle cx="20" cy="21" r="1"/>
                            <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                        </svg>
                        Shop Now →
                    </a>
                    <% if (!isLoggedIn) { %>
                        <a href="register" class="hero-btn hero-btn-outline">
                            <svg class="hero-icon-large" style="width:20px;height:20px;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
                                <circle cx="9" cy="7" r="4"/>
                                <line x1="19" y1="8" x2="19" y2="14"/>
                                <line x1="22" y1="11" x2="16" y2="11"/>
                            </svg>
                            Sign Up →
                        </a>
                    <% } %>
                </div>
            </div>
        </div>
        <div class="hero-slide hero-slide3">
            <div class="hero-content">
                <h1>Free Shipping Worldwide</h1>
                <p>Free delivery on orders over $50. 30-day money-back guarantee!</p>
                <div>
                    <a href="products" class="hero-btn">
                        <svg class="hero-icon-large" style="width:20px;height:20px;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="9" cy="21" r="1"/>
                            <circle cx="20" cy="21" r="1"/>
                            <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                        </svg>
                        Start Shopping →
                    </a>
                </div>
            </div>
        </div>
        <div class="hero-slide hero-slide4">
            <div class="hero-content">
                <h1>Big Holiday Sale!</h1>
                <p>Up to 50% off on selected toys. Limited time offer!</p>
                <div>
                    <a href="products" class="hero-btn">
                        <svg class="hero-icon-large" style="width:20px;height:20px;margin-right:8px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="9" cy="21" r="1"/>
                            <circle cx="20" cy="21" r="1"/>
                            <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                        </svg>
                        Grab the Deal →
                    </a>
                </div>
            </div>
        </div>

        <div class="hero-dots" id="heroDots">
            <button class="hero-dot active" data-slide="0"></button>
            <button class="hero-dot" data-slide="1"></button>
            <button class="hero-dot" data-slide="2"></button>
        </div>
    </div>

    <!-- Auto-Sliding Product Carousel Section -->
    <div class="carousel-section">
        <h2 class="section-title">
            <svg class="hero-icon-large" style="width:32px;height:32px;margin-right:8px;vertical-align:middle;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
            <span>Featured</span> Products
            <svg class="hero-icon-large" style="width:32px;height:32px;margin-left:8px;vertical-align:middle;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
        </h2>
        <div class="carousel-container">
            <button class="carousel-btn carousel-btn-left" id="prevBtn">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="15 18 9 12 15 6"/>
                </svg>
            </button>
            <button class="carousel-btn carousel-btn-right" id="nextBtn">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="9 18 15 12 9 6"/>
                </svg>
            </button>

            <div class="carousel-track-container">
                <ul class="carousel-track" id="carouselTrack">
                    <%
                        int itemsPerSlide = 4;
                        int totalProducts = featuredProducts.size();
                        int totalSlides = (int) Math.ceil((double) totalProducts / itemsPerSlide);

                        if (totalProducts > 0) {
                            for (int slideIdx = 0; slideIdx < totalSlides; slideIdx++) {
                    %>
                        <li class="carousel-slide">
                            <div class="carousel-content">
                                <%
                                    int startIdx = slideIdx * itemsPerSlide;
                                    int endIdx = Math.min(startIdx + itemsPerSlide, totalProducts);
                                    for (int i = startIdx; i < endIdx; i++) {
                                        Product product = featuredProducts.get(i);
                                %>
                                    <div class="carousel-item">
                                        <div class="carousel-item-image">
                                            <img src="<%= product.getImagePath() %>"
                                                 alt="<%= product.getProductName() %>"
                                                 onerror="this.onerror=null; this.src='images/default-toy.png'">
                                        </div>
                                        <div class="carousel-item-name"><%= product.getProductName() %></div>
                                        <div class="carousel-item-price">$<%= String.format("%.2f", product.getPrice()) %></div>
                                        <div class="carousel-item-stock">
                                            <% if (product.getStockQuantity() > 0) { %>
                                                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:3px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                    <path d="M20 6L9 17l-5-5"/>
                                                </svg>
                                                In Stock
                                            <% } else { %>
                                                <svg style="width:14px;height:14px;vertical-align:middle;margin-right:3px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                    <line x1="18" y1="6" x2="6" y2="18"/>
                                                    <line x1="6" y1="6" x2="18" y2="18"/>
                                                </svg>
                                                Out of Stock
                                            <% } %>
                                        </div>
                                        <a href="products" class="view-btn">
                                            View Details →
                                        </a>
                                    </div>
                                <% } %>
                            </div>
                        </li>
                    <%
                            }
                        } else {
                    %>
                        <li class="carousel-slide">
                            <div class="carousel-content">
                                <div style="text-align: center; grid-column: 1/-1; padding: 40px;">
                                    <p>No products available at the moment.</p>
                                </div>
                            </div>
                        </li>
                    <% } %>
                </ul>
            </div>
        </div>

        <% if (totalProducts > 0) { %>
        <div class="carousel-dots" id="carouselDots">
            <% for (int i = 0; i < totalSlides; i++) { %>
                <button class="dot-btn <%= i == 0 ? "active" : "" %>" data-slide="<%= i %>"></button>
            <% } %>
        </div>
        <% } %>
    </div>

    <!-- Features Section -->
    <div class="features">
        <div class="feature">
            <svg class="feature-icon-large" style="width:48px;height:48px;margin-bottom:1rem;" viewBox="0 0 24 24" fill="none" stroke="#667eea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
            <h3>Premium Quality</h3>
            <p>Safe, durable, and high-quality toys for all ages</p>
        </div>
        <div class="feature">
            <svg class="feature-icon-large" style="width:48px;height:48px;margin-bottom:1rem;" viewBox="0 0 24 24" fill="none" stroke="#667eea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/>
                <line x1="1" y1="10" x2="23" y2="10"/>
            </svg>
            <h3>Free Shipping</h3>
            <p>Free delivery on orders over $50</p>
        </div>
        <div class="feature">
            <svg class="feature-icon-large" style="width:48px;height:48px;margin-bottom:1rem;" viewBox="0 0 24 24" fill="none" stroke="#667eea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/>
                <circle cx="7" cy="18" r="2"/>
                <circle cx="17" cy="18" r="2"/>
            </svg>
            <h3>Secure Payment</h3>
            <p>Multiple payment options with secure checkout</p>
        </div>
        <div class="feature">
            <svg class="feature-icon-large" style="width:48px;height:48px;margin-bottom:1rem;" viewBox="0 0 24 24" fill="none" stroke="#667eea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 12h18"/>
                <path d="M12 3v18"/>
                <circle cx="12" cy="12" r="9"/>
            </svg>
            <h3>Easy Returns</h3>
            <p>30-day money-back guarantee</p>
        </div>
    </div>

    <!-- About Section -->
    <div class="about-section">
        <div class="about-container">
            <h2>
                <svg class="hero-icon-large" style="width:36px;height:36px;margin-right:10px;vertical-align:middle;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
                </svg>
                About ToyStore
            </h2>
            <p>
                ToyStore was founded in 2020 with a simple mission: to bring joy and learning to children everywhere through high-quality, safe, and innovative toys.
                We believe that play is essential for child development, and every toy we offer is carefully selected to inspire creativity, imagination, and fun.
            </p>
            <p>
                From educational building blocks to cuddly stuffed animals, our collection is curated to ensure the best experience for both children and parents.
                Customer satisfaction is our top priority, and we're committed to providing excellent service, fast shipping, and a seamless shopping experience.
            </p>
            <div class="about-stats">
                <div class="stat">
                    <div class="stat-number">5000+</div>
                    <div class="stat-label">Happy Customers</div>
                </div>
                <div class="stat">
                    <div class="stat-number">200+</div>
                    <div class="stat-label">Toys Available</div>
                </div>
                <div class="stat">
                    <div class="stat-number">50+</div>
                    <div class="stat-label">Countries Shipped</div>
                </div>
                <div class="stat">
                    <div class="stat-number">98%</div>
                    <div class="stat-label">Satisfaction Rate</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Footer -->
    <div class="footer">
        <div class="footer-content">
            <div class="footer-section">
                <h3>
                    <svg class="footer-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <path d="M12 6a6 6 0 0 0-6 6 6 6 0 0 0 6 6 6 6 0 0 0 6-6 6 6 0 0 0-6-6z"/>
                        <circle cx="12" cy="12" r="2"/>
                    </svg>
                    ToyStore
                </h3>
                <p>Bringing joy to children worldwide with premium quality toys. Safe, fun, and educational toys for all ages.</p>
            </div>
            <div class="footer-section">
                <h3>Quick Links</h3>
                <p><a href="index.jsp">Home</a><br>
                <a href="products">Products</a><br>
                <a href="profile">My Profile</a><br>
                <a href="cart">Cart</a><br>
                <a href="orders">Orders</a><br>
                <a href="reviews">My Reviews</a><br>
                <a href="messages">Contact Us</a><br>
                <a href="notifications">Notifications</a></p>
            </div>
            <div class="footer-section">
                <h3>Contact Us</h3>
                <p>
                    <svg class="footer-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                        <polyline points="22,6 12,13 2,6"/>
                    </svg>
                    support@toystore.com<br>
                    <svg class="footer-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="5" y="2" width="14" height="20" rx="2" ry="2"/>
                        <line x1="12" y1="18" x2="12" y2="18"/>
                    </svg>
                    +1 (555) 123-4567<br>
                    <svg class="footer-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                        <circle cx="12" cy="10" r="3"/>
                    </svg>
                    123 Toy Street, Kidsville, KV 12345
                </p>
            </div>
            <div class="footer-section">
                <h3>Follow Us</h3>
                <div class="social-links">
                    <a href="https://facebook.com" target="_blank" class="social-btn facebook">
                        <svg class="social-icon" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/>
                        </svg>
                    </a>
                    <a href="https://x.com" target="_blank" class="social-btn twitter">
                        <svg class="social-icon" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M23 3a10.9 10.9 0 0 1-3.14 1.53 4.48 4.48 0 0 0-7.86 3v1A10.66 10.66 0 0 1 3 4s-4 9 5 13a11.64 11.64 0 0 1-7 2c9 5 20 0 20-11.5a4.5 4.5 0 0 0-.08-.83A7.72 7.72 0 0 0 23 3z"/>
                        </svg>
                    </a>
                    <a href="https://instagram.com" target="_blank" class="social-btn instagram">
                        <svg class="social-icon" viewBox="0 0 24 24" fill="currentColor">
                            <rect x="2" y="2" width="20" height="20" rx="5" ry="5"/>
                            <circle cx="12" cy="12" r="4"/>
                            <line x1="18" y1="6" x2="18" y2="6"/>
                        </svg>
                    </a>
                    <a href="https://youtube.com" target="_blank" class="social-btn youtube">
                        <svg class="social-icon" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M22.54 6.42a2.78 2.78 0 0 0-1.94-2C18.88 4 12 4 12 4s-6.88 0-8.6.46a2.78 2.78 0 0 0-1.94 2A29 29 0 0 0 1 11.75a29 29 0 0 0 .46 5.33A2.78 2.78 0 0 0 3.4 19c1.72.46 8.6.46 8.6.46s6.88 0 8.6-.46a2.78 2.78 0 0 0 1.94-2 29 29 0 0 0 .46-5.25 29 29 0 0 0-.46-5.33z"/>
                            <polygon points="9.75 15.02 15.5 11.75 9.75 8.48 9.75 15.02"/>
                        </svg>
                    </a>
                </div>
            </div>
        </div>
        <div class="footer-bottom">
            <p>&copy; 2026 ToyStore. All rights reserved. | Designed by ToyStore Team</p>
        </div>
    </div>

    <script>
        // ========== HERO SLIDESHOW SCRIPT ==========
        const heroSlides = document.querySelectorAll('.hero-slide');
        const heroDots = document.querySelectorAll('.hero-dot');
        const heroPrevBtn = document.getElementById('heroPrevBtn');
        const heroNextBtn = document.getElementById('heroNextBtn');

        let heroCurrentIndex = 0;
        let heroAutoSlideInterval;

        function showHeroSlide(n) {
            heroSlides.forEach(slide => slide.classList.remove('active'));
            heroDots.forEach(dot => dot.classList.remove('active'));

            heroCurrentIndex = (n + heroSlides.length) % heroSlides.length;
            heroSlides[heroCurrentIndex].classList.add('active');
            heroDots[heroCurrentIndex].classList.add('active');
        }

        function nextHeroSlide() {
            showHeroSlide(heroCurrentIndex + 1);
        }

        function prevHeroSlide() {
            showHeroSlide(heroCurrentIndex - 1);
        }

        function startHeroAutoSlide() {
            heroAutoSlideInterval = setInterval(nextHeroSlide, 5000);
        }

        function stopHeroAutoSlide() {
            clearInterval(heroAutoSlideInterval);
        }

        heroNextBtn.addEventListener('click', () => {
            stopHeroAutoSlide();
            nextHeroSlide();
            startHeroAutoSlide();
        });

        heroPrevBtn.addEventListener('click', () => {
            stopHeroAutoSlide();
            prevHeroSlide();
            startHeroAutoSlide();
        });

        heroDots.forEach((dot, index) => {
            dot.addEventListener('click', () => {
                stopHeroAutoSlide();
                showHeroSlide(index);
                startHeroAutoSlide();
            });
        });

        const heroSlideshow = document.querySelector('.hero-slideshow');
        heroSlideshow.addEventListener('mouseenter', stopHeroAutoSlide);
        heroSlideshow.addEventListener('mouseleave', startHeroAutoSlide);
        startHeroAutoSlide();

        // ========== PRODUCT CAROUSEL SCRIPT ==========
        const track = document.getElementById('carouselTrack');
        const slides = Array.from(track ? track.children : []);
        const nextBtn = document.getElementById('nextBtn');
        const prevBtn = document.getElementById('prevBtn');
        const dotsNav = document.getElementById('carouselDots');
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
                autoSlideInterval = setInterval(goToNextSlide, 4000);
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

            const carouselContainer = document.querySelector('.carousel-container');
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

        // ========== CART COUNT UPDATE ==========
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

        // ========== NOTIFICATION AND MESSAGE COUNT UPDATE ==========
        function updateNotificationCount() {
            fetch('notifications?ajax=count')
                .then(response => response.json())
                .then(data => {
                    console.log('Notification count:', data.unreadCount);

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
                    } else {
                        const dropdownNotifications = document.getElementById('dropdownNotifications');
                        if (dropdownNotifications && data.unreadCount > 0) {
                            const existingBadge = dropdownNotifications.querySelector('.dropdown-badge');
                            if (!existingBadge) {
                                const badge = document.createElement('span');
                                badge.className = 'dropdown-badge';
                                badge.id = 'dropdownNotifBadge';
                                badge.textContent = data.unreadCount;
                                dropdownNotifications.appendChild(badge);
                            }
                        }
                    }
                })
                .catch(error => console.error('Error fetching notification count:', error));
        }

        function updateMessageCount() {
            fetch('messages?ajax=count')
                .then(response => response.json())
                .then(data => {
                    console.log('Message count:', data.unreadMessageCount);

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
                    } else {
                        const dropdownMessages = document.getElementById('dropdownMessages');
                        if (dropdownMessages && data.unreadMessageCount > 0) {
                            const existingBadge = dropdownMessages.querySelector('.dropdown-badge');
                            if (!existingBadge) {
                                const badge = document.createElement('span');
                                badge.className = 'dropdown-badge';
                                badge.id = 'dropdownMsgBadge';
                                badge.textContent = data.unreadMessageCount;
                                dropdownMessages.appendChild(badge);
                            }
                        }
                    }
                })
                .catch(error => console.error('Error fetching message count:', error));
        }

        // Update counts every 5 seconds for cart, 30 seconds for notifications
        setInterval(updateCartCount, 5000);
        setInterval(updateNotificationCount, 30000);
        setInterval(updateMessageCount, 30000);

        // Initial loads
        updateCartCount();
        updateNotificationCount();
        updateMessageCount();
    </script>
</body>
</html>