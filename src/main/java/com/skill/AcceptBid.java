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

@WebServlet("/AcceptBid")
public class AcceptBid extends HttpServlet {
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

        Integer requesterId = (Integer) session.getAttribute("userId");
        String bidIdStr = request.getParameter("bidId");
        String queryIdStr = request.getParameter("queryId");

        try {
            int bidId = Integer.parseInt(bidIdStr);
            int queryId = Integer.parseInt(queryIdStr);

            // Accept the bid and create transaction
            boolean isAccepted = acceptBidAndCreateTransaction(bidId, queryId, requesterId);

            if (isAccepted) {
                request.setAttribute("message", "Bid accepted successfully! Transaction created.");
            } else {
                request.setAttribute("error", "Failed to accept bid. Please try again.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred. Please try again.");
        }

        RequestDispatcher rd = request.getRequestDispatcher("exchanges.jsp");
        rd.forward(request, response);
    }

    private boolean acceptBidAndCreateTransaction(int bidId, int queryId, int requesterId) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            con.setAutoCommit(false);

            try {
                // Get provider ID and skill ID from bid
                int providerId = -1;
                int providerSkillId = -1;
                
                String getBidSql = "SELECT b.ProviderID, q.SkillID FROM Bids b JOIN Queries q ON b.QueryID = q.QueryID WHERE b.BidID = ?";
                try (PreparedStatement ps = con.prepareStatement(getBidSql)) {
                    ps.setInt(1, bidId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            providerId = rs.getInt("ProviderID");
                            
                            // Get provider's UserSkillID for this skill
                            int skillId = rs.getInt("SkillID");
                            String getProviderSkillSql = "SELECT UserSkillID FROM UserSkills WHERE UserID = ? AND SkillID = ? LIMIT 1";
                            try (PreparedStatement ps2 = con.prepareStatement(getProviderSkillSql)) {
                                ps2.setInt(1, providerId);
                                ps2.setInt(2, skillId);
                                try (ResultSet rs2 = ps2.executeQuery()) {
                                    if (rs2.next()) {
                                        providerSkillId = rs2.getInt("UserSkillID");
                                    }
                                }
                            }
                        }
                    }
                }

                if (providerId == -1 || providerSkillId == -1) {
                    con.rollback();
                    return false;
                }

                // Update bid status to Accepted
                String updateBidSql = "UPDATE Bids SET Status = 'Accepted' WHERE BidID = ?";
                try (PreparedStatement ps = con.prepareStatement(updateBidSql)) {
                    ps.setInt(1, bidId);
                    ps.executeUpdate();
                }

                // Reject all other bids for this query
                String rejectOthersSql = "UPDATE Bids SET Status = 'Rejected' WHERE QueryID = ? AND BidID != ?";
                try (PreparedStatement ps = con.prepareStatement(rejectOthersSql)) {
                    ps.setInt(1, queryId);
                    ps.setInt(2, bidId);
                    ps.executeUpdate();
                }

                // Update query status to In Progress
                String updateQuerySql = "UPDATE Queries SET Status = 'In Progress' WHERE QueryID = ?";
                try (PreparedStatement ps = con.prepareStatement(updateQuerySql)) {
                    ps.setInt(1, queryId);
                    ps.executeUpdate();
                }

                // Create transaction
                String createTransSql = "INSERT INTO Transactions (QueryID, ProviderID, RequesterID, ProviderSkillID, ExchangeType, Status) " +
                                       "VALUES (?, ?, ?, ?, 'Free', 'Ongoing')";
                try (PreparedStatement ps = con.prepareStatement(createTransSql)) {
                    ps.setInt(1, queryId);
                    ps.setInt(2, providerId);
                    ps.setInt(3, requesterId);
                    ps.setInt(4, providerSkillId);
                    ps.executeUpdate();
                }

                con.commit();
                return true;
            } catch (Exception e) {
                con.rollback();
                throw e;
            }
        }
    }
}
