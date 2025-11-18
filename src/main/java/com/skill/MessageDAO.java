package com.skill;

import java.sql.*;
import java.util.*;

public class MessageDAO {

    private static final String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    private static final String JDBC_USER = "root";
    private static final String JDBC_PASS = "aTTri21..";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

    public static boolean isParticipant(int transactionId, int userId) throws SQLException {
        String sql = "SELECT RequesterID, ProviderID FROM Transactions WHERE TransactionID = ?";
        try (Connection c = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, transactionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return false;
                int req = rs.getInt("RequesterID");
                int prov = rs.getInt("ProviderID");
                return userId == req || userId == prov;
            }
        }
    }

    public static List<Map<String,Object>> getMessagesForTransaction(int transactionId, int limit) throws SQLException {
        String sql = "SELECT m.MessageID, m.TransactionID, m.SenderID, m.Content, m.SentAt, u.Username, u.FullName " +
                     "FROM Messages m JOIN Users u ON m.SenderID = u.UserID " +
                     "WHERE m.TransactionID = ? ORDER BY m.SentAt ASC LIMIT ?";
        List<Map<String,Object>> out = new ArrayList<>();
        try (Connection c = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, transactionId);
            ps.setInt(2, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String,Object> m = new HashMap<>();
                    m.put("messageId", rs.getLong("MessageID"));
                    m.put("senderId", rs.getInt("SenderID"));
                    String name = rs.getString("FullName") != null ? rs.getString("FullName") : rs.getString("Username");
                    m.put("senderName", name);
                    m.put("content", rs.getString("Content"));
                    m.put("sentAt", rs.getString("SentAt"));
                    out.add(m);
                }
            }
        }
        return out;
    }

    public static int insertMessage(int transactionId, int senderId, String content) throws SQLException {
        String sql = "INSERT INTO Messages (TransactionID, SenderID, Content) VALUES (?, ?, ?)";
        try (Connection c = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS);
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, transactionId);
            ps.setInt(2, senderId);
            ps.setString(3, content);
            int affected = ps.executeUpdate();
            if (affected == 0) return -1;
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
            return -1;
        }
    }
}
