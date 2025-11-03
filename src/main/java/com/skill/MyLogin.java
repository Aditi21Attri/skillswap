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

@WebServlet("/MyLogin")
public class MyLogin extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Database credentials
    private static final String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    private static final String JDBC_USER = "root";
    private static final String JDBC_PASS = "aTTri21..";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Get user input from login form
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        // Check credentials and get user details
        UserDetails userDetails = authenticateUser(email, password);

        if (userDetails != null) {
            // Create session for logged-in user
            HttpSession session = request.getSession();
            session.setAttribute("userEmail", email);
            session.setAttribute("userId", userDetails.getUserId());
            session.setAttribute("username", userDetails.getUsername());
            session.setAttribute("fullName", userDetails.getFullName());
            
            // Get and store user statistics
            int[] stats = getUserStatistics(userDetails.getUserId());
            session.setAttribute("skillCount", stats[0]);
            session.setAttribute("exchangeCount", stats[1]);
            session.setAttribute("messageCount", stats[2]);

            // Redirect to dashboard
            response.sendRedirect("dashboard.jsp");
        } else {
            // Send error message back to login page
            request.setAttribute("message", "Invalid email or password. Please try again.");
            RequestDispatcher rd = request.getRequestDispatcher("index.jsp");
            rd.forward(request, response);
        }
    }

    private UserDetails authenticateUser(String email, String password) {
        UserDetails userDetails = null;

        try {
            // Load JDBC driver
            Class.forName("com.mysql.cj.jdbc.Driver");

            // Open connection
            try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
                String sql = "SELECT UserID, Username, FullName, Email FROM Users WHERE Email = ? AND PasswordHash = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, email);
                    ps.setString(2, password);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            userDetails = new UserDetails();
                            userDetails.setUserId(rs.getInt("UserID"));
                            userDetails.setUsername(rs.getString("Username"));
                            userDetails.setFullName(rs.getString("FullName"));
                            userDetails.setEmail(rs.getString("Email"));
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return userDetails;
    }
    
    private int[] getUserStatistics(int userId) {
        int[] stats = new int[3]; // [skillCount, activeTransactions, pendingBids]
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
                // Count user's skills
                String skillSql = "SELECT COUNT(*) as count FROM UserSkills WHERE UserID = ?";
                try (PreparedStatement ps = con.prepareStatement(skillSql)) {
                    ps.setInt(1, userId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            stats[0] = rs.getInt("count");
                        }
                    }
                }
                
                // Count active transactions (as provider or requester)
                String transactionSql = "SELECT COUNT(*) as count FROM Transactions WHERE (ProviderID = ? OR RequesterID = ?) AND Status = 'Ongoing'";
                try (PreparedStatement ps = con.prepareStatement(transactionSql)) {
                    ps.setInt(1, userId);
                    ps.setInt(2, userId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            stats[1] = rs.getInt("count");
                        }
                    }
                }
                
                // Count pending bids (received on user's queries)
                String bidsSql = "SELECT COUNT(*) as count FROM Bids b JOIN Queries q ON b.QueryID = q.QueryID WHERE q.RequesterID = ? AND b.Status = 'Pending'";
                try (PreparedStatement ps = con.prepareStatement(bidsSql)) {
                    ps.setInt(1, userId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            stats[2] = rs.getInt("count");
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        return stats;
    }

    // Inner class to hold user details
    private class UserDetails {
        private int userId;
        private String username;
        private String fullName;
        private String email;

        public int getUserId() {
            return userId;
        }

        public void setUserId(int userId) {
            this.userId = userId;
        }

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getFullName() {
            return fullName;
        }

        public void setFullName(String fullName) {
            this.fullName = fullName;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }
    }
}
