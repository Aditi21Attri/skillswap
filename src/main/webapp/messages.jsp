<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%!
    private String esc(Object o) {
        if (o == null) return "";
        String s = o.toString();
        return s.replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }
%>
<%
    // Require login
    Integer userId = null;
    Object uid = session.getAttribute("userId");
    if (uid == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    try { userId = Integer.parseInt(uid.toString()); } catch (Exception e) { response.sendRedirect("index.jsp"); return; }

    // DB config - mirror existing pages
    String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    String JDBC_USER = "root";
    String JDBC_PASS = "aTTri21..";

    List<Map<String,Object>> conversations = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "SELECT t.TransactionID, t.ExchangeType, t.StartDate, q.QueryID, q.Title AS QueryTitle, " +
                         "CASE WHEN t.RequesterID = ? THEN t.ProviderID ELSE t.RequesterID END AS OtherUserID, " +
                         "u.Username, u.FullName, u.Email " +
                         "FROM Transactions t " +
                         "JOIN Queries q ON t.QueryID = q.QueryID " +
                         "JOIN Users u ON (CASE WHEN t.RequesterID = ? THEN t.ProviderID ELSE t.RequesterID END) = u.UserID " +
                         "WHERE (t.RequesterID = ? OR t.ProviderID = ?) AND t.Status = 'Ongoing' " +
                         "ORDER BY t.StartDate DESC";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setInt(2, userId);
                ps.setInt(3, userId);
                ps.setInt(4, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> c = new HashMap<>();
                        c.put("transactionId", rs.getInt("TransactionID"));
                        c.put("queryId", rs.getInt("QueryID"));
                        c.put("queryTitle", rs.getString("QueryTitle"));
                        c.put("otherUserId", rs.getInt("OtherUserID"));
                        c.put("otherUserName", rs.getString("FullName") != null ? rs.getString("FullName") : rs.getString("Username"));
                        c.put("otherUserEmail", rs.getString("Email"));
                        c.put("exchangeType", rs.getString("ExchangeType"));
                        c.put("startDate", rs.getString("StartDate"));
                        conversations.add(c);
                    }
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Messages - Active Exchanges</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/messages.css">
    <style>
        .convo-list { max-width: 1000px; margin: 28px auto; }
        .convo-card { display:flex; gap:14px; align-items:center; padding:14px; background:#fff; border:1px solid #e6e6e6; border-radius:8px; margin-bottom:12px; }
        .avatar { width:56px; height:56px; border-radius:50%; background:#eef2ff; display:flex; align-items:center; justify-content:center; font-weight:600; color:#3b82f6; }
        .convo-main { flex:1; }
        .convo-main h4 { margin:0 0 6px; }
        .convo-meta { color:#6b7280; font-size:13px; }
        .convo-actions a { margin-left:8px; text-decoration:none; padding:8px 12px; border-radius:6px; }
        .btn-chat { background:#2563eb; color:#fff; }
        .btn-profile { background:#f3f4f6; color:#111827; border:1px solid #e5e7eb; }
    </style>
</head>
<body>
    <div class="convo-list">
        <h2>Active Conversations</h2>
        <p class="meta">These are your active exchanges. Click "Open" to view the conversation.</p>

        <% if (conversations.isEmpty()) { %>
            <div class="section-card meta">You have no active exchanges right now.</div>
        <% } else { %>
            <% for (Map<String,Object> c : conversations) { 
                   String name = esc(c.get("otherUserName"));
                   int tid = (int)c.get("transactionId");
                   int otherId = (int)c.get("otherUserId");
            %>
                <div class="convo-card">
                    <div class="avatar"><%= name.length()>0 ? name.substring(0,1).toUpperCase() : "U" %></div>
                    <div class="convo-main">
                        <h4><%= name %> <span class="convo-meta">— <em><%= esc(c.get("queryTitle")) %></em></span></h4>
                        <div class="convo-meta">Started: <%= esc(c.get("startDate")) %> • Type: <%= esc(c.get("exchangeType")) %></div>
                    </div>
                    <div class="convo-actions">
                        <a class="btn-profile" href="profile?id=<%= otherId %>">Profile</a>
                        <a class="btn-chat" href="messages-thread.jsp?transactionId=<%= tid %>">Open</a>
                    </div>
                </div>
            <% } %>
        <% } %>
    </div>
</body>
</html>
