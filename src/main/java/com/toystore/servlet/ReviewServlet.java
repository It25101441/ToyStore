package com.toystore.servlet;

import com.toystore.dao.OrderDAO;
import com.toystore.dao.ProductDAO;
import com.toystore.dao.ReviewDAO;
import com.toystore.dao.NotificationDAO;
import com.toystore.model.Order;
import com.toystore.model.OrderItem;
import com.toystore.model.Product;
import com.toystore.model.Review;
import com.toystore.model.User;
import com.toystore.model.Notification;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;
import java.util.ArrayList;

@WebServlet("/reviews")
public class ReviewServlet extends HttpServlet {

    private ReviewDAO reviewDAO = new ReviewDAO();
    private OrderDAO orderDAO = new OrderDAO();
    private ProductDAO productDAO = new ProductDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();

    private boolean isLoggedIn(HttpSession session) {
        return session != null && session.getAttribute("user") != null;
    }

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && user.isAdmin();
    }

    private int getUserId(HttpSession session) {
        User user = (User) session.getAttribute("user");
        return user != null ? user.getUserId() : -1;
    }

    private String getUserDisplayName(HttpSession session) {
        User user = (User) session.getAttribute("user");
        if (user != null) {
            if (user.getFullName() != null && !user.getFullName().isEmpty()) {
                return user.getFullName();
            }
            return user.getUsername();
        }
        return "Customer";
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!isLoggedIn(session)) {
            response.sendRedirect("login");
            return;
        }

        String action = request.getParameter("action");
        int userId = getUserId(session);

        if ("write".equals(action)) {
            // Show write review form for a specific order item
            int orderId = Integer.parseInt(request.getParameter("orderId"));
            int productId = Integer.parseInt(request.getParameter("productId"));

            // Get order details to verify it's delivered
            Order order = null;
            List<Order> orders = orderDAO.getOrdersByUserId(userId);
            for (Order o : orders) {
                if (o.getOrderId() == orderId) {
                    order = o;
                    break;
                }
            }

            if (order == null) {
                session.setAttribute("errorMessage", "Order not found.");
                response.sendRedirect("orders");
                return;
            }

            // Check if order is delivered
            if (!"Delivered".equalsIgnoreCase(order.getOrderStatus())) {
                session.setAttribute("errorMessage", "You can only review products after your order is delivered.");
                response.sendRedirect("orders");
                return;
            }

            // Check if already reviewed
            if (reviewDAO.hasUserReviewedProduct(userId, productId, orderId)) {
                session.setAttribute("errorMessage", "You have already reviewed this product.");
                response.sendRedirect("orders");
                return;
            }

            // Get product details
            Product product = productDAO.getProductById(productId);

            request.setAttribute("orderId", orderId);
            request.setAttribute("productId", productId);
            request.setAttribute("product", product);
            request.getRequestDispatcher("writeReview.jsp").forward(request, response);

        } else if ("delete".equals(action) && isAdmin(session)) {
            // Admin delete review
            int reviewId = Integer.parseInt(request.getParameter("id"));
            Review review = reviewDAO.getReviewById(reviewId);

            if (review != null) {
                boolean deleted = reviewDAO.deleteReview(reviewId);

                if (deleted) {
                    session.setAttribute("successMessage", "Review deleted successfully.");

                    // Notify the user who wrote the review
                    String adminName = getUserDisplayName(session);
                    String notificationMessage = "Your review for \"" + review.getProductName() + "\" has been deleted by admin (" + adminName + ").";
                    Notification userNotif = new Notification(review.getUserId(), notificationMessage, "REVIEW_DELETED", reviewId);
                    notificationDAO.createNotification(userNotif);

                    // Notify all admins except current
                    String adminMessage = "Review deleted by " + adminName + " for product \"" + review.getProductName() + "\" by user " + review.getDisplayName();
                    notificationDAO.createNotificationForAllAdminsExcept(adminMessage, "REVIEW_DELETED", reviewId, getUserId(session));
                } else {
                    session.setAttribute("errorMessage", "Failed to delete review.");
                }
            }
            response.sendRedirect("reviews?action=admin");

        } else if ("admin".equals(action) && isAdmin(session)) {
            // Admin view all reviews with search functionality
            List<Review> allReviews = reviewDAO.getAllReviews();
            String searchKeyword = request.getParameter("search");
            boolean isSearchResult = false;

            // Apply search filter if keyword is provided
            if (searchKeyword != null && !searchKeyword.trim().isEmpty()) {
                String keyword = searchKeyword.trim().toLowerCase();
                List<Review> filteredReviews = new ArrayList<>();

                System.out.println("=== Admin Searching Reviews ===");
                System.out.println("Search keyword: " + keyword);

                for (Review review : allReviews) {
                    boolean matchesCustomerName = false;
                    boolean matchesProductName = false;
                    boolean matchesComment = false;

                    // Search by customer name (username or full name)
                    String userName = review.getUserName() != null ? review.getUserName().toLowerCase() : "";
                    String userFullName = review.getUserFullName() != null ? review.getUserFullName().toLowerCase() : "";
                    String displayName = review.getDisplayName().toLowerCase();

                    if (userName.contains(keyword) || userFullName.contains(keyword) || displayName.contains(keyword)) {
                        matchesCustomerName = true;
                    }

                    // Search by product name
                    String productName = review.getProductName() != null ? review.getProductName().toLowerCase() : "";
                    if (productName.contains(keyword)) {
                        matchesProductName = true;
                    }

                    // Search by review comment
                    String comment = review.getComment() != null ? review.getComment().toLowerCase() : "";
                    if (comment.contains(keyword)) {
                        matchesComment = true;
                    }

                    if (matchesCustomerName || matchesProductName || matchesComment) {
                        filteredReviews.add(review);
                        System.out.println("  Matched review ID: " + review.getReviewId() +
                                " - Customer: " + review.getDisplayName() +
                                ", Product: " + review.getProductName());
                    }
                }

                allReviews = filteredReviews;
                isSearchResult = true;
                request.setAttribute("searchKeyword", searchKeyword.trim());
                request.setAttribute("isSearchResult", true);
                System.out.println("Search results count: " + allReviews.size());
            }

            System.out.println("=== Admin View All Reviews ===");
            System.out.println("Total reviews found: " + (allReviews != null ? allReviews.size() : 0));

            request.setAttribute("reviews", allReviews);
            request.setAttribute("reviewCount", allReviews != null ? allReviews.size() : 0);
            request.getRequestDispatcher("adminReviews.jsp").forward(request, response);

        } else {
            // User view their own reviews (MY REVIEWS)
            List<Review> userReviews = reviewDAO.getReviewsByUserId(userId);

            // Debug print to verify data
            System.out.println("=== My Reviews for User ID: " + userId + " ===");
            System.out.println("Number of reviews found: " + (userReviews != null ? userReviews.size() : 0));
            if (userReviews != null && !userReviews.isEmpty()) {
                for (Review r : userReviews) {
                    System.out.println("  Review ID: " + r.getReviewId() +
                            ", Product: " + r.getProductName() +
                            ", Rating: " + r.getRating() +
                            ", Comment: " + (r.getComment().length() > 50 ? r.getComment().substring(0, 50) : r.getComment()));
                }
            } else {
                System.out.println("  No reviews found for this user.");
            }

            // Make sure to set both attributes even if empty
            request.setAttribute("reviews", userReviews != null ? userReviews : new ArrayList<>());
            request.setAttribute("reviewCount", userReviews != null ? userReviews.size() : 0);
            request.getRequestDispatcher("myReviews.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!isLoggedIn(session)) {
            response.sendRedirect("login");
            return;
        }

        if (isAdmin(session)) {
            session.setAttribute("errorMessage", "Admin accounts cannot write reviews.");
            response.sendRedirect("products");
            return;
        }

        String action = request.getParameter("action");
        int userId = getUserId(session);
        String customerName = getUserDisplayName(session);

        if ("submit".equals(action)) {
            try {
                int productId = Integer.parseInt(request.getParameter("productId"));
                int orderId = Integer.parseInt(request.getParameter("orderId"));
                int rating = Integer.parseInt(request.getParameter("rating"));
                String comment = request.getParameter("comment");

                System.out.println("=== Submitting Review ===");
                System.out.println("User ID: " + userId);
                System.out.println("Product ID: " + productId);
                System.out.println("Order ID: " + orderId);
                System.out.println("Rating: " + rating);
                System.out.println("Comment: " + (comment != null ? comment.substring(0, Math.min(50, comment.length())) : "null"));

                // Validate rating
                if (rating < 1 || rating > 5) {
                    session.setAttribute("errorMessage", "Rating must be between 1 and 5 stars.");
                    response.sendRedirect("orders");
                    return;
                }

                // Validate comment
                if (comment == null || comment.trim().isEmpty()) {
                    session.setAttribute("errorMessage", "Please write a review comment.");
                    response.sendRedirect("reviews?action=write&orderId=" + orderId + "&productId=" + productId);
                    return;
                }

                // Check if already reviewed
                if (reviewDAO.hasUserReviewedProduct(userId, productId, orderId)) {
                    session.setAttribute("errorMessage", "You have already reviewed this product.");
                    response.sendRedirect("orders");
                    return;
                }

                // Get product name
                Product product = productDAO.getProductById(productId);
                String productName = product != null ? product.getProductName() : "Product";

                // Create review
                Review review = new Review(userId, productId, orderId, rating, comment.trim());
                boolean added = reviewDAO.addReview(review);

                if (added) {
                    session.setAttribute("successMessage", "Thank you for your review!");

                    System.out.println("✅ Review added successfully - User: " + customerName +
                            ", Product: " + productName +
                            ", Rating: " + rating +
                            ", Review ID: " + review.getReviewId());

                    // Send notification to the customer
                    String customerMessage = "Thank you for reviewing \"" + productName + "\"! Your feedback helps us improve.";
                    Notification customerNotif = new Notification(userId, customerMessage, "REVIEW_ADDED", review.getReviewId());
                    notificationDAO.createNotification(customerNotif);

                    // Send notification to all admins
                    String adminMessage = "New review posted by " + customerName + " for \"" + productName + "\" - Rating: " + rating + "/5 stars";
                    notificationDAO.createNotificationForAllAdmins(adminMessage, "NEW_REVIEW", review.getReviewId());

                } else {
                    session.setAttribute("errorMessage", "Failed to submit review. Please try again.");
                    System.err.println("❌ Failed to add review for user " + userId);
                }

                response.sendRedirect("orders");

            } catch (NumberFormatException e) {
                System.err.println("❌ Number format error: " + e.getMessage());
                session.setAttribute("errorMessage", "Invalid input. Please try again.");
                response.sendRedirect("orders");
            } catch (Exception e) {
                System.err.println("❌ Exception in doPost: " + e.getMessage());
                e.printStackTrace();
                session.setAttribute("errorMessage", "Error: " + e.getMessage());
                response.sendRedirect("orders");
            }
        }
    }
}