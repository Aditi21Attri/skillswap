package com.skill;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SkillDAO {
    private static final String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    private static final String JDBC_USER = "root";
    private static final String JDBC_PASS = "aTTri21..";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static UserProfile getUserProfile(int userId) throws SQLException {
        String sql = "SELECT UserID, Username, FullName, Email, Bio FROM Users WHERE UserID = ?";
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    UserProfile up = new UserProfile();
                    up.setUserId(rs.getInt("UserID"));
                    up.setUsername(rs.getString("Username"));
                    up.setFullName(rs.getString("FullName"));
                    up.setEmail(rs.getString("Email"));
                    up.setBio(rs.getString("Bio"));
                    return up;
                }
            }
        }
        return null;
    }

    public static List<Skill> getUserSkills(int userId) throws SQLException {
        String sql = "SELECT s.SkillID, s.SkillName FROM UserSkills us JOIN Skills s ON us.SkillID = s.SkillID WHERE us.UserID = ?";
        List<Skill> skills = new ArrayList<>();
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Skill s = new Skill();
                    s.setSkillId(rs.getInt("SkillID"));
                    s.setSkillName(rs.getString("SkillName"));
                    skills.add(s);
                }
            }
        }
        return skills;
    }

    public static List<java.util.Map<String, Object>> getOpenQueriesByUser(int userId) throws SQLException {
        String sql = "SELECT q.QueryID, q.Title, q.Description, s.SkillName FROM Queries q JOIN Skills s ON q.SkillID = s.SkillID WHERE q.RequesterID = ? AND q.Status = 'Open' ORDER BY q.PostDate DESC";
        List<java.util.Map<String, Object>> list = new ArrayList<>();
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    java.util.Map<String, Object> m = new java.util.HashMap<>();
                    m.put("queryId", rs.getInt("QueryID"));
                    m.put("title", rs.getString("Title"));
                    m.put("description", rs.getString("Description"));
                    m.put("skillName", rs.getString("SkillName"));
                    list.add(m);
                }
            }
        }
        return list;
    }

    public static boolean createBid(int queryId, int providerId, Integer requestedSkillId, Integer offeredSkillId, boolean volunteer, String message) throws SQLException {
        String sql = "INSERT INTO Bids (QueryID, ProviderID, RequestedSkillID, OfferedSkillID, Volunteer, BidDetails, Status) VALUES (?, ?, ?, ?, ?, ?, 'Pending')";
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, queryId);
            ps.setInt(2, providerId);
            if (requestedSkillId == null) ps.setNull(3, Types.INTEGER); else ps.setInt(3, requestedSkillId);
            if (offeredSkillId == null) ps.setNull(4, Types.INTEGER); else ps.setInt(4, offeredSkillId);
            ps.setBoolean(5, volunteer);
            ps.setString(6, message);
            int rows = ps.executeUpdate();
            return rows > 0;
        }
    }

    // Fetch requests posted by user with incoming bids details
    public static List<RequestWithBids> getRequestsWithBids(int requesterId) throws SQLException {
        String sql = "SELECT q.QueryID, q.Title, q.Description, b.BidID, b.ProviderID, b.RequestedSkillID, b.OfferedSkillID, b.Volunteer, b.BidDetails, b.Status, u.Username, sReq.SkillName AS RequestedSkillName, sOff.SkillName AS OfferedSkillName "
                + "FROM Queries q LEFT JOIN Bids b ON q.QueryID = b.QueryID "
                + "LEFT JOIN Users u ON b.ProviderID = u.UserID "
                + "LEFT JOIN Skills sReq ON b.RequestedSkillID = sReq.SkillID "
                + "LEFT JOIN Skills sOff ON b.OfferedSkillID = sOff.SkillID "
                + "WHERE q.RequesterID = ? ORDER BY q.QueryID DESC, b.BidID DESC";

        List<RequestWithBids> results = new ArrayList<>();
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, requesterId);
            try (ResultSet rs = ps.executeQuery()) {
                int lastQueryId = -1;
                RequestWithBids current = null;
                while (rs.next()) {
                    int qid = rs.getInt("QueryID");
                    if (current == null || qid != lastQueryId) {
                        current = new RequestWithBids();
                        current.setQueryId(qid);
                        current.setTitle(rs.getString("Title"));
                        current.setDescription(rs.getString("Description"));
                        current.setBids(new ArrayList<>());
                        results.add(current);
                        lastQueryId = qid;
                    }
                    int bidId = rs.getInt("BidID");
                    if (bidId > 0) {
                        BidSummary b = new BidSummary();
                        b.setBidId(bidId);
                        b.setProviderId(rs.getInt("ProviderID"));
                        b.setProviderName(rs.getString("Username"));
                        b.setRequestedSkillId(rs.getInt("RequestedSkillID"));
                        b.setOfferedSkillId(rs.getInt("OfferedSkillID"));
                        b.setVolunteer(rs.getBoolean("Volunteer"));
                        b.setMessage(rs.getString("BidDetails"));
                        b.setStatus(rs.getString("Status"));
                        b.setRequestedSkillName(rs.getString("RequestedSkillName"));
                        b.setOfferedSkillName(rs.getString("OfferedSkillName"));
                        current.getBids().add(b);
                    }
                }
            }
        }
        return results;
    }

    // Fetch bids created by provider
    public static List<ProviderBidView> getBidsByProvider(int providerId) throws SQLException {
        String sql = "SELECT b.BidID, b.QueryID, q.Title AS QueryTitle, q.RequesterID, u.Username AS RequesterName, b.RequestedSkillID, b.OfferedSkillID, b.Volunteer, b.BidDetails, b.Status, sReq.SkillName AS RequestedSkillName, sOff.SkillName AS OfferedSkillName "
                + "FROM Bids b JOIN Queries q ON b.QueryID = q.QueryID JOIN Users u ON q.RequesterID = u.UserID "
                + "LEFT JOIN Skills sReq ON b.RequestedSkillID = sReq.SkillID LEFT JOIN Skills sOff ON b.OfferedSkillID = sOff.SkillID "
                + "WHERE b.ProviderID = ? ORDER BY b.BidID DESC";

        List<ProviderBidView> list = new ArrayList<>();
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, providerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProviderBidView v = new ProviderBidView();
                    v.setBidId(rs.getInt("BidID"));
                    v.setQueryId(rs.getInt("QueryID"));
                    v.setQueryTitle(rs.getString("QueryTitle"));
                    v.setRequesterId(rs.getInt("RequesterID"));
                    v.setRequesterName(rs.getString("RequesterName"));
                    v.setRequestedSkillName(rs.getString("RequestedSkillName"));
                    v.setOfferedSkillName(rs.getString("OfferedSkillName"));
                    v.setVolunteer(rs.getBoolean("Volunteer"));
                    v.setStatus(rs.getString("Status"));
                    v.setMessage(rs.getString("BidDetails"));
                    list.add(v);
                }
            }
        }
        return list;
    }

    public static boolean updateBidOffer(int bidId, int providerId, Integer offeredSkillId, boolean volunteer) throws SQLException {
        String sql = "UPDATE Bids SET OfferedSkillID = ?, Volunteer = ? WHERE BidID = ? AND ProviderID = ?";
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = con.prepareStatement(sql)) {
            if (offeredSkillId == null) ps.setNull(1, Types.INTEGER); else ps.setInt(1, offeredSkillId);
            ps.setBoolean(2, volunteer);
            ps.setInt(3, bidId);
            ps.setInt(4, providerId);
            int rows = ps.executeUpdate();
            return rows > 0;
        }
    }

    // --- Simple POJOs ---
    public static class UserProfile {
        private int userId;
        private String username;
        private String fullName;
        private String email;
        private String bio;

        public int getUserId() { return userId; }
        public void setUserId(int userId) { this.userId = userId; }
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getFullName() { return fullName; }
        public void setFullName(String fullName) { this.fullName = fullName; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getBio() { return bio; }
        public void setBio(String bio) { this.bio = bio; }
    }

    public static class Skill {
        private int skillId;
        private String skillName;
        public int getSkillId() { return skillId; }
        public void setSkillId(int skillId) { this.skillId = skillId; }
        public String getSkillName() { return skillName; }
        public void setSkillName(String skillName) { this.skillName = skillName; }
    }

    public static class RequestWithBids {
        private int queryId;
        private String title;
        private String description;
        private List<BidSummary> bids;
        public int getQueryId() { return queryId; }
        public void setQueryId(int queryId) { this.queryId = queryId; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public List<BidSummary> getBids() { return bids; }
        public void setBids(List<BidSummary> bids) { this.bids = bids; }
    }

    public static class BidSummary {
        private int bidId;
        private int providerId;
        private String providerName;
        private int requestedSkillId;
        private int offeredSkillId;
        private boolean volunteer;
        private String message;
        private String status;
        private String requestedSkillName;
        private String offeredSkillName;
        // getters/setters omitted for brevity — generate
        public int getBidId() { return bidId; }
        public void setBidId(int bidId) { this.bidId = bidId; }
        public int getProviderId() { return providerId; }
        public void setProviderId(int providerId) { this.providerId = providerId; }
        public String getProviderName() { return providerName; }
        public void setProviderName(String providerName) { this.providerName = providerName; }
        public int getRequestedSkillId() { return requestedSkillId; }
        public void setRequestedSkillId(int requestedSkillId) { this.requestedSkillId = requestedSkillId; }
        public int getOfferedSkillId() { return offeredSkillId; }
        public void setOfferedSkillId(int offeredSkillId) { this.offeredSkillId = offeredSkillId; }
        public boolean isVolunteer() { return volunteer; }
        public void setVolunteer(boolean volunteer) { this.volunteer = volunteer; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getRequestedSkillName() { return requestedSkillName; }
        public void setRequestedSkillName(String requestedSkillName) { this.requestedSkillName = requestedSkillName; }
        public String getOfferedSkillName() { return offeredSkillName; }
        public void setOfferedSkillName(String offeredSkillName) { this.offeredSkillName = offeredSkillName; }
    }

    public static class ProviderBidView {
        private int bidId;
        private int queryId;
        private String queryTitle;
        private int requesterId;
        private String requesterName;
        private String requestedSkillName;
        private String offeredSkillName;
        private boolean volunteer;
        private String status;
        private String message;
        // getters/setters
        public int getBidId() { return bidId; }
        public void setBidId(int bidId) { this.bidId = bidId; }
        public int getQueryId() { return queryId; }
        public void setQueryId(int queryId) { this.queryId = queryId; }
        public String getQueryTitle() { return queryTitle; }
        public void setQueryTitle(String queryTitle) { this.queryTitle = queryTitle; }
        public int getRequesterId() { return requesterId; }
        public void setRequesterId(int requesterId) { this.requesterId = requesterId; }
        public String getRequesterName() { return requesterName; }
        public void setRequesterName(String requesterName) { this.requesterName = requesterName; }
        public String getRequestedSkillName() { return requestedSkillName; }
        public void setRequestedSkillName(String requestedSkillName) { this.requestedSkillName = requestedSkillName; }
        public String getOfferedSkillName() { return offeredSkillName; }
        public void setOfferedSkillName(String offeredSkillName) { this.offeredSkillName = offeredSkillName; }
        public boolean isVolunteer() { return volunteer; }
        public void setVolunteer(boolean volunteer) { this.volunteer = volunteer; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }
}
