package com.toystore.model;

public class CartItem {
    private int cartItemId;
    private int userId;
    private Product product;
    private int quantity;

    public CartItem() {}

    public CartItem(Product product, int quantity) {
        this.product = product;
        this.quantity = quantity;
    }

    // Getters and Setters
    public int getCartItemId() { return cartItemId; }
    public void setCartItemId(int cartItemId) { this.cartItemId = cartItemId; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public Product getProduct() { return product; }
    public void setProduct(Product product) { this.product = product; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public double getSubtotal() {
        return product.getPrice() * quantity;
    }

    // Helper method to get product image path
    public String getProductImagePath() {
        if (product != null && product.getImageUrl() != null && !product.getImageUrl().isEmpty()) {
            return "images/" + product.getImageUrl();
        }
        return "images/default-toy.png";
    }
}