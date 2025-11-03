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

@WebServlet("/AddSkill")
public class AddSkill extends HttpServlet {
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
        String skillName = request.getParameter("skillName");

        try {
            // First, check if skill exists in Skills table, if not add it
            int skillId = getOrCreateSkillId(skillName);

            // Check if user already has this skill
            if (userAlreadyHasSkill(userId, skillId)) {
                request.setAttribute("error", "You already have this skill!");
                RequestDispatcher rd = request.getRequestDispatcher("my-skills.jsp");
                rd.forward(request, response);
                return;
            }

            // Add skill to UserSkills table
            boolean isAdded = addUserSkill(userId, skillId);

            if (isAdded) {
                // Update skill count in session
                Integer currentCount = (Integer) session.getAttribute("skillCount");
                session.setAttribute("skillCount", (currentCount != null ? currentCount : 0) + 1);
                
                request.setAttribute("message", "Skill added successfully!");
            } else {
                request.setAttribute("error", "Failed to add skill. Please try again.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred. Please try again.");
        }

        RequestDispatcher rd = request.getRequestDispatcher("my-skills.jsp");
        rd.forward(request, response);
    }

    private int getOrCreateSkillId(String skillName) throws Exception {
        int skillId = -1;

        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            // Check if skill exists
            String checkSql = "SELECT SkillID FROM Skills WHERE SkillName = ?";
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setString(1, skillName);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        skillId = rs.getInt("SkillID");
                    }
                }
            }

            // If skill doesn't exist, create it
            if (skillId == -1) {
                String insertSql = "INSERT INTO Skills (SkillName) VALUES (?)";
                try (PreparedStatement ps = con.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, skillName);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (rs.next()) {
                            skillId = rs.getInt(1);
                        }
                    }
                }
            }
        }

        return skillId;
    }

    private boolean userAlreadyHasSkill(int userId, int skillId) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "SELECT COUNT(*) as count FROM UserSkills WHERE UserID = ? AND SkillID = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setInt(2, skillId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt("count") > 0) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private boolean addUserSkill(int userId, int skillId) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "INSERT INTO UserSkills (UserID, SkillID) VALUES (?, ?)";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setInt(2, skillId);
                int rows = ps.executeUpdate();
                return rows > 0;
            }
        }
    }
}
