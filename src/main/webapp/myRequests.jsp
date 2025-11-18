<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.skill.SkillDAO" %>
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
    <% List<SkillDAO.RequestWithBids> requests = (List<SkillDAO.RequestWithBids>) request.getAttribute("requestsWithBids");
       if (requests == null || requests.isEmpty()) { %>
        <p>You have not posted any requests yet.</p>
    <% } else {
           for (SkillDAO.RequestWithBids r : requests) { %>
               <div style="margin-bottom:12px;">
                   <h3><%= r.getTitle() %></h3>
                   <p><%= r.getDescription() %></p>
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
                                   <td><%= b.getProviderName() %></td>
                                   <td><%= b.getRequestedSkillName() == null ? "-" : b.getRequestedSkillName() %></td>
                                   <td><%= b.isVolunteer() ? "Volunteer" : (b.getOfferedSkillName() == null ? "-" : b.getOfferedSkillName()) %></td>
                                   <td><%= b.getMessage() %></td>
                                   <td><a href="/profile?id=<%= b.getProviderId() %>">View Profile</a></td>
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
