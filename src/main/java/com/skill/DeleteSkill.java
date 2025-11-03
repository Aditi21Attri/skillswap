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

@WebServlet("/DeleteSkill")
public class DeleteSkill extends HttpServlet {
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

        Integer userId = (Integer) session.getAttribute("userId");
        String userSkillIdStr = request.getParameter("userSkillId");

        try {
            int userSkillId = Integer.parseInt(userSkillIdStr);
            boolean isDeleted = deleteUserSkill(userId, userSkillId);

            if (isDeleted) {
                // Update skill count in session
                Integer currentCount = (Integer) session.getAttribute("skillCount");
                if (currentCount != null && currentCount > 0) {
                    session.setAttribute("skillCount", currentCount - 1);
                }
                
                request.setAttribute("message", "Skill deleted successfully!");
            } else {
                request.setAttribute("error", "Failed to delete skill.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred. Please try again.");
        }

        RequestDispatcher rd = request.getRequestDispatcher("my-skills.jsp");
        rd.forward(request, response);
    }

    private boolean deleteUserSkill(int userId, int userSkillId) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "DELETE FROM UserSkills WHERE UserSkillID = ? AND UserID = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userSkillId);
                ps.setInt(2, userId);
                int rows = ps.executeUpdate();
                return rows > 0;
            }
        }
    }
}
