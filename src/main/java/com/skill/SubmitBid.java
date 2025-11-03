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

@WebServlet("/SubmitBid")
public class SubmitBid extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    private static final String JDBC_USER = "root";
    private static final String JDBC_PASS = "aTTri21..";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        Integer providerId = (Integer) session.getAttribute("userId");
        String queryIdStr = request.getParameter("queryId");
        String bidDetails = request.getParameter("bidDetails");

        try {
            int queryId = Integer.parseInt(queryIdStr);

            // Step 1: Fetch required skillId for this query
            int skillId = -1;
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
                String getSkillSql = "SELECT SkillID FROM Queries WHERE QueryID = ?";
                try (PreparedStatement psSkill = con.prepareStatement(getSkillSql)) {
                    psSkill.setInt(1, queryId);
                    try (ResultSet rsSkill = psSkill.executeQuery()) {
                        if (rsSkill.next()) {
                            skillId = rsSkill.getInt("SkillID");
                        } else {
                            request.setAttribute("error", "Query not found.");
                            RequestDispatcher rd = request.getRequestDispatcher("browse-requests.jsp");
                            rd.forward(request, response);
                            return;
                        }
                    }
                }

                // Step 2: Check if provider has required skill
                String checkSkillSql = "SELECT UserSkillID FROM UserSkills WHERE UserID = ? AND SkillID = ?";
                try (PreparedStatement ps = con.prepareStatement(checkSkillSql)) {
                    ps.setInt(1, providerId);
                    ps.setInt(2, skillId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            request.setAttribute("error", "You cannot send a proposal without having the required skill.");
                            RequestDispatcher rd = request.getRequestDispatcher("browse-requests.jsp");
                            rd.forward(request, response);
                            return;
                        }
                    }
                }

                // Step 3: Check if user already submitted a bid for this query
                String sql = "SELECT COUNT(*) as count FROM Bids WHERE QueryID = ? AND ProviderID = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, queryId);
                    ps.setInt(2, providerId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt("count") > 0) {
                            request.setAttribute("error", "You have already submitted a bid for this request!");
                            RequestDispatcher rd = request.getRequestDispatcher("browse-requests.jsp");
                            rd.forward(request, response);
                            return;
                        }
                    }
                }

                // Step 4: Submit the bid
                String insertSql = "INSERT INTO Bids (QueryID, ProviderID, BidDetails, Status) VALUES (?, ?, ?, 'Pending')";
                try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                    ps.setInt(1, queryId);
                    ps.setInt(2, providerId);
                    ps.setString(3, bidDetails);
                    int rows = ps.executeUpdate();
                    if (rows > 0) {
                        request.setAttribute("message", "Bid submitted successfully!");
                    } else {
                        request.setAttribute("error", "Failed to submit bid. Please try again.");
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred. Please try again.");
        }

        RequestDispatcher rd = request.getRequestDispatcher("browse-requests.jsp");
        rd.forward(request, response);
    }
}
