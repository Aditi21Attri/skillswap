package com.skill;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/bid/create")
public class CreateBidServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        int providerId = (Integer) session.getAttribute("userId");
        String queryIdStr = request.getParameter("queryId");
        String requestedSkillIdStr = request.getParameter("requestedSkillId");
        String offeredSkillIdStr = request.getParameter("offeredSkillId");
        String volunteerStr = request.getParameter("volunteer");
        String message = request.getParameter("message");

        try {
            int queryId = Integer.parseInt(queryIdStr);
            Integer requestedSkillId = (requestedSkillIdStr == null || requestedSkillIdStr.isEmpty()) ? null : Integer.parseInt(requestedSkillIdStr);
            Integer offeredSkillId = (offeredSkillIdStr == null || offeredSkillIdStr.isEmpty()) ? null : Integer.parseInt(offeredSkillIdStr);
            boolean volunteer = "on".equalsIgnoreCase(volunteerStr) || "true".equalsIgnoreCase(volunteerStr);

            // Basic validation: if offeredSkillId provided, ensure provider owns that skill
            if (offeredSkillId != null && !volunteer) {
                boolean owns = false;
                try {
                    java.util.List<SkillDAO.Skill> mySkills = SkillDAO.getUserSkills(providerId);
                    for (SkillDAO.Skill s : mySkills) {
                        if (s.getSkillId() == offeredSkillId) { owns = true; break; }
                    }
                } catch (Exception ex) { ex.printStackTrace(); }

                if (!owns) {
                    request.setAttribute("error", "You cannot offer a skill you do not have.");
                    request.getRequestDispatcher("browse-requests.jsp").forward(request, response);
                    return;
                }
            }

            // Prevent duplicate bid for same query by same provider
            try (java.sql.Connection con = java.sql.DriverManager.getConnection("jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC", "root", "aTTri21..")) {
                String checkSql = "SELECT COUNT(*) as cnt FROM Bids WHERE QueryID = ? AND ProviderID = ?";
                try (java.sql.PreparedStatement ps = con.prepareStatement(checkSql)) {
                    ps.setInt(1, queryId);
                    ps.setInt(2, providerId);
                    try (java.sql.ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt("cnt") > 0) {
                            request.setAttribute("error", "You have already submitted a bid for this request.");
                            request.getRequestDispatcher("browse-requests.jsp").forward(request, response);
                            return;
                        }
                    }
                }
            }

            boolean ok = SkillDAO.createBid(queryId, providerId, requestedSkillId, offeredSkillId, volunteer, message);
            if (ok) {
                request.setAttribute("message", "Bid created successfully.");
            } else {
                request.setAttribute("error", "Failed to create bid.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred.");
        }

        // Redirect back to active swaps or browse page
        request.getRequestDispatcher("browse-requests.jsp").forward(request, response);
    }
}
