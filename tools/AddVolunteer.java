package tools;

import java.sql.*;

public class AddVolunteer {
    public static void main(String[] args) {
        String url = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
        String user = "root";
        String pass = "aTTri21..";
        String alter = "ALTER TABLE Bids ADD COLUMN Volunteer TINYINT(1) NOT NULL DEFAULT 0";
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(url, user, pass);
                 Statement st = con.createStatement()) {
                st.executeUpdate(alter);
                System.out.println("ALTER TABLE executed successfully: Volunteer column added.");
            }
        } catch (SQLException se) {
            System.err.println("SQL error: " + se.getMessage());
            se.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
