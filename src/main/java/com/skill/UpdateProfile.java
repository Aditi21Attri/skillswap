package com.skill;

import java.io.IOException;
import java.sql.*;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/UpdateProfile")
public class UpdateProfile extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Database credentials
    private static final String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    private static final String JDBC_USER = "root";
    private static final String JDBC_PASS = "aTTri21..";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check if user is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");
        
        // Get form data
        String username = request.getParameter("username");
        String fullName = request.getParameter("fullName");
        String bio = request.getParameter("bio");

        // Check if username is already taken by another user
        if (isUsernameTaken(username, userId)) {
            request.setAttribute("error", "Username is already taken. Please choose a different username.");
            RequestDispatcher rd = request.getRequestDispatcher("profile.jsp");
            rd.forward(request, response);
            return;
        }

        // Update profile in database
        boolean isUpdated = updateUserProfile(userId, username, fullName, bio);

        if (isUpdated) {
            // Update session attributes
            session.setAttribute("username", username);
            session.setAttribute("fullName", fullName);
            
            // Send success message
            request.setAttribute("message", "Profile updated successfully!");
            RequestDispatcher rd = request.getRequestDispatcher("profile.jsp");
            rd.forward(request, response);
        } else {
            // Send error message
            request.setAttribute("error", "Failed to update profile. Please try again.");
            RequestDispatcher rd = request.getRequestDispatcher("profile.jsp");
            rd.forward(request, response);
        }
    }

    private boolean isUsernameTaken(String username, int currentUserId) {
        boolean isTaken = false;

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
                // Check if username exists for a different user
                String sql = "SELECT COUNT(*) as count FROM Users WHERE Username = ? AND UserID != ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, username);
                    ps.setInt(2, currentUserId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt("count") > 0) {
                            isTaken = true;
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return isTaken;
    }

    private boolean updateUserProfile(int userId, String username, String fullName, String bio) {
        boolean isUpdated = false;

        try {
            // Load JDBC driver
            Class.forName("com.mysql.cj.jdbc.Driver");

            // Open connection
            try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
                String sql = "UPDATE Users SET Username = ?, FullName = ?, Bio = ? WHERE UserID = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, username);
                    ps.setString(2, fullName);
                    ps.setString(3, bio);
                    ps.setInt(4, userId);
                    
                    int rowsAffected = ps.executeUpdate();
                    if (rowsAffected > 0) {
                        isUpdated = true;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return isUpdated;
    }
}
