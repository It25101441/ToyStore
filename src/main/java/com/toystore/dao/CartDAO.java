package com.toystore.dao;

import com.toystore.model.CartItem;
import com.toystore.model.Product;
import com.toystore.utils.DBConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CartDAO {

    public boolean addToCart(int userId, int productId, int quantity) {
        System.out.println("=== CartDAO.addToCart ===");
        System.out.println("UserID: " + userId + ", ProductID: " + productId + ", Quantity: " + quantity);

        Connection conn = null;
        PreparedStatement checkStmt = null;
        PreparedStatement updateStmt = null;
        PreparedStatement insertStmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            // First check if item already exists in cart
            String checkSql = "SELECT cart_item_id, quantity FROM cart_items WHERE user_id = ? AND product_id = ?";
            checkStmt = conn.prepareStatement(checkSql);
            checkStmt.setInt(1, userId);
            checkStmt.setInt(2, productId);
            rs = checkStmt.executeQuery();

            boolean success = false;

            if (rs.next()) {
                // Update existing item
                int existingQuantity = rs.getInt("quantity");
                int newQuantity = existingQuantity + quantity;
                String updateSql = "UPDATE cart_items SET quantity = ? WHERE user_id = ? AND product_id = ?";
                updateStmt = conn.prepareStatement(updateSql);
                updateStmt.setInt(1, newQuantity);
                updateStmt.setInt(2, userId);
                updateStmt.setInt(3, productId);
                int result = updateStmt.executeUpdate();
                success = result > 0;
                System.out.println("Updated existing cart item. Result: " + result);
            } else {
                // Insert new item
                String insertSql = "INSERT INTO cart_items (user_id, product_id, quantity) VALUES (?, ?, ?)";
                insertStmt = conn.prepareStatement(insertSql);
                insertStmt.setInt(1, userId);
                insertStmt.setInt(2, productId);
                insertStmt.setInt(3, quantity);
                int result = insertStmt.executeUpdate();
                success = result > 0;
                System.out.println("Inserted new cart item. Result: " + result);
            }

            if (success) {
                conn.commit();
                System.out.println("Transaction committed successfully");
                return true;
            } else {
                conn.rollback();
                System.out.println("Transaction rolled back - no rows affected");
                return false;
            }

        } catch (SQLException e) {
            System.out.println("SQL Error in addToCart: " + e.getMessage());
            System.out.println("SQL State: " + e.getSQLState());
            System.out.println("Error Code: " + e.getErrorCode());
            e.printStackTrace();

            if (conn != null) {
                try {
                    conn.rollback();
                    System.out.println("Transaction rolled back due to error");
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            return false;

        } finally {
            // Close all resources
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (checkStmt != null) checkStmt.close(); } catch (SQLException e) {}
            try { if (updateStmt != null) updateStmt.close(); } catch (SQLException e) {}
            try { if (insertStmt != null) insertStmt.close(); } catch (SQLException e) {}
            try { if (conn != null) {
                conn.setAutoCommit(true);
                conn.close();
            } } catch (SQLException e) {}
        }
    }

    public List<CartItem> getCartItems(int userId) {
        List<CartItem> cartItems = new ArrayList<>();
        // FIXED: Added p.image_url to SELECT clause
        String sql = "SELECT c.cart_item_id, c.user_id, c.quantity, " +
                "p.product_id, p.product_name, p.price, p.stock_quantity, p.description, p.image_url " +
                "FROM cart_items c " +
                "INNER JOIN products p ON c.product_id = p.product_id " +
                "WHERE c.user_id = ?";

        System.out.println("Getting cart items for user: " + userId);

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductName(rs.getString("product_name"));
                product.setPrice(rs.getDouble("price"));
                product.setStockQuantity(rs.getInt("stock_quantity"));
                product.setDescription(rs.getString("description"));
                product.setImageUrl(rs.getString("image_url")); // FIXED: Now setting image URL

                CartItem cartItem = new CartItem();
                cartItem.setCartItemId(rs.getInt("cart_item_id"));
                cartItem.setUserId(rs.getInt("user_id"));
                cartItem.setProduct(product);
                cartItem.setQuantity(rs.getInt("quantity"));

                cartItems.add(cartItem);
                System.out.println("Added cart item: " + product.getProductName() + " x " + cartItem.getQuantity());
            }
            System.out.println("Total cart items found: " + cartItems.size());

        } catch (SQLException e) {
            System.out.println("Error getting cart items: " + e.getMessage());
            e.printStackTrace();
        }
        return cartItems;
    }

    public boolean updateCartItemQuantity(int cartItemId, int quantity) {
        String sql = "UPDATE cart_items SET quantity = ? WHERE cart_item_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, quantity);
            pstmt.setInt(2, cartItemId);
            int result = pstmt.executeUpdate();
            System.out.println("Updated quantity for cart item " + cartItemId + " to " + quantity + ". Result: " + result);
            return result > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean removeFromCart(int cartItemId) {
        String sql = "DELETE FROM cart_items WHERE cart_item_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, cartItemId);
            int result = pstmt.executeUpdate();
            System.out.println("Removed cart item " + cartItemId + ". Result: " + result);
            return result > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public void clearCart(int userId) {
        String sql = "DELETE FROM cart_items WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            int result = pstmt.executeUpdate();
            System.out.println("Cleared cart for user: " + userId + ". Deleted " + result + " items");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    // Method to get cart item count for a user (returns total quantity sum)
    public int getCartItemCount(int userId) {
        String sql = "SELECT SUM(quantity) as total FROM cart_items WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                int total = rs.getInt("total");
                System.out.println("Cart item count for user " + userId + ": " + total);
                return total;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    // Method to get total number of items (sum of quantities) in cart for a user
    public int getTotalCartItemCount(int userId) {
        String sql = "SELECT COALESCE(SUM(quantity), 0) as total FROM cart_items WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                int total = rs.getInt("total");
                System.out.println("Total cart item count (sum of quantities) for user " + userId + ": " + total);
                return total;
            }
        } catch (SQLException e) {
            System.out.println("Error getting total cart item count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
}