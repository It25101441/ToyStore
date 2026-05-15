package com.toystore.model;

public class Product {
    private int productId;
    private String productName;
    private String description;
    private double price;
    private int stockQuantity;
    private String imageUrl;
    private String category;
    private double averageRating;
    private int reviewCount;

    public Product() {}

    public Product(int productId, String productName, double price, int stockQuantity) {
        this.productId = productId;
        this.productName = productName;
        this.price = price;
        this.stockQuantity = stockQuantity;
    }

    // Getters and Setters
    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }

    public int getStockQuantity() { return stockQuantity; }
    public void setStockQuantity(int stockQuantity) { this.stockQuantity = stockQuantity; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public double getAverageRating() { return averageRating; }
    public void setAverageRating(double averageRating) { this.averageRating = averageRating; }

    public int getReviewCount() { return reviewCount; }
    public void setReviewCount(int reviewCount) { this.reviewCount = reviewCount; }

    // Helper method to get full image path
    public String getImagePath() {
        if (imageUrl != null && !imageUrl.isEmpty()) {
            return "images/" + imageUrl;
        }
        return "images/default-toy.png";
    }

    // Helper method to get star rating display
    public String getStarRatingDisplay() {
        if (averageRating == 0) return "No reviews yet";
        int fullStars = (int) averageRating;
        boolean hasHalfStar = (averageRating - fullStars) >= 0.5;
        StringBuilder stars = new StringBuilder();
        for (int i = 0; i < fullStars; i++) {
            stars.append("★");
        }
        if (hasHalfStar) {
            stars.append("½");
        }
        return stars.toString();
    }
}