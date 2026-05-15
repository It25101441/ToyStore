package com.toystore.dao;

import com.toystore.model.Review;
import com.toystore.utils.DBConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ReviewDAO {

    // Add a new review
    public boolean addReview(Review review) {
        String sql = "INSERT INTO reviews (user_id, product_id, order_id, rating, comment) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            pstmt.setInt(1, review.getUserId());
            pstmt.setInt(2, review.getProductId());
            pstmt.setInt(3, review.getOrderId());
            pstmt.setInt(4, review.getRating());
            pstmt.setString(5, review.getComment());

            int result = pstmt.executeUpdate();

            if (result > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    review.setReviewId(rs.getInt(1));
                }
                rs.close();
                System.out.println("✅ Review added successfully - User ID: " + review.getUserId() +
                        ", Product ID: " + review.getProductId() +
                        ", Rating: " + review.getRating());
                return true;
            }
            return false;
        } catch (SQLException e) {
            System.err.println("❌ Error adding review: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    // Get reviews for a specific product (for product detail page)
    public List<Review> getReviewsByProductId(int productId) {
        List<Review> reviews = new ArrayList<>();
        String sql = "SELECT r.*, u.username, u.full_name " +
                "FROM reviews r " +
                "LEFT JOIN users u ON r.user_id = u.user_id " +
                "WHERE r.product_id = ? " +
                "ORDER BY r.created_at DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, productId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Review review = extractReviewFromResultSet(rs);
                reviews.add(review);
            }
            rs.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return reviews;
    }

    // Get all reviews (for admin) - WITH product names and images
    public List<Review> getAllReviews() {
        List<Review> reviews = new ArrayList<>();
        String sql = "SELECT r.*, u.username, u.full_name, p.product_name, p.image_url " +
                "FROM reviews r " +
                "LEFT JOIN users u ON r.user_id = u.user_id " +
                "LEFT JOIN products p ON r.product_id = p.product_id " +
                "ORDER BY r.created_at DESC";

        try (Connection conn = DBConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                Review review = extractReviewFromResultSet(rs);
                review.setProductName(rs.getString("product_name"));
                review.setProductImageUrl(rs.getString("image_url"));
                reviews.add(review);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return reviews;
    }

    // FIXED: Get reviews by user ID for "My Reviews" page
    public List<Review> getReviewsByUserId(int userId) {
        List<Review> reviews = new ArrayList<>();
        String sql = "SELECT r.*, u.username, u.full_name, p.product_name, p.image_url " +
                "FROM reviews r " +
                "LEFT JOIN users u ON r.user_id = u.user_id " +
                "INNER JOIN products p ON r.product_id = p.product_id " +  // Changed to INNER JOIN to ensure product exists
                "WHERE r.user_id = ? " +
                "ORDER BY r.created_at DESC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Review review = extractReviewFromResultSet(rs);
                review.setProductName(rs.getString("product_name"));
                review.setProductImageUrl(rs.getString("image_url"));
                reviews.add(review);
                System.out.println("📝 Found review for user " + userId +
                        ": Product=" + review.getProductName() +
                        ", Rating=" + review.getRating());
            }
            rs.close();
            System.out.println("📊 Total reviews found for user " + userId + ": " + reviews.size());

        } catch (SQLException e) {
            System.err.println("❌ Error in getReviewsByUserId: " + e.getMessage());
            e.printStackTrace();
        }
        return reviews;
    }

    // Check if user has already reviewed a product from a delivered order
    public boolean hasUserReviewedProduct(int userId, int productId, int orderId) {
        String sql = "SELECT COUNT(*) FROM reviews WHERE user_id = ? AND product_id = ? AND order_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            pstmt.setInt(2, productId);
            pstmt.setInt(3, orderId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // Get average rating for a product
    public double getAverageRating(int productId) {
        String sql = "SELECT AVG(rating) as avg_rating FROM reviews WHERE product_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, productId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                double avg = rs.getDouble("avg_rating");
                return rs.wasNull() ? 0 : avg;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    // Get review count for a product
    public int getReviewCount(int productId) {
        String sql = "SELECT COUNT(*) FROM reviews WHERE product_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, productId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    // Get review by ID
    public Review getReviewById(int reviewId) {
        String sql = "SELECT r.*, u.username, u.full_name, p.product_name, p.image_url " +
                "FROM reviews r " +
                "LEFT JOIN users u ON r.user_id = u.user_id " +
                "LEFT JOIN products p ON r.product_id = p.product_id " +
                "WHERE r.review_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, reviewId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                Review review = extractReviewFromResultSet(rs);
                review.setProductName(rs.getString("product_name"));
                review.setProductImageUrl(rs.getString("image_url"));
                return review;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // Delete a review (admin only)
    public boolean deleteReview(int reviewId) {
        String sql = "DELETE FROM reviews WHERE review_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, reviewId);
            int result = pstmt.executeUpdate();
            System.out.println("🗑️ Deleted review ID: " + reviewId + ", Result: " + result);
            return result > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // Helper method to extract review from ResultSet
    private Review extractReviewFromResultSet(ResultSet rs) throws SQLException {
        Review review = new Review();
        review.setReviewId(rs.getInt("review_id"));
        review.setUserId(rs.getInt("user_id"));
        review.setProductId(rs.getInt("product_id"));
        review.setOrderId(rs.getInt("order_id"));
        review.setRating(rs.getInt("rating"));
        review.setComment(rs.getString("comment"));
        review.setCreatedAt(rs.getTimestamp("created_at"));
        review.setUpdatedAt(rs.getTimestamp("updated_at"));
        review.setUserName(rs.getString("username"));
        review.setUserFullName(rs.getString("full_name"));
        return review;
    }
}