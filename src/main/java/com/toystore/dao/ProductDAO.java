package com.toystore.dao;

import com.toystore.model.Product;
import com.toystore.utils.DBConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProductDAO {

    // Create with image support
    public boolean addProduct(Product product) {
        String sql = "INSERT INTO products (product_name, description, price, stock_quantity, category, image_url) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, product.getProductName());
            pstmt.setString(2, product.getDescription());
            pstmt.setDouble(3, product.getPrice());
            pstmt.setInt(4, product.getStockQuantity());
            pstmt.setString(5, product.getCategory());
            pstmt.setString(6, product.getImageUrl());

            int result = pstmt.executeUpdate();
            System.out.println("Add product result: " + result);
            return result > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // Read all products with image
    public List<Product> getAllProducts() {
        List<Product> products = new ArrayList<>();
        String sql = "SELECT * FROM products ORDER BY product_id DESC";

        try (Connection conn = DBConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductName(rs.getString("product_name"));
                product.setDescription(rs.getString("description"));
                product.setPrice(rs.getDouble("price"));
                product.setStockQuantity(rs.getInt("stock_quantity"));
                product.setCategory(rs.getString("category"));
                product.setImageUrl(rs.getString("image_url"));
                products.add(product);
            }
            System.out.println("Retrieved " + products.size() + " products");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return products;
    }

    // Get all products with ratings
    public List<Product> getAllProductsWithRatings() {
        List<Product> products = getAllProducts();
        ReviewDAO reviewDAO = new ReviewDAO();
        for (Product product : products) {
            double avgRating = reviewDAO.getAverageRating(product.getProductId());
            int reviewCount = reviewDAO.getReviewCount(product.getProductId());
            product.setAverageRating(avgRating);
            product.setReviewCount(reviewCount);
        }
        return products;
    }

    // Read single product with image
    public Product getProductById(int productId) {
        String sql = "SELECT * FROM products WHERE product_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, productId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductName(rs.getString("product_name"));
                product.setDescription(rs.getString("description"));
                product.setPrice(rs.getDouble("price"));
                product.setStockQuantity(rs.getInt("stock_quantity"));
                product.setCategory(rs.getString("category"));
                product.setImageUrl(rs.getString("image_url"));
                return product;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // Get product with average rating
    public Product getProductWithRating(int productId) {
        Product product = getProductById(productId);
        if (product != null) {
            ReviewDAO reviewDAO = new ReviewDAO();
            double avgRating = reviewDAO.getAverageRating(productId);
            int reviewCount = reviewDAO.getReviewCount(productId);
            product.setAverageRating(avgRating);
            product.setReviewCount(reviewCount);
        }
        return product;
    }

    // Update with image support
    public boolean updateProduct(Product product) {
        String sql = "UPDATE products SET product_name=?, description=?, price=?, stock_quantity=?, category=?, image_url=? WHERE product_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, product.getProductName());
            pstmt.setString(2, product.getDescription());
            pstmt.setDouble(3, product.getPrice());
            pstmt.setInt(4, product.getStockQuantity());
            pstmt.setString(5, product.getCategory());
            pstmt.setString(6, product.getImageUrl());
            pstmt.setInt(7, product.getProductId());

            int result = pstmt.executeUpdate();
            System.out.println("Update product result: " + result);
            return result > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // Delete
    public boolean deleteProduct(int productId) {
        String sql = "DELETE FROM products WHERE product_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, productId);
            int result = pstmt.executeUpdate();

            System.out.println("Delete product ID: " + productId);
            System.out.println("Rows affected: " + result);

            return result > 0;

        } catch (SQLException e) {
            System.out.println("SQL Error in deleteProduct: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
}