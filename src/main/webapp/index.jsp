<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Skill Exchange Platform</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/auth.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="auth-container">
        <div class="auth-card">

            <div class="auth-header">
                <i class="fa-solid fa-user-circle platform-icon"></i>
                <h1 class="platform-title">Skill Exchange Platform</h1>
                <p class="platform-subtitle">Connect, Learn, and Grow Together</p>
            </div>

            <div class="auth-content">
                <!-- Display registration success message -->
                <%
                    String registered = request.getParameter("registered");
                    if (registered != null && registered.equals("true")) {
                %>
                    <div class="alert alert-success">
                        <i class="fas fa-check-circle"></i> Registration successful! Please login with your credentials.
                    </div>
                <%
                    }
                %>

                <!-- Display login error messages -->
                <%
                    String message = (String) request.getAttribute("message");
                    if (message != null) {
                %>
                    <div class="alert alert-error">
                        <i class="fas fa-exclamation-circle"></i> <%= message %>
                    </div>
                <%
                    }
                %>

                <form id="loginForm" class="auth-form" action="MyLogin" method="post">
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" name="email" id="email" placeholder="Enter your email" required>
                    </div>

                    <div class="form-group">
                        <label for="password">Password</label>
                        <input type="password" name="password" id="password" placeholder="Enter your password" required>
                    </div>

                    <div class="form-buttons">
                        <button type="submit" class="btn btn-primary">Login</button>
                        <button type="button" class="btn btn-outline" onclick="handleRegister()">Register</button>
                    </div>
                </form>
            </div>
            <!-- Right-side illustration / visual accent -->
            <div class="auth-illustration">
                <div class="ill-content">
                    <div style="text-align:center">
                        <i class="fas fa-handshake" style="font-size:56px;color:rgba(15,23,42,0.85);margin-bottom:12px"></i>
                        <h3 style="margin:0;font-size:1.1rem;color:rgba(15,23,42,0.9)">Share skills. Build connections.</h3>
                        <p style="margin-top:8px;color:rgba(15,23,42,0.65);font-size:0.9rem">Post requests, propose trades, and learn from others in your community.</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function handleRegister() {
            // Redirect to registration page
            window.location.href = "register.jsp";
        }
    </script>
</body>
</html>
