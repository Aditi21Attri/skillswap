package com.skill;

import java.sql.*;
import java.util.*;

public class ReviewDAO {

    private static final String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    private static final String JDBC_USER = "root";
    private static final String JDBC_PASS = "aTTri21..";

    static {
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
        catch (ClassNotFoundException e) { throw new RuntimeException(e); }
    }

    public static int insertReview(int transactionId, int reviewerId, int revieweeId, Integer rating, String comments, boolean skipped) throws SQLException {
        String sql = "INSERT INTO Reviews (TransactionID, ReviewerID, RevieweeID, Rating, Comments, Skipped) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection c = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, transactionId);
            ps.setInt(2, reviewerId);
            ps.setInt(3, revieweeId);
            if (rating == null) ps.setNull(4, Types.TINYINT); else ps.setInt(4, rating);
            ps.setString(5, comments);
            ps.setInt(6, skipped ? 1 : 0);
            int affected = ps.executeUpdate();
            if (affected == 0) return -1;
            try (ResultSet keys = ps.getGeneratedKeys()) { if (keys.next()) return keys.getInt(1); }
            return -1;
        }
    }

    public static boolean hasReview(int transactionId, int reviewerId) throws SQLException {
        String sql = "SELECT 1 FROM Reviews WHERE TransactionID = ? AND ReviewerID = ? LIMIT 1";
        try (Connection c = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, transactionId);
            ps.setInt(2, reviewerId);
            try (ResultSet rs = ps.executeQuery()) { return rs.next(); }
        }
    }

    public static List<Map<String,Object>> getReviewsForUser(int userId) throws SQLException {
        String sql = "SELECT r.ReviewID, r.TransactionID, r.ReviewerID, r.Rating, r.Comments, r.Skipped, r.CreatedAt, u.Username, u.FullName " +
                     "FROM Reviews r JOIN Users u ON r.ReviewerID = u.UserID WHERE r.RevieweeID = ? ORDER BY r.CreatedAt DESC";
        List<Map<String,Object>> out = new ArrayList<>();
        try (Connection c = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String,Object> m = new HashMap<>();
                    m.put("reviewId", rs.getInt("ReviewID"));
                    m.put("transactionId", rs.getInt("TransactionID"));
                    m.put("reviewerId", rs.getInt("ReviewerID"));
                    String name = rs.getString("FullName") != null ? rs.getString("FullName") : rs.getString("Username");
                    m.put("reviewerName", name);
                    m.put("rating", rs.getObject("Rating"));
                    m.put("comments", rs.getString("Comments"));
                    m.put("skipped", rs.getInt("Skipped") == 1);
                    m.put("createdAt", rs.getString("CreatedAt"));
                    out.add(m);
                }
            }
        }
        return out;
    }
}
