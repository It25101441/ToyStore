package com.toystore.servlet;

import com.toystore.dao.OrderDAO;
import com.toystore.model.Order;
import com.toystore.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;
import java.util.ArrayList;

@WebServlet("/orders")
public class OrderServlet extends HttpServlet {

    private OrderDAO orderDAO = new OrderDAO();

    // Helper method to check if user is admin
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

        String action = request.getParameter("action");

        if (action != null && action.equals("updateStatus") && isAdmin(session)) {
            // Admin updating order status
            int orderId = Integer.parseInt(request.getParameter("orderId"));
            String status = request.getParameter("status");

            boolean updated = orderDAO.updateOrderStatus(orderId, status);

            if (updated) {
                session.setAttribute("successMessage", "Order #" + orderId + " status updated to: " + status);
            } else {
                session.setAttribute("errorMessage", "Failed to update order status");
            }

            response.sendRedirect("orders");

        } else if (action != null && action.equals("view") && isAdmin(session)) {
            // Admin viewing specific order details
            int orderId = Integer.parseInt(request.getParameter("orderId"));
            Order order = orderDAO.getOrderWithUserDetails(orderId);
            request.setAttribute("order", order);
            request.getRequestDispatcher("orderDetail.jsp").forward(request, response);

        } else {
            // Regular order listing or admin all orders view
            List<Order> orders;
            String searchKeyword = request.getParameter("search");
            boolean isSearchResult = false;

            if (isAdmin(session)) {
                // Admin sees all orders
                orders = orderDAO.getAllOrders();

                // Handle search if keyword is provided
                if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
                    String keyword = searchKeyword.trim().toLowerCase();
                    List<Order> filteredOrders = new ArrayList<>();

                    System.out.println("Searching orders with keyword: " + keyword);

                    for (Order order : orders) {
                        // Search by Order ID
                        boolean matchesOrderId = String.valueOf(order.getOrderId()).contains(keyword);

                        // Search by Username
                        boolean matchesUsername = false;
                        if (order.getCustomer() != null && order.getCustomer().getUsername() != null) {
                            matchesUsername = order.getCustomer().getUsername().toLowerCase().contains(keyword);
                        }

                        // Also search by customer full name
                        boolean matchesFullName = false;
                        if (order.getCustomer() != null && order.getCustomer().getFullName() != null) {
                            matchesFullName = order.getCustomer().getFullName().toLowerCase().contains(keyword);
                        }

                        if (matchesOrderId || matchesUsername || matchesFullName) {
                            filteredOrders.add(order);
                            System.out.println("Matched order #" + order.getOrderId());
                        }
                    }

                    orders = filteredOrders;
                    isSearchResult = true;
                    request.setAttribute("searchKeyword", searchKeyword.trim());
                    System.out.println("Search results count: " + orders.size());
                }

                request.setAttribute("isAdmin", true);
                request.setAttribute("isSearchResult", isSearchResult);
                request.setAttribute("orderCount", orders.size());
            } else {
                // Regular user sees only their orders
                orders = orderDAO.getOrdersByUserId(userId);
                request.setAttribute("isAdmin", false);
                request.setAttribute("isSearchResult", false);
            }

            request.setAttribute("orders", orders);
            request.getRequestDispatcher("orders.jsp").forward(request, response);
        }
    }
}