<%
    String userEmail = (String) session.getAttribute("userEmail");
    String username = (String) session.getAttribute("username");
    String displayName = (username != null && !username.isEmpty()) ? username : (userEmail != null ? userEmail : "Guest");
    String subtitle = (String) request.getAttribute("pageSubtitle");
    if (subtitle == null) subtitle = "";
%>
<!-- Header -->
<header class="dashboard-header">
    <div class="header-content">
        <h1 class="platform-title">XpertiseXchange</h1>
        <p class="header-subtitle"><%= subtitle.isEmpty() ? "" : subtitle %></p>
        <button class="btn btn-outline btn-sm logout-btn" onclick="logout()">
            <i class="fas fa-sign-out-alt"></i> Logout
        </button>
    </div>
</header>
