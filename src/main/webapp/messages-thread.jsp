<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="com.skill.MessageDAO" %>
<%!
    private String esc(Object o) {
        if (o == null) return "";
        String s = o.toString();
        return s.replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }
%>

<%
    Object uidObj = session.getAttribute("userId");
    if (uidObj == null) { response.sendRedirect("index.jsp"); return; }

    int userId;
    try { userId = Integer.parseInt(uidObj.toString()); }
    catch (Exception e) { response.sendRedirect("index.jsp"); return; }

    String tidParam = request.getParameter("transactionId");
    if (tidParam == null) { response.sendRedirect("messages.jsp"); return; }

    int transactionId;
    try { transactionId = Integer.parseInt(tidParam); }
    catch (NumberFormatException e) { response.sendRedirect("messages.jsp"); return; }

    try { if (!MessageDAO.isParticipant(transactionId, userId)) { response.sendError(403); return; } }
    catch (Exception e) { throw new RuntimeException(e); }

    List<Map<String,Object>> messages = Collections.emptyList();
    try { messages = MessageDAO.getMessagesForTransaction(transactionId, 200); }
    catch (Exception e) { e.printStackTrace(); }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Conversation</title>

    <style>
        body {
            background: #f7f9fc;
            font-family: "Segoe UI", Inter, sans-serif;
            margin: 0;
            padding: 0;
        }

        /* HEADER */
        .header {
            background: linear-gradient(90deg, #715aff, #4a7bf7);
            padding: 22px 40px;
            color: white;
            font-size: 28px;
            font-weight: 700;
        }

        /* MAIN CARD */
        .chat-box {
            max-width: 900px;
            margin: 30px auto;
            background: white;
            border-radius: 16px;
            padding: 20px 28px;
            box-shadow: 0 6px 20px rgba(0,0,0,0.08);
        }

        .back-btn {
            padding: 8px 16px;
            color: #4a7bf7;
            background: #eaf0ff;
            border-radius: 8px;
            border: none;
            cursor: pointer;
            font-size: 14px;
            margin-bottom: 16px;
        }

        #messages {
            max-height: 65vh;
            overflow-y: auto;
            padding: 6px 0;
        }

        /* BUBBLES */
        .msg {
            padding: 12px 16px;
            border-radius: 14px;
            margin: 12px 0;
            max-width: 70%;
            font-size: 15px;
            line-height: 1.4;
        }

        .msg.me {
            background: #e8fbe8;
            margin-left: auto;
            border-bottom-right-radius: 4px;
        }

        .msg.them {
            background: #eef1f6;
            margin-right: auto;
            border-bottom-left-radius: 4px;
        }

        .meta {
            font-size: 12px;
            color: #687280;
            margin-bottom: 4px;
        }

        /* COMPOSER */
        .composer {
            display: flex;
            gap: 10px;
            margin-top: 16px;
        }

        textarea {
            flex: 1;
            border-radius: 12px;
            border: 1px solid #cfd8e3;
            padding: 12px;
            font-size: 15px;
        }

        .send-btn {
            background: #2563ff;
            color: white;
            padding: 12px 22px;
            border-radius: 10px;
            border: none;
            cursor: pointer;
            font-size: 15px;
            font-weight: 500;
        }
    </style>
</head>

<body>

    <div class="header">XpertiseXchange</div>

    <div class="chat-box">

        <!-- Back button -->
        <button class="back-btn" onclick="history.back()">← Back</button>

        <h2 style="margin-top: 0; color:#333;">Conversation</h2>

        <div id="messages">
            <% for (Map<String,Object> m : messages) { 
                int senderId = (int) m.get("senderId");
            %>
                <div class="msg <%= senderId == userId ? "me" : "them" %>">
                    <div class="meta">
                        <strong><%= esc(m.get("senderName")) %></strong> • <%= esc(m.get("sentAt")) %>
                    </div>
                    <div><%= esc(m.get("content")) %></div>
                </div>
            <% } %>
        </div>

        <!-- Message composer -->
        <form method="post" action="send-message" class="composer">
            <input type="hidden" name="transactionId" value="<%= transactionId %>">
            <textarea name="content" placeholder="Write a message..." required></textarea>
            <button class="send-btn">Send</button>
        </form>

    </div>

</body>
</html>
