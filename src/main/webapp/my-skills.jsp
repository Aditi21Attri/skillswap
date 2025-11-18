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
    
    // List to hold user skills
    List<Map<String, Object>> userSkills = new ArrayList<>();
    
    // Fetch user's skills from database
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String sql = "SELECT us.UserSkillID, s.SkillName, s.SkillID " +
                        "FROM UserSkills us " +
                        "JOIN Skills s ON us.SkillID = s.SkillID " +
                        "WHERE us.UserID = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> skill = new HashMap<>();
                        skill.put("userSkillId", rs.getInt("UserSkillID"));
                        skill.put("skillId", rs.getInt("SkillID"));
                        skill.put("skillName", rs.getString("SkillName"));
                        userSkills.add(skill);
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
    <title>My Skills - Skill Exchange Platform</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/dashboard.css">
    <link rel="stylesheet" href="css/skills.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="dashboard-container">
        <!-- Header -->
        <header class="dashboard-header">
            <div class="header-content">
                <h1 class="platform-title">XpertiseXchange</h1>
                <p class="header-subtitle">My Skills</p>
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
                <a href="my-skills.jsp" class="tab-trigger active" data-tab="my-skills">
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
            <div class="skills-container">
                <div class="skills-card">
                    <div class="skills-header">
                        <div class="header-info">
                            <h2>My Skills</h2>
                            <p class="skills-description">Manage your skills</p>
                        </div>
                        <button class="btn btn-primary" onclick="openAddSkillModal()">
                            <i class="fas fa-plus"></i> Add Skill
                        </button>
                    </div>
                    <div class="skills-content">
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
                        
                        <div class="skills-list" id="skillsList">
                            <% if (userSkills.isEmpty()) { %>
                                <div style="text-align: center; padding: 3rem; color: #666;">
                                    <i class="fas fa-book-open" style="font-size: 3rem; margin-bottom: 1rem; opacity: 0.3;"></i>
                                    <p>You haven't added any skills yet.</p>
                                    <p>Click "Add Skill" to get started!</p>
                                </div>
                            <% } else {
                                for (Map<String, Object> skill : userSkills) {
                            %>
                                <div class="skill-item" data-skill-id="<%= skill.get("userSkillId") %>">
                                    <div class="skill-info">
                                        <div class="skill-title-row">
                                            <h3 class="skill-title"><%= skill.get("skillName") %></h3>
                                        </div>
                                    </div>
                                    <form action="DeleteSkill" method="post" style="display: inline;">
                                        <input type="hidden" name="userSkillId" value="<%= skill.get("userSkillId") %>">
                                        <button type="submit" class="btn btn-outline btn-sm delete-btn" onclick="return confirm('Are you sure you want to delete this skill?')">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </form>
                                </div>
                            <% 
                                }
                            } 
                            %>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- Add Skill Modal -->
    <div id="addSkillModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3>Add New Skill</h3>
                <p class="modal-description">Add a skill to your profile</p>
                <button class="modal-close" onclick="closeAddSkillModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <form action="AddSkill" method="post" id="addSkillForm" class="modal-form">
                <div class="form-group">
                    <label for="skillName">Skill Name</label>
                    <input type="text" id="skillName" name="skillName" required placeholder="e.g., React Development, Photography">
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeAddSkillModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Add Skill</button>
                </div>
            </form>
        </div>
    </div>

    <script src="js/dashboard.js"></script>
    <script>
        function logout() {
            if (confirm('Are you sure you want to logout?')) {
                window.location.href = 'logout.jsp';
            }
        }

        function openAddSkillModal() {
            document.getElementById('addSkillModal').style.display = 'flex';
        }

        function closeAddSkillModal() {
            document.getElementById('addSkillModal').style.display = 'none';
            document.getElementById('addSkillForm').reset();
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('addSkillModal');
            if (event.target == modal) {
                closeAddSkillModal();
            }
        }
    </script>
</body>
</html>
