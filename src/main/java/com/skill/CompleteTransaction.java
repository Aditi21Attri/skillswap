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

@WebServlet("/CompleteTransaction")
public class CompleteTransaction extends HttpServlet {
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

        String transactionIdStr = request.getParameter("transactionId");

        if (transactionIdStr == null) {
            request.setAttribute("error", "Missing transaction id.");
            request.getRequestDispatcher("exchanges.jsp").forward(request, response);
            return;
        }

        try {
            int transactionId = Integer.parseInt(transactionIdStr);

            // If the request is the initial 'mark completed' action, show the review form first
            if (request.getParameter("reviewSubmitted") == null && request.getParameter("skipReview") == null) {
                // Forward to review form where user can submit rating/comments or skip
                request.setAttribute("transactionId", transactionId);
                request.getRequestDispatcher("review.jsp").forward(request, response);
                return;
            }

            // At this point reviewSubmitted or skipReview is present — persist review (if any) then mark completed
            int reviewerId = (Integer) request.getSession().getAttribute("userId");

            // determine reviewee (the other participant)
            int revieweeId = -1;
            try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
                 PreparedStatement ps = con.prepareStatement("SELECT RequesterID, ProviderID FROM Transactions WHERE TransactionID = ?")) {
                ps.setInt(1, transactionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        int requester = rs.getInt("RequesterID");
                        int provider = rs.getInt("ProviderID");
                        revieweeId = (reviewerId == requester) ? provider : requester;
                    }
                }
            }

            // Insert review if submitted or create skipped review marker
            try {
                if (request.getParameter("skipReview") != null) {
                    // create a skipped review row so we know reviewer declined
                    com.skill.ReviewDAO.insertReview(transactionId, reviewerId, revieweeId, null, null, true);
                } else {
                    String ratingStr = request.getParameter("rating");
                    Integer rating = null;
                    if (ratingStr != null && !ratingStr.trim().isEmpty()) {
                        try { rating = Integer.parseInt(ratingStr); } catch (NumberFormatException ignored) {}
                    }
                    String comments = request.getParameter("comments");
                    com.skill.ReviewDAO.insertReview(transactionId, reviewerId, revieweeId, rating, comments, false);
                }
            } catch (Exception re) {
                // log but continue to complete the transaction
                re.printStackTrace();
            }

            boolean isCompleted = completeTransaction(transactionId);

            if (isCompleted) {
                request.setAttribute("message", "Transaction marked as completed!");
            } else {
                request.setAttribute("error", "Failed to complete transaction.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred.");
        }

        RequestDispatcher rd = request.getRequestDispatcher("exchanges.jsp");
        rd.forward(request, response);
    }

    private boolean completeTransaction(int transactionId) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            con.setAutoCommit(false);
            
            try {
                // Update transaction status
                String updateTransSql = "UPDATE Transactions SET Status = 'Completed', EndDate = NOW() WHERE TransactionID = ?";
                try (PreparedStatement ps = con.prepareStatement(updateTransSql)) {
                    ps.setInt(1, transactionId);
                    ps.executeUpdate();
                }

                // Update associated query to Completed
                String updateQuerySql = "UPDATE Queries q JOIN Transactions t ON q.QueryID = t.QueryID SET q.Status = 'Completed' WHERE t.TransactionID = ?";
                try (PreparedStatement ps = con.prepareStatement(updateQuerySql)) {
                    ps.setInt(1, transactionId);
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
