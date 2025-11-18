<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.skill.SkillDAO" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Active Swaps</title>
    <link rel="stylesheet" href="css/styles.css">
    <style>table{width:100%;border-collapse:collapse}th,td{padding:8px;border-bottom:1px solid #eee}</style>
</head>
<body>
<div style="max-width:1000px;margin:20px auto;background:#fff;padding:16px;border-radius:8px;box-shadow:0 6px 18px rgba(0,0,0,0.04)">
    <h2>Active Swaps (Bids You Sent)</h2>
    <% List<SkillDAO.ProviderBidView> bids = (List<SkillDAO.ProviderBidView>) request.getAttribute("providerBids");
       if (bids == null || bids.isEmpty()) { %>
        <p>You have not proposed any swaps yet.</p>
    <% } else { %>
        <table>
            <thead><tr><th>Request</th><th>Requester</th><th>Requested Skill</th><th>Offered Skill / Volunteer</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
            <% for (SkillDAO.ProviderBidView b : bids) { %>
                <tr>
                    <td><%= b.getQueryTitle() %></td>
                    <td><a href="/profile?id=<%= b.getRequesterId() %>"><%= b.getRequesterName() %></a></td>
                    <td><%= b.getRequestedSkillName() == null ? "-" : b.getRequestedSkillName() %></td>
                    <td><%= b.isVolunteer() ? "Volunteer" : (b.getOfferedSkillName() == null ? "-" : b.getOfferedSkillName()) %></td>
                    <td><%= b.getStatus() %></td>
                    <td>
                        <form action="/bid/update" method="post" style="display:inline">
                            <input type="hidden" name="bidId" value="<%= b.getBidId() %>">
                            <button type="button" onclick="openEdit('<%= b.getBidId() %>')">Edit</button>
                        </form>
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
    <% } %>
</div>

<script>
    function openEdit(bidId) {
        // For brevity simply prompt for new offeredSkillId or volunteer
        var offered = prompt('Enter Offered Skill ID (leave blank to set volunteer):');
        if (offered === null) return;
        var volunteer = offered.trim() === '';

        // Create a form and submit
        var form = document.createElement('form');
        form.method = 'post';
        form.action = '/bid/update';
    var i1 = document.createElement('input'); i1.type='hidden'; i1.name='bidId'; i1.value = bidId; form.appendChild(i1);
        var i2 = document.createElement('input'); i2.type='hidden'; i2.name='offeredSkillId'; i2.value = offered; form.appendChild(i2);
        var i3 = document.createElement('input'); i3.type='hidden'; i3.name='volunteer'; i3.value = volunteer; form.appendChild(i3);
        document.body.appendChild(form); form.submit();
    }
</script>

</body>
</html>
