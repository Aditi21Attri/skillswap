<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.skill.SkillDAO" %>
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
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Requests</title>
    <link rel="stylesheet" href="css/styles.css">
    <style>
        table { width:100%; border-collapse:collapse }
        th,td { padding:8px; border-bottom:1px solid #eee }
    </style>
</head>
<body>
<div style="max-width:1000px;margin:20px auto;background:#fff;padding:16px;border-radius:8px;box-shadow:0 6px 18px rgba(0,0,0,0.04)">
    <h2>My Requests</h2>
    <% Integer userId = (Integer) session.getAttribute("userId");
       List<SkillDAO.RequestWithBids> requests = (List<SkillDAO.RequestWithBids>) request.getAttribute("requestsWithBids");
       if (requests == null) {
           try { requests = SkillDAO.getRequestsWithBids(userId); } catch (Exception e) { e.printStackTrace(); }
       }
       if (requests == null || requests.isEmpty()) { %>
        <p>You have not posted any requests yet.</p>
    <% } else {
           for (SkillDAO.RequestWithBids r : requests) { %>
               <div style="margin-bottom:12px;">
                   <h3><%= esc(r.getTitle()) %></h3>
                   <p><%= esc(r.getDescription()) %></p>
                   <h4>Incoming Bids</h4>
                   <% List<SkillDAO.BidSummary> bids = r.getBids();
                      if (bids == null || bids.isEmpty()) { %>
                       <p>No bids yet.</p>
                   <% } else { %>
                       <table>
                           <thead><tr><th>Provider</th><th>Requested Skill</th><th>Offered Skill / Volunteer</th><th>Message</th><th>Action</th></tr></thead>
                           <tbody>
                           <% for (SkillDAO.BidSummary b : bids) { %>
                               <tr>
                                   <td><a href="profile?id=<%= b.getProviderId() %>"><%= esc(b.getProviderName()) %></a></td>
                                   <td><%= esc(b.getRequestedSkillName() == null ? "-" : b.getRequestedSkillName()) %></td>
                                   <td><%= b.isVolunteer() ? "Volunteer" : esc(b.getOfferedSkillName() == null ? "-" : b.getOfferedSkillName()) %></td>
                                   <td><%= esc(b.getMessage()) %></td>
                                   <td><a href="profile?id=<%= b.getProviderId() %>">View Profile</a></td>
                               </tr>
                           <% } %>
                           </tbody>
                       </table>
                   <% } %>
               </div>
    <%     }
       }
    %>
</div>
</body>
</html>