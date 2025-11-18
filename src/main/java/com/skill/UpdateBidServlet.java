package com.skill;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/bid/update")
public class UpdateBidServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        int providerId = (Integer) session.getAttribute("userId");
        String bidIdStr = request.getParameter("bidId");
        String offeredSkillIdStr = request.getParameter("offeredSkillId");
        String volunteerStr = request.getParameter("volunteer");

        try {
            int bidId = Integer.parseInt(bidIdStr);
            Integer offeredSkillId = (offeredSkillIdStr == null || offeredSkillIdStr.isEmpty()) ? null : Integer.parseInt(offeredSkillIdStr);
            boolean volunteer = "on".equalsIgnoreCase(volunteerStr) || "true".equalsIgnoreCase(volunteerStr);

            boolean ok = SkillDAO.updateBidOffer(bidId, providerId, offeredSkillId, volunteer);
            if (ok) {
                request.setAttribute("message", "Bid updated successfully.");
            } else {
                request.setAttribute("error", "Unable to update the bid. Make sure you own the bid.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred.");
        }

        request.getRequestDispatcher("active-swaps").forward(request, response);
    }
}
