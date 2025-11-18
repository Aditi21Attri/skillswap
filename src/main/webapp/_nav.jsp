<%
    String activeTab = (String) request.getAttribute("activeTab");
    if (activeTab == null) activeTab = "";
%>
<nav class="tab-navigation" style="max-width:1000px;margin:18px auto 0;padding:0 12px;">
    <div class="tab-list">
        <a href="dashboard.jsp" class="tab-trigger <%= "dashboard".equals(activeTab) ? "active" : "" %>" data-tab="dashboard">
            <i class="fas fa-home"></i>
            Dashboard
        </a>
        <a href="profile.jsp" class="tab-trigger <%= "profile".equals(activeTab) ? "active" : "" %>" data-tab="profile">
            <i class="fas fa-user"></i>
            Profile
        </a>
        <a href="my-skills.jsp" class="tab-trigger <%= "my-skills".equals(activeTab) ? "active" : "" %>" data-tab="my-skills">
            <i class="fas fa-book-open"></i>
            My Skills
        </a>
        <a href="browse-requests.jsp" class="tab-trigger <%= "browse-requests".equals(activeTab) ? "active" : "" %>" data-tab="browse-requests">
            <i class="fas fa-search"></i>
            Browse Requests
        </a>
        <a href="exchanges.jsp" class="tab-trigger <%= "exchanges".equals(activeTab) ? "active" : "" %>" data-tab="exchanges">
            <i class="fas fa-exchange-alt"></i>
            Exchanges
        </a>
        
    </div>
</nav>
