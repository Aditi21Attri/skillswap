package tools;

import java.sql.*;

public class QueryBids {
    public static void main(String[] args) {
        String url = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
        String user = "root";
        String pass = "aTTri21..";
        String sql = "SELECT BidID, QueryID, ProviderID, RequestedSkillID, WantedSkillID, OfferedSkillID, Volunteer, BidDetails, BidDate FROM Bids ORDER BY BidID DESC LIMIT 10";
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(url, user, pass);
                 PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                System.out.println("BidID | QueryID | ProviderID | RequestedSkillID | WantedSkillID | OfferedSkillID | Volunteer | BidDate | BidDetails");
                while (rs.next()) {
                    int bidId = rs.getInt("BidID");
                    int qid = rs.getInt("QueryID");
                    int pid = rs.getInt("ProviderID");
                    String req = rs.getString("RequestedSkillID");
                    String want = rs.getString("WantedSkillID");
                    String off = rs.getString("OfferedSkillID");
                    String vol = rs.getString("Volunteer");
                    String details = rs.getString("BidDetails");
                    String date = rs.getString("BidDate");
                    System.out.printf("%d | %d | %d | %s | %s | %s | %s | %s | %s\n", bidId, qid, pid, req, want, off, vol, date, details != null ? details.replaceAll("\n"," ") : "");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Failed to query Bids: " + e.getMessage());
        }
    }
}
