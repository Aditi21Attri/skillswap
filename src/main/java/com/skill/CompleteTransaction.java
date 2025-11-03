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

        try {
            int transactionId = Integer.parseInt(transactionIdStr);
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
