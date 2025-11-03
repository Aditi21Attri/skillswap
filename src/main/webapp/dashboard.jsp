<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
    // Check if user is logged in
    String userEmail = (String) session.getAttribute("userEmail");
    String username = (String) session.getAttribute("username");
    if (userEmail == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    
    // Retrieve user statistics from session
    Integer skillCount = (Integer) session.getAttribute("skillCount");
    Integer exchangeCount = (Integer) session.getAttribute("exchangeCount");
    Integer messageCount = (Integer) session.getAttribute("messageCount");
    
    // Set default values if not available
    if (skillCount == null) skillCount = 0;
    if (exchangeCount == null) exchangeCount = 0;
    if (messageCount == null) messageCount = 0;
    
    // Display username or email
    String displayName = (username != null && !username.isEmpty()) ? username : userEmail;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Skill Exchange Platform</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/dashboard.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="dashboard-container">
        <!-- Header -->
        <header class="dashboard-header">
            <div class="header-content">
                <h1 class="platform-title">XpertiseXchange</h1>
                <p class="header-subtitle">Dashboard - Welcome, <%= displayName %></p>
                <button class="btn btn-outline btn-sm logout-btn" onclick="logout()">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </button>
            </div>
        </header>

        <!-- Navigation Tabs -->
        <nav class="tab-navigation">
            <div class="tab-list">
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
            <div class="welcome-section">
                <div class="welcome-card">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                        <h2>Welcome to Your Dashboard</h2>
                        <a href="post-request.jsp" class="btn btn-primary">
                            <i class="fas fa-plus-circle"></i> Post Request
                        </a>
                    </div>
                    <p>Navigate through the tabs above to access different sections of the platform.</p>
                    <div class="quick-stats">
                        <div class="stat-item">
                            <i class="fas fa-book-open"></i>
                            <span class="stat-number"><%= skillCount %></span>
                            <span class="stat-label">My Skills</span>
                        </div>
                        <div class="stat-item">
                            <i class="fas fa-handshake"></i>
                            <span class="stat-number"><%= exchangeCount %></span>
                            <span class="stat-label">Active Exchanges</span>
                        </div>
                        <div class="stat-item">
                            <i class="fas fa-envelope"></i>
                            <span class="stat-number"><%= messageCount %></span>
                            <span class="stat-label">Pending Bids</span>
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
