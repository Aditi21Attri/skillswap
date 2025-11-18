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
        String offeredSkillStr = request.getParameter("offeredSkillId");
        String wantedSkillStr = request.getParameter("wantedSkillId");
        String isVolunteerStr = request.getParameter("isVolunteer");

        // EXTRA DEBUG: dump parameter map and query string to help trace missing fields
        try {
            System.out.println("[SubmitBid] Request QueryString: " + request.getQueryString());
            java.util.Map<String, String[]> pm = request.getParameterMap();
            System.out.println("[SubmitBid] Parameter map:");
            for (java.util.Map.Entry<String, String[]> e : pm.entrySet()) {
                String k = e.getKey();
                String[] vals = e.getValue();
                String joined = vals == null ? "null" : String.join("|", vals);
                System.out.println("[SubmitBid]   " + k + " = [" + joined + "]");
            }
            System.out.flush();
        } catch (Exception dx) {
            System.out.println("[SubmitBid] Failed to dump parameter map: " + dx);
        }

        try {
            int queryId = Integer.parseInt(queryIdStr);
            // Temporary debug logging
            System.out.println("[SubmitBid] providerId=" + providerId + " queryIdStr=" + queryIdStr + " offeredSkillStr=" + offeredSkillStr + " wantedSkillStr=" + wantedSkillStr + " isVolunteerStr=" + isVolunteerStr + " bidDetails=" + (bidDetails!=null?bidDetails.replaceAll("\n"," "):""));

            // determine volunteer early so we allow volunteers even if they don't have the requested skill
            boolean volunteer = false;
            if (isVolunteerStr != null && (isVolunteerStr.equals("1") || isVolunteerStr.equalsIgnoreCase("true"))) {
                volunteer = true;
            }

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

                // Step 2: Check if provider has required skill (skip check for volunteers)
                if (!volunteer) {
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

                // Step 4: Submit the bid (include requested/offered skill and volunteer flag)
                Integer offeredSkillId = null;
                Integer wantedSkillId = null;
                if (offeredSkillStr != null && !offeredSkillStr.trim().isEmpty()) {
                    try { offeredSkillId = Integer.parseInt(offeredSkillStr); } catch(NumberFormatException nfe) { offeredSkillId = null; }
                }
                if (wantedSkillStr != null && !wantedSkillStr.trim().isEmpty()) {
                    try { wantedSkillId = Integer.parseInt(wantedSkillStr); } catch(NumberFormatException nfe) { wantedSkillId = null; }
                }

                // Validate offeredSkillId belongs to provider (prevent client tampering)
                if (offeredSkillId != null) {
                    String checkOffSql = "SELECT UserSkillID FROM UserSkills WHERE UserID = ? AND SkillID = ?";
                    try (PreparedStatement chk = con.prepareStatement(checkOffSql)) {
                        chk.setInt(1, providerId);
                        chk.setInt(2, offeredSkillId);
                        try (ResultSet rchk = chk.executeQuery()) {
                            if (!rchk.next()) {
                                request.setAttribute("error", "Invalid offered skill selection.");
                                RequestDispatcher rd = request.getRequestDispatcher("browse-requests.jsp");
                                rd.forward(request, response);
                                return;
                            }
                        }
                    }
                }

                String insertSql = "INSERT INTO Bids (QueryID, ProviderID, RequestedSkillID, WantedSkillID, OfferedSkillID, Volunteer, BidDetails, Status) VALUES (?, ?, ?, ?, ?, ?, ?, 'Pending')";
                System.out.println("[SubmitBid] About to execute insert SQL: " + insertSql);
                try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                    ps.setInt(1, queryId);
                    ps.setInt(2, providerId);
                    // use the query's skillId as the requested skill (ignore client tampering)
                    if (skillId <= 0) ps.setNull(3, Types.INTEGER); else ps.setInt(3, skillId);
                    if (wantedSkillId == null) ps.setNull(4, Types.INTEGER); else ps.setInt(4, wantedSkillId);
                    if (offeredSkillId == null) ps.setNull(5, Types.INTEGER); else ps.setInt(5, offeredSkillId);
                    ps.setBoolean(6, volunteer);
                    ps.setString(7, bidDetails);
                    int rows = ps.executeUpdate();
                    System.out.println("[SubmitBid] Insert affected rows=" + rows);
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
