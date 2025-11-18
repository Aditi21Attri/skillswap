<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.sql.*" %>
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

    // Fetch transaction / query / peer user / accepted bid details to show in sidebar
    Map<String,Object> transInfo = new HashMap<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        String sql = "SELECT t.TransactionID, t.QueryID, t.ProviderID, t.RequesterID, t.ProviderSkillID, t.ExchangeType, " +
                     "q.Title AS QueryTitle, q.Description AS QueryDescription, q.SkillID AS RequestedSkillID, sReq.SkillName AS RequestedSkillName, " +
                     "usProv.UserID AS ProviderUserID, sProv.SkillName AS ProviderSkillName, " +
                     "CASE WHEN t.RequesterID = ? THEN t.ProviderID ELSE t.RequesterID END AS OtherUserID, " +
                     "u.Username AS OtherUsername, u.FullName AS OtherFullName, u.Email AS OtherEmail, " +
                     "b.BidID, b.BidDetails, b.WantedSkillID, sWant.SkillName AS WantedSkillName " +
                     "FROM Transactions t " +
                     "JOIN Queries q ON t.QueryID = q.QueryID " +
                     "LEFT JOIN Skills sReq ON q.SkillID = sReq.SkillID " +
                     "LEFT JOIN UserSkills usProv ON usProv.UserSkillID = t.ProviderSkillID " +
                     "LEFT JOIN Skills sProv ON usProv.SkillID = sProv.SkillID " +
                     "JOIN Users u ON u.UserID = (CASE WHEN t.RequesterID = ? THEN t.ProviderID ELSE t.RequesterID END) " +
                     "LEFT JOIN Bids b ON b.QueryID = t.QueryID AND b.ProviderID = (CASE WHEN t.RequesterID = ? THEN t.ProviderID ELSE t.RequesterID END) AND b.Status = 'Accepted' " +
                     "LEFT JOIN Skills sWant ON b.WantedSkillID = sWant.SkillID " +
                     "WHERE t.TransactionID = ? LIMIT 1";
        try (Connection c = DriverManager.getConnection("jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC","root","aTTri21..");
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, userId);
            ps.setInt(3, userId);
            ps.setInt(4, transactionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    transInfo.put("transactionId", rs.getInt("TransactionID"));
                    transInfo.put("queryId", rs.getInt("QueryID"));
                    transInfo.put("queryTitle", rs.getString("QueryTitle"));
                    transInfo.put("queryDescription", rs.getString("QueryDescription"));
                    transInfo.put("requestedSkillId", rs.getObject("RequestedSkillID"));
                    transInfo.put("requestedSkillName", rs.getString("RequestedSkillName"));
                    transInfo.put("providerSkillName", rs.getString("ProviderSkillName"));
                    transInfo.put("exchangeType", rs.getString("ExchangeType"));
                    transInfo.put("otherUserId", rs.getInt("OtherUserID"));
                    String otherName = rs.getString("OtherFullName") != null ? rs.getString("OtherFullName") : rs.getString("OtherUsername");
                    transInfo.put("otherUserName", otherName);
                    transInfo.put("otherUserEmail", rs.getString("OtherEmail"));
                    transInfo.put("bidId", rs.getObject("BidID"));
                    transInfo.put("bidDetails", rs.getString("BidDetails"));
                    transInfo.put("wantedSkillId", rs.getObject("WantedSkillID"));
                    transInfo.put("wantedSkillName", rs.getString("WantedSkillName"));
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
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
            max-width: 1100px;
            margin: 30px auto;
            background: white;
            border-radius: 16px;
            padding: 20px 28px;
            box-shadow: 0 6px 20px rgba(0,0,0,0.08);
        }

        /* Two-column layout: messages + sidebar */
        .chat-grid { display: flex; gap: 24px; }
        .chat-main { flex: 1; min-width: 0; }
        .chat-side { width: 320px; }

        .detail-card { background:#f8fafc; border-radius:12px; padding:16px; border:1px solid #eef2f7; }
        .detail-card h3 { margin:0 0 8px 0; }
        .detail-row { margin-bottom:10px; color:#374151; font-size:14px; }
        .skill-badge { display:inline-block; background:#eef2ff; color:#1e40af; padding:6px 8px; border-radius:8px; font-weight:600; margin-right:6px; }

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

        <div class="chat-grid">
            <div class="chat-main">
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

            <aside class="chat-side">
                <div class="detail-card">
                    <h3>Conversation With</h3>
                    <div class="detail-row"><strong><%= esc(transInfo.get("otherUserName")) %></strong></div>
                    <div class="detail-row"><%= esc(transInfo.get("otherUserEmail")) %></div>
                    <hr />
                    <h3>Request</h3>
                    <div class="detail-row"><strong><%= esc(transInfo.get("queryTitle")) %></strong></div>
                    <div class="detail-row" style="color:#556; font-size:13px;"><%= esc(transInfo.get("queryDescription")) %></div>
                    <div style="margin-top:8px;">
                        <span class="skill-badge">Requested: <%= esc(transInfo.get("requestedSkillName")) %></span>
                    </div>
                    <hr />
                    <h3>Accepted Bid</h3>
                    <div class="detail-row"><%= transInfo.get("bidId") != null ? ("Bid #" + esc(transInfo.get("bidId"))) : "—" %></div>
                    <div class="detail-row" style="color:#556; font-size:13px;"><%= esc(transInfo.get("bidDetails")) %></div>
                    <div style="margin-top:8px;">
                        <span class="skill-badge">Offered: <%= esc(transInfo.get("providerSkillName")) %></span>
                        <span class="skill-badge">Wanted: <%= esc(transInfo.get("wantedSkillName")) %></span>
                    </div>
                </div>
            </aside>
        </div>

    </div>

</body>
</html>
