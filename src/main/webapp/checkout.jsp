<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.toystore.model.CartItem, com.toystore.model.User" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Toy Store - Checkout</title>
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
        }

        .logo {
            font-size: 1.8rem;
            font-weight: bold;
            color: #667eea;
        }

        .container {
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 2rem;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
        }

        .checkout-form, .order-summary {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        h2 {
            margin-bottom: 1.5rem;
            color: #667eea;
        }

        .form-group {
            margin-bottom: 1rem;
        }

        label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 500;
        }

        input, select, textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-family: inherit;
        }

        input[readonly] {
            background: #f5f5f5;
            cursor: not-allowed;
        }

        small {
            display: block;
            margin-top: 5px;
            font-size: 0.85rem;
            color: #666;
        }

        .info-note {
            background: #e6fffa;
            padding: 10px;
            border-radius: 8px;
            margin-bottom: 1rem;
            font-size: 0.85rem;
            color: #234e52;
            border-left: 3px solid #38b2ac;
        }

        .info-note a {
            color: #667eea;
        }

        .order-item {
            padding: 0.5rem 0;
            border-bottom: 1px solid #eee;
        }

        .total {
            font-size: 1.3rem;
            font-weight: bold;
            margin-top: 1rem;
            text-align: right;
            color: #667eea;
        }

        .complete-payment {
            width: 100%;
            background: #48bb78;
            color: white;
            padding: 12px;
            border: none;
            border-radius: 5px;
            font-size: 1.1rem;
            cursor: pointer;
            margin-top: 1rem;
        }

        .complete-payment:hover {
            background: #38a169;
        }

        .error {
            background: #fee;
            color: #c33;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 1rem;
        }

        .svg-icon {
            width: 18px;
            height: 18px;
            vertical-align: middle;
            margin-right: 5px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        @media (max-width: 768px) {
            .container {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="logo">
            <svg class="svg-icon" style="width:24px;height:24px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"/>
                <path d="M12 6a6 6 0 0 0-6 6 6 6 0 0 0 6 6 6 6 0 0 0 6-6 6 6 0 0 0-6-6z"/>
                <circle cx="12" cy="12" r="2"/>
            </svg>
            ToyStore
        </div>
    </div>

    <div class="container">
        <div class="checkout-form">
            <h2>
                <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/>
                    <line x1="1" y1="10" x2="23" y2="10"/>
                </svg>
                Shipping Information
            </h2>

            <% if (request.getAttribute("error") != null) { %>
                <div class="error">
                    <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <%= request.getAttribute("error") %>
                </div>
            <% } %>

            <div class="info-note">
                <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="16" x2="12" y2="12"/>
                    <line x1="12" y1="8" x2="12.01" y2="8"/>
                </svg>
                Your address and contact number have been loaded from your
                <a href="profile">profile</a>. You can edit them below for this order only.
            </div>

            <form action="checkout" method="post">
                <div class="form-group">
                    <label>Full Name</label>
                    <input type="text" value="<%= ((User)request.getAttribute("user")).getFullName() %>" readonly>
                </div>

                <div class="form-group">
                    <label>Contact Number *</label>
                    <input type="tel" name="contactNumber"
                           value="<%= request.getAttribute("savedPhone") != null ? request.getAttribute("savedPhone") : "" %>"
                           placeholder="e.g., 0712345678 or 011-2345678" required>
                    <small>We'll use this to contact you about your order. Update your default number in <a href="profile">Profile</a></small>
                </div>

                <div class="form-group">
                    <label>Shipping Address *</label>
                    <textarea name="shippingAddress" rows="3" required><%= request.getAttribute("savedAddress") != null ? request.getAttribute("savedAddress") : "" %></textarea>
                    <small>Update your default address in <a href="profile">Profile</a></small>
                </div>

                <div class="form-group">
                    <label>Payment Method *</label>
                    <select name="paymentMethod" required>
                        <option value="">Select Payment Method</option>
                        <option value="Credit Card">Credit Card</option>
                        <option value="Debit Card">Debit Card</option>
                        <option value="PayPal">PayPal</option>
                        <option value="Cash on Delivery">Cash on Delivery</option>
                    </select>
                </div>

                <button type="submit" class="complete-payment">
                    <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20 6L9 17l-5-5"/>
                    </svg>
                    Complete Payment →
                </button>
            </form>
        </div>

        <div class="order-summary">
            <h2>
                <svg class="svg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                </svg>
                Order Summary
            </h2>
            <%
                List<CartItem> cartItems = (List<CartItem>) request.getAttribute("cartItems");
                Double total = (Double) request.getAttribute("total");
                if (cartItems != null) {
                    for (CartItem item : cartItems) {
            %>
                <div class="order-item">
                    <%= item.getQuantity() %>x <%= item.getProduct().getProductName() %>
                    - $<%= String.format("%.2f", item.getSubtotal()) %>
                </div>
            <%      }
                }
            %>
            <div class="total">Total: $<%= String.format("%.2f", total) %></div>
        </div>
    </div>
</body>
</html>