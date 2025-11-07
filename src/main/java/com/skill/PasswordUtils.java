package com.skill;

import java.security.SecureRandom;
import java.security.spec.KeySpec;
import java.util.Base64;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * Simple PBKDF2-based password hashing utilities.
 * Stores passwords in the format: iterations:salt:hash (all Base64 where applicable).
 */
public class PasswordUtils {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int SALT_LENGTH = 16; // bytes
    private static final int ITERATIONS = 65536;
    private static final int KEY_LENGTH = 256; // bits

    public static String generateSalt() {
        byte[] salt = new byte[SALT_LENGTH];
        RANDOM.nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
    }

    public static String hashPassword(String password, String saltBase64) throws Exception {
        byte[] salt = Base64.getDecoder().decode(saltBase64);
        KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, ITERATIONS, KEY_LENGTH);
        SecretKeyFactory f = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        byte[] hash = f.generateSecret(spec).getEncoded();
        return ITERATIONS + ":" + saltBase64 + ":" + Base64.getEncoder().encodeToString(hash);
    }

    public static String generateSecurePassword(String password) throws Exception {
        String salt = generateSalt();
        return hashPassword(password, salt);
    }

    public static boolean verifyPassword(String password, String stored) throws Exception {
        if (stored == null || stored.isEmpty()) return false;
        String[] parts = stored.split(":");
        if (parts.length != 3) return false;

        int iterations = Integer.parseInt(parts[0]);
        String saltBase64 = parts[1];
        byte[] salt = Base64.getDecoder().decode(saltBase64);

        KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, iterations, KEY_LENGTH);
        SecretKeyFactory f = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        byte[] hash = f.generateSecret(spec).getEncoded();
        byte[] storedHash = Base64.getDecoder().decode(parts[2]);

        return java.security.MessageDigest.isEqual(hash, storedHash);
    }
}
