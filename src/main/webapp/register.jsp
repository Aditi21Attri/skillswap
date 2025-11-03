<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register - XpertiseXchange</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/auth.css">
    <link rel="stylesheet" href="css/register.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">

    
</head>
<body>
<div class="register-container">
    <h1><i class="fas fa-user-plus"></i> Sign Up</h1>
    <p class="subtitle">Join XpertiseXchange to learn & share your skills!</p>

    <% 
        String message = (String) request.getAttribute("message");
        String error = (String) request.getAttribute("error");
        if (message != null) {
    %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= message %></div>
    <% } 
        if (error != null) {
    %>
        <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> <%= error %></div>
    <% } %>

    <form action="Register" method="post">
        <div class="section-title">Account Information</div>

        <div class="form-group">
            <i class="fas fa-user"></i>
            <input type="text" id="username" name="username" required placeholder="Choose a username (e.g., aditi_123)">
        </div>

        <div class="form-group">
            <i class="fas fa-envelope"></i>
            <input type="email" id="email" name="email" required placeholder="you@example.com">
        </div>

        <div class="form-group">
            <i class="fas fa-lock"></i>
            <input type="password" id="password" name="password" required placeholder="Create a password" minlength="6">
            <i class="fas fa-eye toggle-password" onclick="togglePassword('password', this)"></i>
        </div>

        <div class="form-group">
            <i class="fas fa-lock"></i>
            <input type="password" id="confirmPassword" name="confirmPassword" required placeholder="Confirm your password">
            <i class="fas fa-eye toggle-password" onclick="togglePassword('confirmPassword', this)"></i>
        </div>

        <div class="section-title">Personal Details</div>

        <div class="form-group">
            <i class="fas fa-id-card"></i>
            <input type="text" id="fullName" name="fullName" required placeholder="Enter your full name">
        </div>

        <div class="form-group">
            <i class="fas fa-pen-nib"></i>
            <textarea id="bio" name="bio" maxlength="150" placeholder="Tell us a little about yourself..."></textarea>
            <div class="bio-counter" id="bioCounter">0 / 150</div>
        </div>

        <button type="submit" class="btn"><i class="fas fa-user-plus"></i> Create Account</button>
    </form>

    <div class="login-link">
        Already a member? <a href="index.jsp">Login here</a>
    </div>
</div>

<script>
    // Password toggle visibility
    function togglePassword(fieldId, icon) {
        const field = document.getElementById(fieldId);
        if (field.type === "password") {
            field.type = "text";
            icon.classList.replace("fa-eye", "fa-eye-slash");
        } else {
            field.type = "password";
            icon.classList.replace("fa-eye-slash", "fa-eye");
        }
    }

    // Password match validation
    document.querySelector('form').addEventListener('submit', e => {
        const password = document.getElementById('password').value;
        const confirm = document.getElementById('confirmPassword').value;
        if (password !== confirm) {
            e.preventDefault();
            alert("Passwords do not match!");
        }
    });

    // Bio character counter
    const bio = document.getElementById('bio');
    const counter = document.getElementById('bioCounter');
    bio.addEventListener('input', () => {
        counter.textContent = `${bio.value.length} / 150`;
    });
</script>
</body>
</html>
