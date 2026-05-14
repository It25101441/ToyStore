package com.toystore.servlet;

import com.toystore.dao.ProductDAO;
import com.toystore.dao.ReviewDAO;
import com.toystore.dao.NotificationDAO;
import com.toystore.dao.OrderDAO;
import com.toystore.model.Product;
import com.toystore.model.Review;
import com.toystore.model.Notification;
import com.toystore.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/products")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 2,
        maxFileSize = 1024 * 1024 * 10,
        maxRequestSize = 1024 * 1024 * 50
)
public class ProductServlet extends HttpServlet {

    private ProductDAO productDAO = new ProductDAO();
    private ReviewDAO reviewDAO = new ReviewDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();
    private OrderDAO orderDAO = new OrderDAO();
    private static final String UPLOAD_DIR = "images";

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && user.isAdmin();
    }

    private int getCurrentUserId(HttpSession session) {
        User user = (User) session.getAttribute("user");
        return user != null ? user.getUserId() : -1;
    }

    private String getCurrentAdminName(HttpSession session) {
        User user = (User) session.getAttribute("user");
        if (user != null) {
            if (user.getFullName() != null && !user.getFullName().isEmpty()) {
                return user.getFullName();
            }
            return user.getUsername();
        }
        return "Admin";
    }

    private String uploadImage(HttpServletRequest request, String existingImage) throws IOException, ServletException {
        Part filePart = request.getPart("productImage");

        if (filePart == null || filePart.getSize() == 0) {
            return existingImage;
        }

        String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();

        String fileExtension = "";
        if (fileName.contains(".")) {
            fileExtension = fileName.substring(fileName.lastIndexOf("."));
        }
        String uniqueFileName = System.currentTimeMillis() + fileExtension;

        String applicationPath = request.getServletContext().getRealPath("");
        String uploadFilePath = applicationPath + File.separator + UPLOAD_DIR;

        File uploadDir = new File(uploadFilePath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        String filePath = uploadFilePath + File.separator + uniqueFileName;
        filePart.write(filePath);

        return uniqueFileName;
    }

    // Show product detail with all reviews
    private void showProductDetail(HttpServletRequest request, HttpServletResponse response, int productId)
            throws ServletException, IOException {

        // Get product with ratings
        Product product = productDAO.getProductWithRating(productId);

        if (product == null) {
            response.sendRedirect("products");
            return;
        }

        // Get all reviews for this product (for all users to see)
        List<Review> reviews = reviewDAO.getReviewsByProductId(productId);
        double avgRating = reviewDAO.getAverageRating(productId);
        int reviewCount = reviewDAO.getReviewCount(productId);

        request.setAttribute("product", product);
        request.setAttribute("reviews", reviews);
        request.setAttribute("averageRating", avgRating);
        request.setAttribute("reviewCount", reviewCount);

        request.getRequestDispatcher("productDetail.jsp").forward(request, response);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        String action = request.getParameter("action");
        String productIdParam = request.getParameter("id");
        String searchKeyword = request.getParameter("search");

        // Handle product detail view (when id parameter is present and no action)
        if (productIdParam != null && !productIdParam.trim().isEmpty() && action == null) {
            try {
                int productId = Integer.parseInt(productIdParam);
                showProductDetail(request, response, productId);
                return;
            } catch (NumberFormatException e) {
                response.sendRedirect("products");
                return;
            }
        }

        System.out.println("=== ProductServlet doGet ===");
        System.out.println("Action: " + action);
        System.out.println("Search: " + searchKeyword);

        if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
            List<Product> allProducts = productDAO.getAllProductsWithRatings();
            String keyword = searchKeyword.trim().toLowerCase();
            List<Product> filteredProducts = new ArrayList<>();

            System.out.println("Searching products with keyword: " + keyword);

            for (Product product : allProducts) {
                boolean matchesName = product.getProductName() != null &&
                        product.getProductName().toLowerCase().contains(keyword);
                boolean matchesCategory = product.getCategory() != null &&
                        product.getCategory().toLowerCase().contains(keyword);
                boolean matchesDescription = product.getDescription() != null &&
                        product.getDescription().toLowerCase().contains(keyword);

                if (matchesName || matchesCategory || matchesDescription) {
                    filteredProducts.add(product);
                    System.out.println("Matched product: " + product.getProductName());
                }
            }

            request.setAttribute("products", filteredProducts);
            request.setAttribute("productCount", filteredProducts.size());
            request.getRequestDispatcher("products.jsp").forward(request, response);
            return;
        }

        if (action == null || action.isEmpty()) {
            List<Product> products = productDAO.getAllProductsWithRatings();
            request.setAttribute("products", products);
            request.setAttribute("productCount", products.size());
            request.getRequestDispatcher("products.jsp").forward(request, response);

        } else if (action.equals("edit")) {
            if (!isAdmin(session)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required");
                return;
            }
            int productId = Integer.parseInt(request.getParameter("id"));
            Product product = productDAO.getProductById(productId);
            request.setAttribute("product", product);
            request.getRequestDispatcher("editProduct.jsp").forward(request, response);

        } else if (action.equals("delete")) {
            if (!isAdmin(session)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required");
                return;
            }

            try {
                int productId = Integer.parseInt(request.getParameter("id"));
                Product product = productDAO.getProductById(productId);
                String productName = product != null ? product.getProductName() : "Unknown Product";

                System.out.println("Attempting to delete product ID: " + productId);

                boolean deleted = productDAO.deleteProduct(productId);

                if (deleted) {
                    System.out.println("Product deleted successfully");
                    session.setAttribute("successMessage", "Product deleted successfully!");

                    String adminName = getCurrentAdminName(session);
                    int currentAdminId = getCurrentUserId(session);
                    String notificationMessage = "PRODUCT DELETED by " + adminName + ": \"" + productName + "\" (ID: #" + productId + ") has been removed from the store.";
                    notificationDAO.createNotificationForAllAdminsExcept(notificationMessage, "PRODUCT_DELETED", productId, currentAdminId);

                    String selfNotification = "You successfully deleted product: \"" + productName + "\" (ID: #" + productId + ")";
                    Notification selfNotif = new Notification(currentAdminId, selfNotification, "ADMIN_ACTION", productId);
                    notificationDAO.createNotification(selfNotif);

                } else {
                    System.out.println("Failed to delete product");
                    session.setAttribute("errorMessage", "Failed to delete product!");
                }

            } catch (NumberFormatException e) {
                System.out.println("Invalid product ID: " + e.getMessage());
                session.setAttribute("errorMessage", "Invalid product ID!");
            }

            response.sendRedirect("products");

        } else if (action.equals("add")) {
            if (!isAdmin(session)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required");
                return;
            }
            request.getRequestDispatcher("addProduct.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!isAdmin(session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required");
            return;
        }

        String action = request.getParameter("action");
        int currentAdminId = getCurrentUserId(session);
        String adminName = getCurrentAdminName(session);

        System.out.println("=== ProductServlet doPost ===");
        System.out.println("Action: " + action);

        if (action.equals("add")) {
            try {
                Product product = new Product();
                product.setProductName(request.getParameter("productName"));
                product.setDescription(request.getParameter("description"));
                product.setPrice(Double.parseDouble(request.getParameter("price")));
                product.setStockQuantity(Integer.parseInt(request.getParameter("stockQuantity")));
                product.setCategory(request.getParameter("category"));

                String imageName = uploadImage(request, null);
                product.setImageUrl(imageName);

                boolean added = productDAO.addProduct(product);

                if (added) {
                    session.setAttribute("successMessage", "Product added successfully!");

                    String notificationMessage = "NEW PRODUCT ADDED by " + adminName + ": \"" + product.getProductName() + "\" ($" + String.format("%.2f", product.getPrice()) + ") has been added to the store.";
                    notificationDAO.createNotificationForAllAdminsExcept(notificationMessage, "PRODUCT_ADDED", 0, currentAdminId);

                    String selfNotification = "You successfully added a new product: \"" + product.getProductName() + "\" ($" + String.format("%.2f", product.getPrice()) + ")";
                    Notification selfNotif = new Notification(currentAdminId, selfNotification, "ADMIN_ACTION", 0);
                    notificationDAO.createNotification(selfNotif);

                } else {
                    session.setAttribute("errorMessage", "Failed to add product!");
                }

            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("errorMessage", "Error adding product: " + e.getMessage());
            }
            response.sendRedirect("products");

        } else if (action.equals("update")) {
            try {
                Product product = new Product();
                product.setProductId(Integer.parseInt(request.getParameter("productId")));
                product.setProductName(request.getParameter("productName"));
                product.setDescription(request.getParameter("description"));
                product.setPrice(Double.parseDouble(request.getParameter("price")));
                product.setStockQuantity(Integer.parseInt(request.getParameter("stockQuantity")));
                product.setCategory(request.getParameter("category"));

                Product oldProduct = productDAO.getProductById(product.getProductId());
                String oldProductName = oldProduct != null ? oldProduct.getProductName() : "Unknown Product";
                String oldImageUrl = oldProduct != null ? oldProduct.getImageUrl() : "";

                String existingImage = request.getParameter("existingImage");
                String newImageName = uploadImage(request, existingImage);
                product.setImageUrl(newImageName);

                boolean updated = productDAO.updateProduct(product);

                if (updated) {
                    // If the image was changed, update all order items with the new image
                    if (newImageName != null && !newImageName.isEmpty() && !newImageName.equals(oldImageUrl)) {
                        orderDAO.updateOrderItemImages(product.getProductId(), newImageName);
                        System.out.println("Updated order item images for product ID: " + product.getProductId());
                    }

                    session.setAttribute("successMessage", "Product updated successfully!");

                    String notificationMessage = "PRODUCT UPDATED by " + adminName + ": \"" + oldProductName + "\" → \"" + product.getProductName() + "\" (ID: #" + product.getProductId() + ")";
                    notificationDAO.createNotificationForAllAdminsExcept(notificationMessage, "PRODUCT_UPDATED", product.getProductId(), currentAdminId);

                    String selfNotification = "You successfully updated product: \"" + product.getProductName() + "\" (ID: #" + product.getProductId() + ")";
                    Notification selfNotif = new Notification(currentAdminId, selfNotification, "ADMIN_ACTION", product.getProductId());
                    notificationDAO.createNotification(selfNotif);

                } else {
                    session.setAttribute("errorMessage", "Failed to update product!");
                }

            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("errorMessage", "Error updating product: " + e.getMessage());
            }
            response.sendRedirect("products");
        }
    }
}