package com.skill;

import java.io.IOException;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/active-swaps")
public class ActiveSwapsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        int providerId = (Integer) session.getAttribute("userId");
        try {
            List<SkillDAO.ProviderBidView> bids = SkillDAO.getBidsByProvider(providerId);
            request.setAttribute("providerBids", bids);
            request.getRequestDispatcher("activeSwaps.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Unable to load your active swaps.");
            request.getRequestDispatcher("dashboard.jsp").forward(request, response);
        }
    }
}
