<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Add New Product</title>
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

        .upload-btn {
            background: #48bb78;
            margin-top: 0.5rem;
        }

        .upload-btn:hover {
            background: #38a169;
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
        <h2>Add New Product</h2>

        <% if (request.getParameter("imageUploaded") != null) { %>
            <div class="message success">✓ Image uploaded successfully! Complete the form below.</div>
        <% } %>

        <form action="products" method="post" enctype="multipart/form-data">
            <input type="hidden" name="action" value="add">

            <div class="form-group">
                <label>Product Image</label>
                <input type="file" name="productImage" accept="image/jpeg,image/png,image/jpg,image/gif" id="imageInput">
                <div class="image-preview" id="imagePreview"></div>
                <div class="image-info">Supported formats: JPG, PNG, GIF (Max: 5MB)</div>
            </div>

            <div class="form-group">
                <label>Product Name</label>
                <input type="text" name="productName" required>
            </div>

            <div class="form-group">
                <label>Description</label>
                <textarea name="description" rows="3"></textarea>
            </div>

            <div class="form-group">
                <label>Price ($)</label>
                <input type="number" step="0.01" name="price" required>
            </div>

            <div class="form-group">
                <label>Stock Quantity</label>
                <input type="number" name="stockQuantity" required>
            </div>

            <div class="form-group">
                <label>Category</label>
                <select name="category">
                    <option value="Stuffed Toys">Stuffed Toys</option>
                    <option value="Building Toys">Building Toys</option>
                    <option value="Dolls">Dolls</option>
                    <option value="Remote Control">Remote Control</option>
                    <option value="Puzzles">Puzzles</option>
                </select>
            </div>

            <button type="submit">Add Product</button>
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
                    preview.innerHTML = '<img src="' + event.target.result + '" alt="Preview">';
                }
                reader.readAsDataURL(file);
            }
        });
    </script>
</body>
</html>