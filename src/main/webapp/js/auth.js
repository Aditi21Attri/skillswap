// Authentication JavaScript
document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('loginForm');
    
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }
});

function handleLogin(e) {
    e.preventDefault();
    
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    // Basic validation
    if (!email || !password) {
        showMessage('Please enter both email and password.', 'error');
        return;
    }
    
    if (!isValidEmail(email)) {
        showMessage('Please enter a valid email address.', 'error');
        return;
    }
    
    // Show loading state
    setLoading(true);
    
    // Simulate API call
    setTimeout(() => {
        setLoading(false);
        
        // Mock authentication - in real app, this would be an API call
        if (email && password) {
            showMessage('Login successful! Redirecting...', 'success');
            
            // Store user session (in real app, use proper authentication)
            localStorage.setItem('userSession', JSON.stringify({
                email: email,
                loginTime: new Date().toISOString()
            }));
            
            // Redirect to dashboard
            setTimeout(() => {
                window.location.href = 'dashboard.html';
            }, 1000);
        } else {
            showMessage('Invalid credentials. Please try again.', 'error');
        }
    }, 1000);
}

function handleRegister() {
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    if (!email || !password) {
        showMessage('Please fill in all fields to register.', 'error');
        return;
    }
    
    if (!isValidEmail(email)) {
        showMessage('Please enter a valid email address.', 'error');
        return;
    }
    
    if (password.length < 6) {
        showMessage('Password must be at least 6 characters long.', 'error');
        return;
    }
    
    showMessage('Registration successful! You can now login.', 'success');
}

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function setLoading(isLoading) {
    const form = document.getElementById('loginForm');
    const buttons = form.querySelectorAll('button');
    
    if (isLoading) {
        form.classList.add('loading');
        buttons.forEach(btn => {
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';
        });
    } else {
        form.classList.remove('loading');
        buttons.forEach((btn, index) => {
            btn.disabled = false;
            if (index === 0) {
                btn.innerHTML = 'Login';
            } else {
                btn.innerHTML = 'Register';
            }
        });
    }
}

function showMessage(message, type) {
    // Remove existing messages
    const existingMessages = document.querySelectorAll('.auth-message');
    existingMessages.forEach(msg => msg.remove());
    
    // Create new message
    const messageDiv = document.createElement('div');
    messageDiv.className = `auth-message ${type}`;
    messageDiv.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check-circle' : 'exclamation-triangle'}"></i>
        <span>${message}</span>
    `;
    
    // Add styles
    messageDiv.style.cssText = `
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 1rem;
        border-radius: 0.5rem;
        margin-bottom: 1rem;
        font-size: 0.875rem;
        animation: slideDown 0.3s ease-out;
        ${type === 'success' ? 
            'background: #f0fdf4; border: 1px solid #bbf7d0; color: #166534;' : 
            'background: #fef2f2; border: 1px solid #fecaca; color: #dc2626;'
        }
    `;
    
    // Insert before form
    const form = document.getElementById('loginForm');
    form.parentNode.insertBefore(messageDiv, form);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (messageDiv.parentNode) {
            messageDiv.remove();
        }
    }, 5000);
}

// Add CSS animation
const style = document.createElement('style');
style.textContent = `
    @keyframes slideDown {
        from {
            opacity: 0;
            transform: translateY(-10px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
`;
document.head.appendChild(style);
