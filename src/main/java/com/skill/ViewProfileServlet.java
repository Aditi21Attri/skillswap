package com.skill;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/profile")
public class ViewProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr == null) {
            response.sendRedirect("browse-requests.jsp");
            return;
        }

        try {
            // Ensure user is logged in (viewer)
            Object sessUid = request.getSession().getAttribute("userId");
            if (sessUid == null) {
                response.sendRedirect("index.jsp");
                return;
            }

            int userId = Integer.parseInt(idStr);
            SkillDAO.UserProfile profile = SkillDAO.getUserProfile(userId);
            if (profile == null) {
                request.setAttribute("error", "User not found.");
                request.getRequestDispatcher("browse-requests.jsp").forward(request, response);
                return;
            }

            request.setAttribute("profile", profile);
            request.setAttribute("skills", SkillDAO.getUserSkills(userId));

            // Also load logged-in viewer's own skills for the offered-skill dropdown
            int viewerId = (sessUid instanceof Integer) ? (Integer) sessUid : Integer.parseInt(sessUid.toString());
            request.setAttribute("mySkills", SkillDAO.getUserSkills(viewerId));
            // Fetch user's open requests (to display on profile read-only)
            request.setAttribute("profileRequests", SkillDAO.getOpenQueriesByUser(userId));
            request.getRequestDispatcher("profile.jsp").forward(request, response);
        } catch (Exception e) {
            // Log full stack trace to server logs for debugging
            e.printStackTrace();
            // Provide a concise error message to the UI with exception class and message to aid debugging
            String errMsg = "An error occurred while loading profile: " + e.getClass().getSimpleName() + " - " + (e.getMessage() != null ? e.getMessage() : "(no message)");
            request.setAttribute("error", errMsg);
            // Optionally expose stack trace to the request for debugging (commented out for security);
            // StringWriter sw = new StringWriter(); e.printStackTrace(new PrintWriter(sw)); request.setAttribute("devStack", sw.toString());
            request.getRequestDispatcher("browse-requests.jsp").forward(request, response);
        }
    }
}
