package com.toystore.servlet;

import com.toystore.dao.CartDAO;
import com.toystore.dao.ProductDAO;
import com.toystore.model.CartItem;
import com.toystore.model.Product;
import com.toystore.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

@WebServlet("/cart")
public class CartServlet extends HttpServlet {

    private CartDAO cartDAO = new CartDAO();
    private ProductDAO productDAO = new ProductDAO();

    // Helper method to check if user is admin
    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && user.isAdmin();
    }

    // Helper method to check if user is logged in
    private boolean isLoggedIn(HttpSession session) {
        return session != null && session.getAttribute("user") != null;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        // Check if this is an AJAX request for cart count
        String ajax = request.getParameter("ajax");
        if ("count".equals(ajax)) {
            if (isLoggedIn(session)) {
                Integer userId = (Integer) session.getAttribute("userId");
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                PrintWriter out = response.getWriter();
                int count = cartDAO.getTotalCartItemCount(userId);
                out.print("{\"cartItemCount\": " + count + "}");
                out.flush();
            } else {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                PrintWriter out = response.getWriter();
                out.print("{\"cartItemCount\": 0}");
                out.flush();
            }
            return;
        }

        // Check if user is logged in for cart operations
        if (!isLoggedIn(session)) {
            response.sendRedirect("login");
            return;
        }

        // BLOCK ADMIN FROM ACCESSING CART
        if (isAdmin(session)) {
            session.setAttribute("errorMessage", "Admin accounts cannot access shopping cart. Admin is for managing products and orders only.");
            response.sendRedirect("products");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");
        String action = request.getParameter("action");

        System.out.println("=== CartServlet doGet called ===");
        System.out.println("User ID: " + userId);
        System.out.println("Action: " + action);

        if (action == null) {
            // Show cart page
            List<CartItem> cartItems = cartDAO.getCartItems(userId);
            double total = 0;
            if (cartItems != null) {
                for (CartItem item : cartItems) {
                    total += item.getSubtotal();
                }
            }

            System.out.println("Cart items count: " + (cartItems != null ? cartItems.size() : 0));
            System.out.println("Total: " + total);

            request.setAttribute("cartItems", cartItems);
            request.setAttribute("total", total);
            request.getRequestDispatcher("cart.jsp").forward(request, response);

        } else if (action.equals("remove")) {
            int cartItemId = Integer.parseInt(request.getParameter("cartItemId"));
            cartDAO.removeFromCart(cartItemId);
            response.sendRedirect("cart");

        } else if (action.equals("update")) {
            int cartItemId = Integer.parseInt(request.getParameter("cartItemId"));
            int quantity = Integer.parseInt(request.getParameter("quantity"));
            if (quantity > 0) {
                cartDAO.updateCartItemQuantity(cartItemId, quantity);
            } else {
                cartDAO.removeFromCart(cartItemId);
            }
            response.sendRedirect("cart");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("=== CartServlet doPost called ===");

        HttpSession session = request.getSession();

        // Check if user is logged in
        if (!isLoggedIn(session)) {
            System.out.println("User not logged in!");
            response.sendRedirect("login");
            return;
        }

        // BLOCK ADMIN FROM ADDING TO CART
        if (isAdmin(session)) {
            System.out.println("Admin tried to add to cart - BLOCKED!");
            session.setAttribute("errorMessage", "Admin accounts cannot add items to cart. Admin is for managing products and orders only.");
            response.sendRedirect("products");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");
        String action = request.getParameter("action");
        System.out.println("Action: " + action);

        if (action != null && action.equals("add")) {
            try {
                int productId = Integer.parseInt(request.getParameter("productId"));
                int quantity = Integer.parseInt(request.getParameter("quantity"));

                System.out.println("Product ID: " + productId);
                System.out.println("Quantity: " + quantity);

                Product product = productDAO.getProductById(productId);
                if (product != null) {
                    System.out.println("Product found: " + product.getProductName());

                    if (product.getStockQuantity() >= quantity) {
                        boolean added = cartDAO.addToCart(userId, productId, quantity);
                        System.out.println("Added to cart result: " + added);

                        if (added) {
                            session.setAttribute("cartMessage", "✅ " + product.getProductName() + " added to cart!");
                        } else {
                            session.setAttribute("cartError", "Failed to add product to cart");
                        }
                    } else {
                        session.setAttribute("cartError", "Insufficient stock! Only " + product.getStockQuantity() + " available");
                    }
                } else {
                    session.setAttribute("cartError", "Product not found!");
                }

                response.sendRedirect("products");

            } catch (NumberFormatException e) {
                System.out.println("Number format error: " + e.getMessage());
                session.setAttribute("cartError", "Invalid product or quantity");
                response.sendRedirect("products");
            } catch (Exception e) {
                System.out.println("Exception: " + e.getMessage());
                e.printStackTrace();
                session.setAttribute("cartError", "Error: " + e.getMessage());
                response.sendRedirect("products");
            }
        }
    }
}