<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
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
    
    // List to hold queries/requests
    List<Map<String, Object>> queries = new ArrayList<>();
    
    // Fetch all open queries (excluding user's own queries)
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "SELECT q.QueryID, q.Title, q.Description, q.PostDate, q.Status, " +
                        "u.Username as RequesterName, u.FullName as RequesterFullName, " +
                        "s.SkillName " +
                        "FROM Queries q " +
                        "JOIN Users u ON q.RequesterID = u.UserID " +
                        "JOIN Skills s ON q.SkillID = s.SkillID " +
                        "WHERE q.RequesterID != ? AND q.Status = 'Open' " +
                        "ORDER BY q.PostDate DESC";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> query = new HashMap<>();
                        query.put("queryId", rs.getInt("QueryID"));
                        query.put("title", rs.getString("Title"));
                        query.put("description", rs.getString("Description"));
                        query.put("postDate", rs.getString("PostDate"));
                        query.put("status", rs.getString("Status"));
                        query.put("requesterName", rs.getString("RequesterFullName") != null ? 
                                  rs.getString("RequesterFullName") : rs.getString("RequesterName"));
                        query.put("skillName", rs.getString("SkillName"));
                        queries.add(query);
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
    <title>Browse Requests - Skill Exchange Platform</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/dashboard.css">
    <link rel="stylesheet" href="css/browse.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="dashboard-container">
        <!-- Header -->
        <header class="dashboard-header">
            <div class="header-content">
                <h1 class="platform-title">XpertiseXchange</h1>
                <p class="header-subtitle">Browse Requests</p>
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
                <a href="profile.jsp" class="tab-trigger" data-tab="profile">
                    <i class="fas fa-user"></i>
                    Profile
                </a>
                <a href="my-skills.jsp" class="tab-trigger" data-tab="my-skills">
                    <i class="fas fa-book-open"></i>
                    My Skills
                </a>
                <a href="browse-requests.jsp" class="tab-trigger active" data-tab="browse-requests">
                    <i class="fas fa-search"></i>
                    Browse Requests
                </a>
                <a href="exchanges.jsp" class="tab-trigger" data-tab="exchanges">
                    <i class="fas fa-exchange-alt"></i>
                    Exchanges
                </a>
                <a href="messages.jsp" class="tab-trigger" data-tab="messages">
                    <i class="fas fa-comments"></i>
                    Messages
                </a>
            </div>
        </nav>

        <!-- Main Content -->
        <main class="dashboard-main">
            <div class="browse-container">
                <div class="browse-card">
                    <div class="browse-header">
                        <h2>Browse Skill Exchange Requests</h2>
                        <p class="browse-description">Find and respond to skill exchange requests from other users</p>
                    </div>
                    <div class="browse-content">
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
                        
                        <div class="requests-table">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Request ID</th>
                                        <th>Title</th>
                                        <th>Posted By</th>
                                        <th>Skill Needed</th>
                                        <th>Description</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody id="requestsTableBody">
                                    <% if (queries.isEmpty()) { %>
                                        <tr>
                                            <td colspan="6" style="text-align: center; padding: 2rem; color: #666;">
                                                <i class="fas fa-search" style="font-size: 2rem; margin-bottom: 1rem; opacity: 0.3; display: block;"></i>
                                                No open requests available at the moment.
                                            </td>
                                        </tr>
                                    <% } else {
                                        for (Map<String, Object> query : queries) {
                                    %>
                                        <tr>
                                            <td class="request-id">REQ<%= String.format("%03d", query.get("queryId")) %></td>
                                            <td><strong><%= query.get("title") %></strong></td>
                                            <td><%= query.get("requesterName") %></td>
                                            <td><span class="skill-badge"><%= query.get("skillName") %></span></td>
                                            <td><%= query.get("description") != null ? query.get("description") : "No description provided" %></td>
                                            <td>
                                            <button onclick='openProposalModal(
    <%= query.get("queryId") %>,
    <%= "\"" + query.get("requesterName").toString().replace("\"", "\\\"") + "\"" %>,
    <%= "\"" + query.get("title").toString().replace("\"", "\\\"") + "\"" %>,
    <%= "\"" + query.get("skillName").toString().replace("\"", "\\\"") + "\"" %>
)'>
    Send Proposal
</button>
                                            
                                                <button class="btn btn-primary btn-sm" 
                                                        onclick="openProposalModal(<%= query.get("queryId") %>, '<%= query.get("requesterName") %>', '<%= query.get("title") %>', '<%= query.get("skillName") %>')">
                                                    Send Proposal
                                                </button>
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
        </main>
    </div>

    <!-- Proposal Modal -->
    <div id="proposalModal" class="modal" style="display: none;">
        <div class="modal-content">
            <div class="modal-header">
                <h3>Send Proposal</h3>
                <p class="modal-description">Send a bid for this skill exchange request</p>
                <button class="modal-close" onclick="closeProposalModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="modal-body">
                <div class="request-details" id="requestDetails" style="background: #f8f9fa; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                    <!-- Request details will be populated dynamically -->
                </div>
                <form action="SubmitBid" method="post" id="proposalForm" class="modal-form">
                    <input type="hidden" id="queryId" name="queryId" value="">
                    <div class="form-group">
                        <label for="bidDetails">Your Bid Details</label>
                        <textarea id="bidDetails" name="bidDetails" rows="4" placeholder="Describe your proposal and how you can help..." required></textarea>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline" onclick="closeProposalModal()">Cancel</button>
                        <button type="submit" class="btn btn-primary">Send Proposal</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="js/dashboard.js"></script>
    <script>
        function logout() {
            if (confirm('Are you sure you want to logout?')) {
                window.location.href = 'logout.jsp';
            }
        }

        function openProposalModal(queryId, requesterName, title, skill) {
            document.getElementById('proposalModal').style.display = 'flex';
            document.getElementById('queryId').value = queryId;
            document.getElementById('requestDetails').innerHTML = `
                <p><strong>Request:</strong> ${title}</p>
                <p><strong>Posted by:</strong> ${requesterName}</p>
                <p><strong>Skill Needed:</strong> ${skill}</p>
            `;
        }

        function closeProposalModal() {
            document.getElementById('proposalModal').style.display = 'none';
            document.getElementById('proposalForm').reset();
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('proposalModal');
            if (event.target == modal) {
                closeProposalModal();
            }
        }
    </script>
</body>
</html>
