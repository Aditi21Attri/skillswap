<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.skill.SkillDAO" %>
<%@ page import="java.util.List" %>
<%!
    public static String jsEscape(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r");
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>User Profile</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/profile_user.css">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background: #f6f8fa;
            margin: 0;
        }

        .container {
            max-width: 1080px;
            margin: 40px auto;
            display: flex;
            gap: 30px;
        }

        /* LEFT SIDEBAR — GitHub style */
        .sidebar {
            width: 280px;
        }

        .avatar {
            width: 180px;
            height: 180px;
            border-radius: 50%;
            background: #e5e7eb;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
            font-weight: bold;
            color: #374151;
            margin-bottom: 20px;
        }

        .name { font-size: 26px; font-weight: 600; }
        .username { font-size: 18px; color: #57606a; margin-top: 4px; }
        .email { margin-top: 10px; color: #444; font-size: 15px; }

        .bio-box {
            margin-top: 20px;
            padding: 12px;
            background: #fff;
            border: 1px solid #d0d7de;
            border-radius: 8px;
        }

        /* RIGHT SECTION */
        .main {
            flex: 1;
        }

        .section-card {
            background: #fff;
            border: 1px solid #d0d7de;
            border-radius: 8px;
            padding: 18px;
            margin-bottom: 20px;
        }

        h3 { margin: 0 0 10px; }

        .skills-list {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }

        .pill {
            padding: 6px 12px;
            background: #e2e8f0;
            border-radius: 14px;
            font-size: 14px;
        }

        .meta { color: #6b7280; font-size: 14px; }

        .btn {
            padding: 8px 14px;
            background: #2da44e;
            border: none;
            color: white;
            border-radius: 6px;
            cursor: pointer;
        }

        .btn:hover { background: #22863a; }

        /* Modal */
        .modal {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,0.45);
            align-items: center;
            justify-content: center;
        }

        .modal-content {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            width: min(600px, 95%);
        }

        input, select, textarea {
            width: 100%;
            padding: 8px;
            border-radius: 6px;
            border: 1px solid #d1d5db;
        }
    </style>
</head>
<body>

<%
    SkillDAO.UserProfile profile = (SkillDAO.UserProfile) request.getAttribute("profile");
    List<SkillDAO.Skill> skills = (List<SkillDAO.Skill>) request.getAttribute("skills");
    List<SkillDAO.Skill> mySkills = (List<SkillDAO.Skill>) request.getAttribute("mySkills");

    Integer sessionUserId = null;
    Object uidObj = request.getSession().getAttribute("userId");
    if (uidObj != null) {
        try { sessionUserId = Integer.parseInt(uidObj.toString()); } catch (Exception ignored) {}
    }

    // If no profile was found by the servlet/DAO, show a friendly message and stop rendering.
    if (profile == null) {
%>
    <div style="max-width:800px;margin:40px auto;padding:20px;background:#fff;border:1px solid #e6e6e6;border-radius:8px;">
        <h2>User not found</h2>
        <p>The requested user profile could not be found. It may have been removed or the link is invalid.</p>
        <p><a href="index.jsp">Return to homepage</a></p>
    </div>
<%
        return;
    }

    String initials = "U";
    if (profile != null && profile.getFullName() != null) {
        String[] parts = profile.getFullName().trim().split(" ");
        if (parts.length > 0) initials = parts[0].substring(0,1).toUpperCase();
        if (parts.length > 1) initials += parts[1].substring(0,1).toUpperCase();
    }
%>

<div class="container">

    <!-- LEFT SIDEBAR -->
    <div class="sidebar">
        <div class="avatar"><%= initials %></div>

        <div class="name"><%= profile != null ? profile.getFullName() : "Unknown User" %></div>
        <div class="username">@<%= profile != null ? profile.getUsername() : "" %></div>
        <div class="email"><%= profile != null ? profile.getEmail() : "" %></div>

        <div class="bio-box">
            <strong>Bio:</strong><br>
            <%= profile != null && profile.getBio() != null ? profile.getBio() : "No bio provided." %>
        </div>
    </div>

    <!-- RIGHT MAIN CONTENT -->
    <div class="main">

        <!-- SKILLS -->
        <div class="section-card">
            <h3>Skills</h3>
            <div class="skills-list">
                <% if (skills != null && !skills.isEmpty()) {
                       for (SkillDAO.Skill s : skills) { %>
                           <div class="pill"><%= s.getSkillName() %></div>
                <%     }
                   } else { %>
                       <div class="meta">No skills listed.</div>
                <% } %>
            </div>
        </div>

        <!-- ACTIVE REQUESTS -->
        <div class="section-card">
            <h3>Active Requests by <%= profile.getFullName() %></h3>
            <ul>
                <% 
                    List<java.util.Map<String,Object>> reqs =
                        (List<java.util.Map<String,Object>>) request.getAttribute("profileRequests");

                    if (reqs != null && !reqs.isEmpty()) {
                        for (java.util.Map<String,Object> r : reqs) {
                %>
                    <li>
                        <strong><%= r.get("title") %></strong> — 
                        <em><%= r.get("skillName") %></em> — 
                        <%= r.get("description") %>
                    </li>
                <% 
                        }
                    } else { 
                %>
                    <li class="meta">No open requests.</li>
                <% } %>
            </ul>
        </div>

    </div>
</div>


</body>
</html>
