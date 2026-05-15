package com.toystore.model;

public class OrderItem {
    private int orderItemId;
    private int orderId;
    private int productId;
    private String productName;
    private String productImageUrl;  // NEW FIELD
    private int quantity;
    private double priceAtTime;

    // Getters and Setters
    public int getOrderItemId() { return orderItemId; }
    public void setOrderItemId(int orderItemId) { this.orderItemId = orderItemId; }

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getProductImageUrl() { return productImageUrl; }
    public void setProductImageUrl(String productImageUrl) { this.productImageUrl = productImageUrl; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public double getPriceAtTime() { return priceAtTime; }
    public void setPriceAtTime(double priceAtTime) { this.priceAtTime = priceAtTime; }

    // Helper method to get image path
    public String getImagePath() {
        if (productImageUrl != null && !productImageUrl.isEmpty()) {
            return "images/" + productImageUrl;
        }
        return "images/default-toy.png";
    }
}