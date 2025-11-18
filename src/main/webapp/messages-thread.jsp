<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="com.skill.MessageDAO" %>
<%
    Object uidObj = session.getAttribute("userId");
    if (uidObj == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    int userId;
    try { userId = Integer.parseInt(uidObj.toString()); } catch (Exception e) { response.sendRedirect("index.jsp"); return; }

    String tidParam = request.getParameter("transactionId");
    if (tidParam == null) {
        response.sendRedirect("messages.jsp");
        return;
    }
    int transactionId;
    try { transactionId = Integer.parseInt(tidParam); } catch (NumberFormatException e) { response.sendRedirect("messages.jsp"); return; }

    try {
        if (!MessageDAO.isParticipant(transactionId, userId)) {
            response.sendError(403);
            return;
        }
    } catch (Exception e) {
        throw new RuntimeException(e);
    }

    List<Map<String,Object>> messages = Collections.emptyList();
    try { messages = MessageDAO.getMessagesForTransaction(transactionId, 100); } catch (Exception e) { e.printStackTrace(); }

    // simple esc
    String esc(Object o) { if (o==null) return ""; return o.toString().replace("&","&amp;").replace("\"","&quot;").replace("<","&lt;").replace(">","&gt;"); }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Conversation</title>
    <link rel="stylesheet" href="css/styles.css">
    <style>
        .thread { max-width:900px; margin:28px auto; background:#fff; padding:18px; border-radius:8px; border:1px solid #e6e6e6; }
        .msg { padding:8px 12px; border-radius:10px; margin:8px 0; max-width:70%; }
        .msg.me { background:#dcfce7; margin-left:auto; }
        .msg.them { background:#f3f4f6; margin-right:auto; }
        .meta { font-size:12px; color:#6b7280; }
        .composer { margin-top:12px; display:flex; gap:8px; }
        textarea { flex:1; min-height:70px; }
        .btn { padding:8px 12px; background:#2563eb; color:#fff; border-radius:6px; border:none; }
    </style>
</head>
<body>
    <div class="thread">
        <h3>Conversation</h3>
        <div id="messages">
            <% for (Map<String,Object> m : messages) {
                   int senderId = (int) m.get("senderId");
                   String name = (String) m.get("senderName");
            %>
                <div class="msg <%= senderId == userId ? "me" : "them" %>">
                    <div class="meta"><strong><%= esc(name) %></strong> • <%= esc(m.get("sentAt")) %></div>
                    <div><%= esc(m.get("content")) %></div>
                </div>
            <% } %>
        </div>

        <form method="post" action="send-message" class="composer">
            <input type="hidden" name="transactionId" value="<%= transactionId %>">
            <textarea name="content" placeholder="Write a message..."></textarea>
            <button class="btn" type="submit">Send</button>
        </form>
    </div>
</body>
</html>
