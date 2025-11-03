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

@WebServlet("/RejectBid")
public class RejectBid extends HttpServlet {
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

        String bidIdStr = request.getParameter("bidId");

        try {
            int bidId = Integer.parseInt(bidIdStr);
            boolean isRejected = rejectBid(bidId);

            if (isRejected) {
                request.setAttribute("message", "Bid rejected.");
            } else {
                request.setAttribute("error", "Failed to reject bid.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred.");
        }

        RequestDispatcher rd = request.getRequestDispatcher("exchanges.jsp");
        rd.forward(request, response);
    }

    private boolean rejectBid(int bidId) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "UPDATE Bids SET Status = 'Rejected' WHERE BidID = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, bidId);
                return ps.executeUpdate() > 0;
            }
        }
    }
}
