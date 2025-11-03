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
    
    // Fetch all available skills for dropdown
    List<Map<String, Object>> allSkills = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "SELECT SkillID, SkillName FROM Skills ORDER BY SkillName";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> skill = new HashMap<>();
                        skill.put("skillId", rs.getInt("SkillID"));
                        skill.put("skillName", rs.getString("SkillName"));
                        allSkills.add(skill);
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
    <title>Post Request - Skill Exchange Platform</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/dashboard.css">
    <link rel="stylesheet" href="css/profile.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="dashboard-container">
        <!-- Header -->
        <header class="dashboard-header">
            <div class="header-content">
                <h1 class="platform-title">XpertiseXchange</h1>
                <p class="header-subtitle">Post New Request</p>
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
                <a href="browse-requests.jsp" class="tab-trigger" data-tab="browse-requests">
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
            <div class="profile-container">
                <div class="profile-card">
                    <div class="profile-header">
                        <h2>Post a Skill Exchange Request</h2>
                        <p class="profile-description">Create a new request to find someone with the skills you need</p>
                    </div>
                    <div class="profile-content">
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
                        
                        <form action="PostRequest" method="post" class="profile-form">
                            <div class="form-group">
                                <label for="title">Request Title *</label>
                                <input type="text" id="title" name="title" required placeholder="e.g., Looking for React Developer">
                            </div>
                            
                            <div class="form-group">
                                <label for="skillId">Skill Needed *</label>
                                <select id="skillId" name="skillId" required>
                                    <option value="">-- Select a Skill --</option>
                                    <% for (Map<String, Object> skill : allSkills) { %>
                                        <option value="<%= skill.get("skillId") %>"><%= skill.get("skillName") %></option>
                                    <% } %>
                                </select>
                                <small style="color: #666; font-size: 12px;">Don't see your skill? <a href="my-skills.jsp" style="color: #007bff;">Add it to your skills first</a></small>
                            </div>
                            
                            <div class="form-group">
                                <label for="description">Description *</label>
                                <textarea id="description" name="description" rows="5" required placeholder="Describe what you need help with, project details, timeline, etc."></textarea>
                            </div>
                            
                            <div style="display: flex; gap: 1rem;">
                                <button type="submit" class="btn btn-primary" style="flex: 1;">
                                    <i class="fas fa-paper-plane"></i> Post Request
                                </button>
                                <a href="dashboard.jsp" class="btn btn-outline" style="flex: 1; text-align: center;">
                                    <i class="fas fa-times"></i> Cancel
                                </a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <script>
        function logout() {
            if (confirm('Are you sure you want to logout?')) {
                window.location.href = 'logout.jsp';
            }
        }
    </script>
</body>
</html>
