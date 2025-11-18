package com.skill;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/send-message")
public class SendMessage extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Object uidObj = request.getSession().getAttribute("userId");
        if (uidObj == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        int userId;
        try { userId = Integer.parseInt(uidObj.toString()); } catch (Exception e) { response.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }

        String tidStr = request.getParameter("transactionId");
        String content = request.getParameter("content");
        if (tidStr == null || content == null || content.trim().isEmpty()) {
            response.sendRedirect(request.getHeader("referer") != null ? request.getHeader("referer") : "messages.jsp");
            return;
        }
        int tid;
        try { tid = Integer.parseInt(tidStr); } catch (NumberFormatException e) { response.sendError(HttpServletResponse.SC_BAD_REQUEST); return; }

        try {
            if (!MessageDAO.isParticipant(tid, userId)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }
            MessageDAO.insertMessage(tid, userId, content.trim());
            // Redirect back to thread
            response.sendRedirect("messages-thread.jsp?transactionId=" + tid);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
