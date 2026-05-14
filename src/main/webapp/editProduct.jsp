<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.toystore.model.Product" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Product</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 2rem;
        }

        .form-container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            width: 100%;
            max-width: 500px;
        }

        h2 {
            text-align: center;
            color: #667eea;
            margin-bottom: 1.5rem;
        }

        .form-group {
            margin-bottom: 1rem;
        }

        label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 500;
        }

        input, textarea, select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
        }

        input[type="file"] {
            padding: 5px;
        }

        .current-image {
            text-align: center;
            margin-bottom: 1rem;
        }

        .current-image img {
            max-width: 120px;
            max-height: 120px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .image-preview {
            margin-top: 10px;
            text-align: center;
        }

        .image-preview img {
            max-width: 150px;
            max-height: 150px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        button {
            width: 100%;
            background: #667eea;
            color: white;
            padding: 12px;
            border: none;
            border-radius: 5px;
            font-size: 1rem;
            cursor: pointer;
            margin-top: 1rem;
        }

        button:hover {
            background: #5a67d8;
        }

        .back-link {
            display: block;
            text-align: center;
            margin-top: 1rem;
            color: #667eea;
            text-decoration: none;
        }

        .message {
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 1rem;
            text-align: center;
        }

        .success {
            background: #c6f6d5;
            color: #22543d;
        }

        .image-info {
            font-size: 0.85rem;
            color: #666;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="form-container">
        <h2>Edit Product</h2>

        <% if (request.getParameter("imageUploaded") != null) { %>
            <div class="message success">✓ Image uploaded successfully! Update the form below.</div>
        <% } %>

        <form action="products" method="post" enctype="multipart/form-data">
            <input type="hidden" name="action" value="update">

            <% Product product = (Product) request.getAttribute("product"); %>
            <input type="hidden" name="productId" value="<%= product.getProductId() %>">
            <input type="hidden" name="existingImage" value="<%= product.getImageUrl() != null ? product.getImageUrl() : "" %>">

            <div class="form-group">
                <label>Current Image</label>
                <div class="current-image">
                    <img src="<%= product.getImagePath() %>" alt="Current product image"
                         onerror="this.src='images/default-toy.png'">
                </div>
                <label>Change Image (optional)</label>
                <input type="file" name="productImage" accept="image/jpeg,image/png,image/jpg,image/gif" id="imageInput">
                <div class="image-preview" id="imagePreview"></div>
                <div class="image-info">Upload a new image to replace the current one. Supported formats: JPG, PNG, GIF</div>
            </div>

            <div class="form-group">
                <label>Product Name</label>
                <input type="text" name="productName" value="<%= product.getProductName() %>" required>
            </div>

            <div class="form-group">
                <label>Description</label>
                <textarea name="description" rows="3"><%= product.getDescription() %></textarea>
            </div>

            <div class="form-group">
                <label>Price ($)</label>
                <input type="number" step="0.01" name="price" value="<%= product.getPrice() %>" required>
            </div>

            <div class="form-group">
                <label>Stock Quantity</label>
                <input type="number" name="stockQuantity" value="<%= product.getStockQuantity() %>" required>
            </div>

            <div class="form-group">
                <label>Category</label>
                <select name="category">
                    <option value="Stuffed Toys" <%= product.getCategory() != null && product.getCategory().equals("Stuffed Toys") ? "selected" : "" %>>Stuffed Toys</option>
                    <option value="Building Toys" <%= product.getCategory() != null && product.getCategory().equals("Building Toys") ? "selected" : "" %>>Building Toys</option>
                    <option value="Dolls" <%= product.getCategory() != null && product.getCategory().equals("Dolls") ? "selected" : "" %>>Dolls</option>
                    <option value="Remote Control" <%= product.getCategory() != null && product.getCategory().equals("Remote Control") ? "selected" : "" %>>Remote Control</option>
                    <option value="Puzzles" <%= product.getCategory() != null && product.getCategory().equals("Puzzles") ? "selected" : "" %>>Puzzles</option>
                </select>
            </div>

            <button type="submit">Update Product</button>
        </form>
        <a href="products" class="back-link">← Back to Products</a>
    </div>

    <script>
        document.getElementById('imageInput').addEventListener('change', function(e) {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(event) {
                    const preview = document.getElementById('imagePreview');
                    preview.innerHTML = '<img src="' + event.target.result + '" alt="New Image Preview">';
                }
                reader.readAsDataURL(file);
            } else {
                document.getElementById('imagePreview').innerHTML = '';
            }
        });
    </script>
</body>
</html>