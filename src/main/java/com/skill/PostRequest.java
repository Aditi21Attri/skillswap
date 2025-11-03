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

@WebServlet("/PostRequest")
public class PostRequest extends HttpServlet {
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
        String title = request.getParameter("title");
        String description = request.getParameter("description");
        String skillIdStr = request.getParameter("skillId");

        try {
            int skillId = Integer.parseInt(skillIdStr);

            // Insert the query into database
            boolean isPosted = postQuery(requesterId, title, description, skillId);

            if (isPosted) {
                request.setAttribute("message", "Request posted successfully! Others can now see and bid on your request.");
                
                // Optionally redirect to browse page after success
                // response.sendRedirect("browse-requests.jsp");
                // return;
            } else {
                request.setAttribute("error", "Failed to post request. Please try again.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred. Please try again.");
        }

        RequestDispatcher rd = request.getRequestDispatcher("post-request.jsp");
        rd.forward(request, response);
    }

    private boolean postQuery(int requesterId, String title, String description, int skillId) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "INSERT INTO Queries (RequesterID, Title, Description, SkillID, Status) VALUES (?, ?, ?, ?, 'Open')";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, requesterId);
                ps.setString(2, title);
                ps.setString(3, description);
                ps.setInt(4, skillId);
                int rows = ps.executeUpdate();
                return rows > 0;
            }
        }
    }
}
