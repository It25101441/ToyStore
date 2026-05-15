package com.toystore.dao;

import com.toystore.model.Order;
import com.toystore.model.OrderItem;
import com.toystore.model.Notification;
import com.toystore.model.User;
import com.toystore.model.Product;
import com.toystore.utils.DBConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class OrderDAO {

    private NotificationDAO notificationDAO = new NotificationDAO();

    // Create order (for customers)
    public int createOrder(Order order) {
        String orderSql = "INSERT INTO orders (user_id, total_amount, shipping_address, payment_method, contact_number) VALUES (?, ?, ?, ?, ?)";
        int generatedOrderId = -1;

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(orderSql, Statement.RETURN_GENERATED_KEYS)) {

            conn.setAutoCommit(false);

            pstmt.setInt(1, order.getUserId());
            pstmt.setDouble(2, order.getTotalAmount());
            pstmt.setString(3, order.getShippingAddress());
            pstmt.setString(4, order.getPaymentMethod());
            pstmt.setString(5, order.getContactNumber());

            pstmt.executeUpdate();

            ResultSet rs = pstmt.getGeneratedKeys();
            if (rs.next()) {
                generatedOrderId = rs.getInt(1);
            }

            if (generatedOrderId != -1 && order.getOrderItems() != null) {
                String itemSql = "INSERT INTO order_items (order_id, product_id, quantity, price_at_time, product_image_url) VALUES (?, ?, ?, ?, ?)";
                try (PreparedStatement itemStmt = conn.prepareStatement(itemSql)) {
                    for (OrderItem item : order.getOrderItems()) {
                        itemStmt.setInt(1, generatedOrderId);
                        itemStmt.setInt(2, item.getProductId());
                        itemStmt.setInt(3, item.getQuantity());
                        itemStmt.setDouble(4, item.getPriceAtTime());

                        // Store the product image URL at time of order
                        String imageUrl = item.getProductImageUrl();
                        if (imageUrl == null || imageUrl.isEmpty()) {
                            // If not provided, try to get from product
                            ProductDAO productDAO = new ProductDAO();
                            Product product = productDAO.getProductById(item.getProductId());
                            imageUrl = product != null ? product.getImageUrl() : null;
                        }
                        itemStmt.setString(5, imageUrl);
                        itemStmt.addBatch();
                    }
                    itemStmt.executeBatch();
                }

                String updateStockSql = "UPDATE products SET stock_quantity = stock_quantity - ? WHERE product_id = ?";
                try (PreparedStatement stockStmt = conn.prepareStatement(updateStockSql)) {
                    for (OrderItem item : order.getOrderItems()) {
                        stockStmt.setInt(1, item.getQuantity());
                        stockStmt.setInt(2, item.getProductId());
                        stockStmt.addBatch();
                    }
                    stockStmt.executeBatch();
                }

                String getUserSql = "SELECT username, full_name FROM users WHERE user_id = ?";
                String customerName = "Customer";
                try (PreparedStatement userStmt = conn.prepareStatement(getUserSql)) {
                    userStmt.setInt(1, order.getUserId());
                    ResultSet userRs = userStmt.executeQuery();
                    if (userRs.next()) {
                        String fullName = userRs.getString("full_name");
                        String username = userRs.getString("username");
                        customerName = (fullName != null && !fullName.isEmpty()) ? fullName : username;
                    }
                }

                Notification customerNotification = new Notification(
                        order.getUserId(),
                        "Your order #" + generatedOrderId + " has been placed successfully! Total: $" + String.format("%.2f", order.getTotalAmount()),
                        "ORDER_PLACED",
                        generatedOrderId
                );
                notificationDAO.createNotification(customerNotification);

                String adminMessage = "NEW ORDER #" + generatedOrderId + " from " + customerName + "! Amount: $" + String.format("%.2f", order.getTotalAmount());
                notificationDAO.createNotificationForAllAdmins(adminMessage, "NEW_ORDER", generatedOrderId);

                System.out.println("Admin notifications sent for new order #" + generatedOrderId);
            }

            conn.commit();
            System.out.println("Order created successfully with ID: " + generatedOrderId);

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return generatedOrderId;
    }

    private List<OrderItem> getOrderItems(int orderId) {
        List<OrderItem> items = new ArrayList<>();
        String sql = "SELECT oi.*, p.product_name, p.image_url FROM order_items oi " +
                "LEFT JOIN products p ON oi.product_id = p.product_id WHERE oi.order_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, orderId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                OrderItem item = new OrderItem();
                item.setOrderItemId(rs.getInt("order_item_id"));
                item.setOrderId(rs.getInt("order_id"));
                item.setProductId(rs.getInt("product_id"));
                item.setProductName(rs.getString("product_name"));
                item.setQuantity(rs.getInt("quantity"));
                item.setPriceAtTime(rs.getDouble("price_at_time"));

                // First try to get from order_items table (stored at order time)
                String imageUrl = rs.getString("product_image_url");
                // If not found, try to get from current product
                if (imageUrl == null || imageUrl.isEmpty()) {
                    imageUrl = rs.getString("image_url");
                }
                item.setProductImageUrl(imageUrl);
                items.add(item);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return items;
    }

    public List<Order> getOrdersByUserId(int userId) {
        List<Order> orders = new ArrayList<>();
        String sql = "SELECT * FROM orders WHERE user_id = ? ORDER BY order_date DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Order order = new Order();
                order.setOrderId(rs.getInt("order_id"));
                order.setUserId(rs.getInt("user_id"));
                order.setOrderDate(rs.getTimestamp("order_date"));
                order.setTotalAmount(rs.getDouble("total_amount"));
                order.setOrderStatus(rs.getString("order_status"));
                order.setShippingAddress(rs.getString("shipping_address"));
                order.setPaymentMethod(rs.getString("payment_method"));
                order.setContactNumber(rs.getString("contact_number"));
                order.setOrderItems(getOrderItems(order.getOrderId()));
                orders.add(order);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return orders;
    }

    public List<Order> getAllOrders() {
        List<Order> orders = new ArrayList<>();
        String sql = "SELECT o.*, u.username, u.full_name, u.email, u.phone, u.address as customer_address " +
                "FROM orders o " +
                "LEFT JOIN users u ON o.user_id = u.user_id " +
                "ORDER BY o.order_date DESC";

        try (Connection conn = DBConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                Order order = new Order();
                order.setOrderId(rs.getInt("order_id"));
                order.setUserId(rs.getInt("user_id"));
                order.setOrderDate(rs.getTimestamp("order_date"));
                order.setTotalAmount(rs.getDouble("total_amount"));
                order.setOrderStatus(rs.getString("order_status"));
                order.setShippingAddress(rs.getString("shipping_address"));
                order.setPaymentMethod(rs.getString("payment_method"));
                order.setContactNumber(rs.getString("contact_number"));

                User customer = new User();
                customer.setUserId(rs.getInt("user_id"));
                String username = rs.getString("username");
                customer.setUsername(username != null ? username : "Unknown");
                String fullName = rs.getString("full_name");
                customer.setFullName(fullName != null ? fullName : "");
                customer.setEmail(rs.getString("email") != null ? rs.getString("email") : "");
                customer.setPhone(rs.getString("phone") != null ? rs.getString("phone") : "");
                customer.setAddress(rs.getString("customer_address") != null ? rs.getString("customer_address") : "");
                order.setCustomer(customer);

                order.setOrderItems(getOrderItems(order.getOrderId()));
                orders.add(order);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return orders;
    }

    public Order getOrderWithUserDetails(int orderId) {
        String sql = "SELECT o.*, u.username, u.full_name, u.email, u.phone, u.address as customer_address " +
                "FROM orders o " +
                "LEFT JOIN users u ON o.user_id = u.user_id " +
                "WHERE o.order_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, orderId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                Order order = new Order();
                order.setOrderId(rs.getInt("order_id"));
                order.setUserId(rs.getInt("user_id"));
                order.setOrderDate(rs.getTimestamp("order_date"));
                order.setTotalAmount(rs.getDouble("total_amount"));
                order.setOrderStatus(rs.getString("order_status"));
                order.setShippingAddress(rs.getString("shipping_address"));
                order.setPaymentMethod(rs.getString("payment_method"));
                order.setContactNumber(rs.getString("contact_number"));

                User customer = new User();
                customer.setUserId(rs.getInt("user_id"));
                String username = rs.getString("username");
                customer.setUsername(username != null ? username : "Unknown");
                String fullName = rs.getString("full_name");
                customer.setFullName(fullName != null ? fullName : "");
                customer.setEmail(rs.getString("email") != null ? rs.getString("email") : "");
                customer.setPhone(rs.getString("phone") != null ? rs.getString("phone") : "");
                customer.setAddress(rs.getString("customer_address") != null ? rs.getString("customer_address") : "");
                order.setCustomer(customer);

                order.setOrderItems(getOrderItems(orderId));
                return order;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateOrderStatus(int orderId, String status) {
        String sql = "UPDATE orders SET order_status = ? WHERE order_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            conn.setAutoCommit(false);

            pstmt.setString(1, status);
            pstmt.setInt(2, orderId);
            int result = pstmt.executeUpdate();

            if (result > 0) {
                String getOrderSql = "SELECT o.user_id, o.total_amount, u.username, u.full_name FROM orders o " +
                        "LEFT JOIN users u ON o.user_id = u.user_id WHERE o.order_id = ?";
                try (PreparedStatement orderStmt = conn.prepareStatement(getOrderSql)) {
                    orderStmt.setInt(1, orderId);
                    ResultSet rs = orderStmt.executeQuery();
                    if (rs.next()) {
                        int userId = rs.getInt("user_id");
                        double totalAmount = rs.getDouble("total_amount");
                        String fullName = rs.getString("full_name");
                        String username = rs.getString("username");
                        String customerName = (fullName != null && !fullName.isEmpty()) ? fullName : username;

                        String customerMessage = "Order #" + orderId + " status updated to: " + status.toUpperCase();
                        Notification customerNotification = new Notification(userId, customerMessage, "ORDER_STATUS", orderId);
                        notificationDAO.createNotification(customerNotification);

                        // Add review reminder when order is delivered
                        if ("Delivered".equals(status)) {
                            String reminderMessage = "Your order #" + orderId + " has been delivered! We'd love to hear your feedback. You can now write reviews for the products you purchased.";
                            Notification reminderNotif = new Notification(userId, reminderMessage, "REVIEW_REMINDER", orderId);
                            notificationDAO.createNotification(reminderNotif);
                        }

                        String adminMessage = "Order #" + orderId + " for " + customerName + " status changed to: " + status.toUpperCase();
                        notificationDAO.createNotificationForAllAdmins(adminMessage, "ORDER_UPDATE", orderId);

                        System.out.println("Admin notifications sent for order #" + orderId + " status update");
                    }
                }
                conn.commit();
                System.out.println("Order " + orderId + " status updated to: " + status);
                return true;
            }
            conn.rollback();
            return false;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // NEW METHOD: Update product image URL in all order items when product image changes
    public boolean updateOrderItemImages(int productId, String newImageUrl) {
        String sql = "UPDATE order_items SET product_image_url = ? WHERE product_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, newImageUrl);
            pstmt.setInt(2, productId);

            int result = pstmt.executeUpdate();
            System.out.println("Updated " + result + " order items with new image for product ID: " + productId);
            return result > 0;

        } catch (SQLException e) {
            System.out.println("Error updating order item images: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
}