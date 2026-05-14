package com.toystore.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;

@WebServlet("/uploadImage")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
        maxFileSize = 1024 * 1024 * 10,       // 10MB
        maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class ImageUploadServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "images";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Get the product ID from request
        String productId = request.getParameter("productId");
        String action = request.getParameter("action");

        Part filePart = request.getPart("productImage");
        String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();

        // Generate unique filename to avoid conflicts
        String fileExtension = "";
        if (fileName.contains(".")) {
            fileExtension = fileName.substring(fileName.lastIndexOf("."));
        }
        String uniqueFileName = System.currentTimeMillis() + "_" + productId + fileExtension;

        // Get the absolute path to the webapp directory
        String applicationPath = request.getServletContext().getRealPath("");
        String uploadFilePath = applicationPath + File.separator + UPLOAD_DIR;

        // Create directory if it doesn't exist
        File uploadDir = new File(uploadFilePath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        // Save the file
        String filePath = uploadFilePath + File.separator + uniqueFileName;
        filePart.write(filePath);

        // Store the image URL in session to be used by addProduct or updateProduct
        request.getSession().setAttribute("uploadedImageName", uniqueFileName);

        // Redirect back to the appropriate form
        if ("edit".equals(action)) {
            response.sendRedirect("products?action=edit&id=" + productId + "&imageUploaded=true");
        } else {
            response.sendRedirect("products?action=add&imageUploaded=true");
        }
    }
}