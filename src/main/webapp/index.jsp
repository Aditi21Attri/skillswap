<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Skill Exchange Platform</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/auth.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="auth-container">
        <div class="auth-card">
        
			<i class="fa-solid fa-user-circle platform-icon"></i>
        
            <div class="auth-header">
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
