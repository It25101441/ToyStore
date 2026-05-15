package com.toystore.servlet;

import com.toystore.dao.CartDAO;
import com.toystore.dao.OrderDAO;
import com.toystore.dao.UserDAO;
import com.toystore.model.CartItem;
import com.toystore.model.Order;
import com.toystore.model.OrderItem;
import com.toystore.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/checkout")
public class CheckoutServlet extends HttpServlet {

    private CartDAO cartDAO = new CartDAO();
    private OrderDAO orderDAO = new OrderDAO();
    private UserDAO userDAO = new UserDAO();

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && user.isAdmin();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect("login");
            return;
        }

        if (isAdmin(session)) {
            session.setAttribute("errorMessage", "Admin accounts cannot checkout.");
            response.sendRedirect("products");
            return;
        }

        List<CartItem> cartItems = cartDAO.getCartItems(userId);

        if (cartItems.isEmpty()) {
            response.sendRedirect("cart");
            return;
        }

        double total = 0;
        for (CartItem item : cartItems) {
            total += item.getSubtotal();
        }

        User user = userDAO.getUserById(userId);

        // Set user's saved address and phone for auto-fill in checkout form
        String savedAddress = user.getAddress();
        String savedPhone = user.getPhone();

        // If address or phone is null, set empty string to avoid null in JSP
        if (savedAddress == null) savedAddress = "";
        if (savedPhone == null) savedPhone = "";

        request.setAttribute("savedAddress", savedAddress);
        request.setAttribute("savedPhone", savedPhone);
        request.setAttribute("cartItems", cartItems);
        request.setAttribute("total", total);
        request.setAttribute("user", user);

        System.out.println("=== CheckoutServlet doGet ===");
        System.out.println("User ID: " + userId);
        System.out.println("Saved Address: " + (savedAddress.isEmpty() ? "(not set)" : savedAddress));
        System.out.println("Saved Phone: " + (savedPhone.isEmpty() ? "(not set)" : savedPhone));
        System.out.println("Cart items count: " + cartItems.size());
        System.out.println("Total amount: $" + total);

        request.getRequestDispatcher("checkout.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect("login");
            return;
        }

        if (isAdmin(session)) {
            session.setAttribute("errorMessage", "Admin accounts cannot checkout.");
            response.sendRedirect("products");
            return;
        }

        String shippingAddress = request.getParameter("shippingAddress");
        String paymentMethod = request.getParameter("paymentMethod");
        String contactNumber = request.getParameter("contactNumber");

        // Validate required fields
        if (shippingAddress == null || shippingAddress.trim().isEmpty()) {
            request.setAttribute("error", "Shipping address is required");

            // Re-populate the form with existing data
            User user = userDAO.getUserById(userId);
            List<CartItem> cartItems = cartDAO.getCartItems(userId);
            double total = 0;
            for (CartItem item : cartItems) {
                total += item.getSubtotal();
            }
            request.setAttribute("savedAddress", user.getAddress() != null ? user.getAddress() : "");
            request.setAttribute("savedPhone", user.getPhone() != null ? user.getPhone() : "");
            request.setAttribute("cartItems", cartItems);
            request.setAttribute("total", total);
            request.setAttribute("user", user);
            request.getRequestDispatcher("checkout.jsp").forward(request, response);
            return;
        }

        if (paymentMethod == null || paymentMethod.trim().isEmpty()) {
            request.setAttribute("error", "Payment method is required");

            User user = userDAO.getUserById(userId);
            List<CartItem> cartItems = cartDAO.getCartItems(userId);
            double total = 0;
            for (CartItem item : cartItems) {
                total += item.getSubtotal();
            }
            request.setAttribute("savedAddress", user.getAddress() != null ? user.getAddress() : "");
            request.setAttribute("savedPhone", user.getPhone() != null ? user.getPhone() : "");
            request.setAttribute("cartItems", cartItems);
            request.setAttribute("total", total);
            request.setAttribute("user", user);
            request.getRequestDispatcher("checkout.jsp").forward(request, response);
            return;
        }

        if (contactNumber == null || contactNumber.trim().isEmpty()) {
            request.setAttribute("error", "Contact number is required");

            User user = userDAO.getUserById(userId);
            List<CartItem> cartItems = cartDAO.getCartItems(userId);
            double total = 0;
            for (CartItem item : cartItems) {
                total += item.getSubtotal();
            }
            request.setAttribute("savedAddress", user.getAddress() != null ? user.getAddress() : "");
            request.setAttribute("savedPhone", user.getPhone() != null ? user.getPhone() : "");
            request.setAttribute("cartItems", cartItems);
            request.setAttribute("total", total);
            request.setAttribute("user", user);
            request.getRequestDispatcher("checkout.jsp").forward(request, response);
            return;
        }

        List<CartItem> cartItems = cartDAO.getCartItems(userId);

        if (cartItems.isEmpty()) {
            response.sendRedirect("cart");
            return;
        }

        // Check stock availability before processing order
        for (CartItem cartItem : cartItems) {
            int currentStock = cartItem.getProduct().getStockQuantity();
            if (currentStock < cartItem.getQuantity()) {
                String errorMsg = "Sorry, " + cartItem.getProduct().getProductName() +
                        " only has " + currentStock + " units available.";
                request.setAttribute("error", errorMsg);

                User user = userDAO.getUserById(userId);
                double total = 0;
                for (CartItem item : cartItems) {
                    total += item.getSubtotal();
                }
                request.setAttribute("savedAddress", user.getAddress() != null ? user.getAddress() : "");
                request.setAttribute("savedPhone", user.getPhone() != null ? user.getPhone() : "");
                request.setAttribute("cartItems", cartItems);
                request.setAttribute("total", total);
                request.setAttribute("user", user);
                request.getRequestDispatcher("checkout.jsp").forward(request, response);
                return;
            }
        }

        Order order = new Order();
        order.setUserId(userId);
        order.setShippingAddress(shippingAddress.trim());
        order.setPaymentMethod(paymentMethod);
        order.setContactNumber(contactNumber.trim());

        double total = 0;
        List<OrderItem> orderItems = new ArrayList<>();

        for (CartItem cartItem : cartItems) {
            OrderItem orderItem = new OrderItem();
            orderItem.setProductId(cartItem.getProduct().getProductId());
            orderItem.setProductName(cartItem.getProduct().getProductName());
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setPriceAtTime(cartItem.getProduct().getPrice());
            // Store product image URL in order item
            orderItem.setProductImageUrl(cartItem.getProduct().getImageUrl());
            orderItems.add(orderItem);

            total += cartItem.getSubtotal();
        }

        order.setTotalAmount(total);
        order.setOrderItems(orderItems);

        System.out.println("=== CheckoutServlet doPost ===");
        System.out.println("Creating order for user: " + userId);
        System.out.println("Shipping Address: " + shippingAddress);
        System.out.println("Contact Number: " + contactNumber);
        System.out.println("Payment Method: " + paymentMethod);
        System.out.println("Total Amount: $" + total);

        int orderId = orderDAO.createOrder(order);

        if (orderId != -1) {
            cartDAO.clearCart(userId);
            session.setAttribute("successMessage", "Order #" + orderId + " placed successfully!");
            System.out.println("Order #" + orderId + " created successfully. Cart cleared.");
            response.sendRedirect("orders");
        } else {
            System.out.println("Order creation failed!");
            request.setAttribute("error", "Checkout failed. Please try again.");

            User user = userDAO.getUserById(userId);
            request.setAttribute("savedAddress", user.getAddress() != null ? user.getAddress() : "");
            request.setAttribute("savedPhone", user.getPhone() != null ? user.getPhone() : "");
            request.setAttribute("cartItems", cartItems);
            request.setAttribute("total", total);
            request.setAttribute("user", user);
            request.getRequestDispatcher("checkout.jsp").forward(request, response);
        }
    }
}