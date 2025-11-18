<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%!
    // Simple HTML escaper for embedding values into attribute contexts
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
    // Check if user is logged in
    String userEmail = (String) session.getAttribute("userEmail");
    Integer userId = (Integer) session.getAttribute("userId");
    if (userEmail == null || userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    
    // Database credentials
    String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    String JDBC_USER = "root";
    String JDBC_PASS = "aTTri21..";
    
    // Lists to hold data
    List<Map<String, Object>> receivedBids = new ArrayList<>();
    List<Map<String, Object>> activeTransactions = new ArrayList<>();
    
    // Fetch received bids on user's queries (pending only)
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String bidsSql = "SELECT b.BidID, b.BidDetails, b.Status, b.BidDate, b.RequestedSkillID, b.WantedSkillID, b.OfferedSkillID, b.Volunteer, " +
                            "u.UserID AS ProviderID, u.Username as ProviderName, u.FullName as ProviderFullName, " +
                            "q.Title as QueryTitle, q.QueryID, sReq.SkillName AS RequestedSkillName, sWant.SkillName AS WantedSkillName, sOff.SkillName AS OfferedSkillName " +
                            "FROM Bids b " +
                            "JOIN Queries q ON b.QueryID = q.QueryID " +
                            "JOIN Users u ON b.ProviderID = u.UserID " +
                            "LEFT JOIN Skills sReq ON b.RequestedSkillID = sReq.SkillID " +
                            "LEFT JOIN Skills sWant ON b.WantedSkillID = sWant.SkillID " +
                            "LEFT JOIN Skills sOff ON b.OfferedSkillID = sOff.SkillID " +
                            "WHERE q.RequesterID = ? AND b.Status = 'Pending' " +
                            "ORDER BY b.BidDate DESC";
            try (PreparedStatement ps = con.prepareStatement(bidsSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> bid = new HashMap<>();
                        bid.put("bidId", rs.getInt("BidID"));
                        bid.put("bidDetails", rs.getString("BidDetails"));
                        bid.put("status", rs.getString("Status"));
                        bid.put("bidDate", rs.getString("BidDate"));
                        bid.put("queryTitle", rs.getString("QueryTitle"));
                        bid.put("queryId", rs.getInt("QueryID"));
                        bid.put("providerId", rs.getInt("ProviderID"));
                        bid.put("providerName", rs.getString("ProviderFullName") != null ? rs.getString("ProviderFullName") : rs.getString("ProviderName"));
                        bid.put("requestedSkillName", rs.getString("RequestedSkillName"));
                        bid.put("wantedSkillName", rs.getString("WantedSkillName"));
                        bid.put("offeredSkillName", rs.getString("OfferedSkillName"));
                        bid.put("volunteer", rs.getBoolean("Volunteer"));
                        receivedBids.add(bid);
                    }
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    // Fetch active transactions
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String transSql = "SELECT t.TransactionID, t.Status, t.StartDate, t.ExchangeType, " +
                             "u.Username as OtherUserName, u.FullName as OtherUserFullName, " +
                             "q.Title as QueryTitle, " +
                             "CASE " +
                             "  WHEN t.RequesterID = ? THEN 'Provider' " +
                             "  ELSE 'Requester' " +
                             "END as UserRole " +
                             "FROM Transactions t " +
                             "JOIN Queries q ON t.QueryID = q.QueryID " +
                             "JOIN Users u ON (CASE WHEN t.RequesterID = ? THEN t.ProviderID ELSE t.RequesterID END) = u.UserID " +
                             "WHERE (t.RequesterID = ? OR t.ProviderID = ?) AND t.Status = 'Ongoing' " +
                             "ORDER BY t.StartDate DESC";
            try (PreparedStatement ps = con.prepareStatement(transSql)) {
                ps.setInt(1, userId);
                ps.setInt(2, userId);
                ps.setInt(3, userId);
                ps.setInt(4, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> transaction = new HashMap<>();
                        transaction.put("transactionId", rs.getInt("TransactionID"));
                        transaction.put("status", rs.getString("Status"));
                        transaction.put("startDate", rs.getString("StartDate"));
                        transaction.put("exchangeType", rs.getString("ExchangeType"));
                        transaction.put("queryTitle", rs.getString("QueryTitle"));
                        transaction.put("userRole", rs.getString("UserRole"));
                        transaction.put("otherUserName", rs.getString("OtherUserFullName") != null ? 
                                       rs.getString("OtherUserFullName") : rs.getString("OtherUserName"));
                        activeTransactions.add(transaction);
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
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exchanges - Skill Exchange Platform</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/dashboard.css">
    <link rel="stylesheet" href="css/exchanges.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="dashboard-container">
        <!-- Header -->
        <header class="dashboard-header">
            <div class="header-content">
                <h1 class="platform-title">XpertiseXchange</h1>
                <p class="header-subtitle">Exchanges</p>
                <button class="btn btn-outline btn-sm logout-btn" onclick="logout()">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </button>
            </div>
        </header>

        <!-- Navigation Tabs -->
        <nav class="tab-navigation">
            <div class="tab-list">
                <a href="dashboard.jsp" class="tab-trigger" data-tab="dashboard">
                    <i class="fas fa-home"></i>
                    Dashboard
                </a>
                <a href="myProfile.jsp" class="tab-trigger" data-tab="profile">
                    <i class="fas fa-user"></i>
                    Profile
                </a>
                <a href="my-skills.jsp" class="tab-trigger" data-tab="my-skills">
                    <i class="fas fa-book-open"></i>
                    My Skills
                </a>
                <a href="browse-requests.jsp" class="tab-trigger" data-tab="browse-requests">
                    <i class="fas fa-search"></i>
                    Browse Requests
                </a>
                <!--<a href="exchanges.jsp" class="tab-trigger active" data-tab="exchanges">
                    <i class="fas fa-exchange-alt"></i>
                    Exchanges
                </a>-->
                <a href="messages.jsp" class="tab-trigger" data-tab="messages">
                    <i class="fas fa-comments"></i>
                    Messages
                </a>
            </div>
        </nav>

        <!-- Main Content -->
        <main class="dashboard-main">
            <div class="exchanges-container">
                <% 
                    String message = (String) request.getAttribute("message");
                    String error = (String) request.getAttribute("error");
                    if (message != null) {
                %>
                    <div class="alert alert-success" style="margin-bottom: 1rem; padding: 1rem; background: #d4edda; border: 1px solid #c3e6cb; border-radius: 8px; color: #155724;">
                        <%= message %>
                    </div>
                <% } 
                    if (error != null) {
                %>
                    <div class="alert alert-error" style="margin-bottom: 1rem; padding: 1rem; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 8px; color: #721c24;">
                        <%= error %>
                    </div>
                <% } %>
                
                <div class="exchanges-grid">
                    <!-- Panel A: My Requests (Received Bids) -->
                    <div class="exchange-panel">
                        <div class="panel-card">
                            <div class="panel-header">
                                <h2>My Requests (Received Bids)</h2>
                                <p class="panel-description">Bids received on your posted requests</p>
                            </div>
                            <div class="panel-content">
                                <div class="proposals-table">
                                    <table>
                                        <thead>
                                            <tr>
                                                <th>Bid ID</th>
                                                <th>Request</th>
                                                <th>Requested Skill</th>
                                                <th>Wanted Skill</th>
                                                <th>From User</th>
                                                <th>Bid Details</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody id="proposalsTableBody">
                                            <% if (receivedBids.isEmpty()) { %>
                                                <tr>
                                                    <td colspan="5" style="text-align: center; padding: 2rem; color: #666;">
                                                        <i class="fas fa-inbox" style="font-size: 2rem; margin-bottom: 1rem; opacity: 0.3; display: block;"></i>
                                                        No pending bids on your requests.
                                                    </td>
                                                </tr>
                                            <% } else {
                                                for (Map<String, Object> bid : receivedBids) {
                                            %>
                                                <tr>
                                                    <td class="proposal-id">BID<%= String.format("%03d", bid.get("bidId")) %></td>
                                                    <td><strong><%= esc(bid.get("queryTitle")) %></strong></td>
                                                    <td><%= esc(bid.get("requestedSkillName") != null ? bid.get("requestedSkillName") : "-") %></td>
                                                    <td><%= esc(bid.get("wantedSkillName") != null ? bid.get("wantedSkillName") : "-") %></td>
                                                    <td><a href="profile?id=<%= bid.get("providerId") %>"><%= esc(bid.get("providerName")) %></a></td>
                                                    <td style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                                                        <%= esc(bid.get("bidDetails")) %>
                                                    </td>
                                                    <td>
                                                        <div class="action-buttons">
                                                            <form action="AcceptBid" method="post" style="display: inline;">
                                                                <input type="hidden" name="bidId" value="<%= bid.get("bidId") %>">
                                                                <input type="hidden" name="queryId" value="<%= bid.get("queryId") %>">
                                                                <button type="submit" class="btn btn-success btn-sm" onclick="return confirm('Accept this bid?')">
                                                                    <i class="fas fa-check"></i> Accept
                                                                </button>
                                                            </form>
                                                            <form action="RejectBid" method="post" style="display: inline;">
                                                                <input type="hidden" name="bidId" value="<%= bid.get("bidId") %>">
                                                                <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Reject this bid?')">
                                                                    <i class="fas fa-times"></i> Reject
                                                                </button>
                                                            </form>
                                                        </div>
                                                    </td>
                                                </tr>
                                            <% 
                                                }
                                            } 
                                            %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Panel B: Active Exchanges -->
                    <div class="exchange-panel">
                        <div class="panel-card">
                            <div class="panel-header">
                                <h2>Active Exchanges</h2>
                                <p class="panel-description">Your ongoing skill exchanges</p>
                            </div>
                            <div class="panel-content">
                                <div class="exchanges-table">
                                    <table>
                                        <thead>
                                            <tr>
                                                <th>Exchange ID</th>
                                                <th>Request</th>
                                                <th>With User</th>
                                                <th>Role</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody id="exchangesTableBody">
                                            <% if (activeTransactions.isEmpty()) { %>
                                                <tr>
                                                    <td colspan="5" style="text-align: center; padding: 2rem; color: #666;">
                                                        <i class="fas fa-handshake" style="font-size: 2rem; margin-bottom: 1rem; opacity: 0.3; display: block;"></i>
                                                        No active exchanges yet.
                                                    </td>
                                                </tr>
                                            <% } else {
                                                for (Map<String, Object> transaction : activeTransactions) {
                                            %>
                                                <tr>
                                                    <td class="exchange-id">EX<%= String.format("%03d", transaction.get("transactionId")) %></td>
                                                    <td><strong><%= transaction.get("queryTitle") %></strong></td>
                                                    <td><%= transaction.get("otherUserName") %></td>
                                                    <td>
                                                        <span class="skill-badge"><%= transaction.get("userRole") %></span>
                                                    </td>
                                                    <td>
                                                        <a class="btn btn-primary btn-sm" href="review.jsp?transactionId=<%= transaction.get("transactionId") %>">
                                                            <i class="fas fa-check-circle"></i> Mark Completed
                                                        </a>
                                                    </td>
                                                </tr>
                                            <% 
                                                }
                                            } 
                                            %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <script src="js/dashboard.js"></script>
    <script>
        function logout() {
            if (confirm('Are you sure you want to logout?')) {
                window.location.href = 'logout.jsp';
            }
        }
    </script>
</body>
</html>