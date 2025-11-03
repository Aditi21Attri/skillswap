// Dashboard Common JavaScript
document.addEventListener('DOMContentLoaded', function() {
    // Check authentication
    checkAuthentication();
    
    // Set active tab based on current page
    setActiveTab();
    
    // Initialize page-specific features
    initializePage();
});

function checkAuthentication() {
    const session = localStorage.getItem('userSession');
    
    if (!session) {
        // Redirect to login if no session
        window.location.href = 'index.html';
        return;
    }
    
    try {
        const userData = JSON.parse(session);
        console.log('User authenticated:', userData.email);
    } catch (e) {
        console.error('Invalid session data');
        logout();
    }
}

function logout() {
    // Clear session
    localStorage.removeItem('userSession');
    localStorage.removeItem('userProfile');
    localStorage.removeItem('userSkills');
    
    // Show message and redirect
    showToast('Logged out successfully!', 'info');
    
    setTimeout(() => {
        window.location.href = 'index.html';
    }, 1000);
}

function setActiveTab() {
    const currentPage = window.location.pathname.split('/').pop();
    const tabLinks = document.querySelectorAll('.tab-trigger');
    
    tabLinks.forEach(tab => {
        tab.classList.remove('active');
        
        // Set active based on current page
        const href = tab.getAttribute('href');
        if (href && href.includes(currentPage)) {
            tab.classList.add('active');
        }
    });
    
    // Default to profile if on dashboard
    if (currentPage === 'dashboard.html') {
        const profileTab = document.querySelector('.tab-trigger[href="profile.html"]');
        if (profileTab) {
            profileTab.classList.add('active');
        }
    }
}

function initializePage() {
    const currentPage = window.location.pathname.split('/').pop();
    
    // Add page-specific initialization here
    console.log('Initialized page:', currentPage);
}

function showToast(message, type = 'info', duration = 3000) {
    // Remove existing toasts
    const existingToasts = document.querySelectorAll('.toast-message');
    existingToasts.forEach(toast => toast.remove());
    
    // Create toast element
    const toast = document.createElement('div');
    toast.className = `toast-message toast-${type}`;
    
    // Toast content
    toast.innerHTML = `
        <div class="toast-content">
            <i class="fas fa-${getToastIcon(type)}"></i>
            <span>${message}</span>
            <button class="toast-close" onclick="this.parentElement.parentElement.remove()">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `;
    
    // Style toast
    toast.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 1000;
        max-width: 400px;
        border-radius: 0.5rem;
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        animation: slideInRight 0.3s ease-out;
        ${getToastStyles(type)}
    `;
    
    // Add to page
    document.body.appendChild(toast);
    
    // Auto remove
    if (duration > 0) {
        setTimeout(() => {
            if (toast.parentNode) {
                toast.style.animation = 'slideOutRight 0.3s ease-out';
                setTimeout(() => toast.remove(), 300);
            }
        }, duration);
    }
}

function getToastIcon(type) {
    const icons = {
        success: 'check-circle',
        error: 'exclamation-triangle',
        warning: 'exclamation-circle',
        info: 'info-circle'
    };
    return icons[type] || 'info-circle';
}

function getToastStyles(type) {
    const styles = {
        success: 'background: #f0fdf4; border: 1px solid #bbf7d0; color: #166534;',
        error: 'background: #fef2f2; border: 1px solid #fecaca; color: #dc2626;',
        warning: 'background: #fffbeb; border: 1px solid #fed7aa; color: #92400e;',
        info: 'background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af;'
    };
    return styles[type] || styles.info;
}

// Utility functions
function formatDate(date) {
    return new Date(date).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

function formatTime(date) {
    return new Date(date).toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit'
    });
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

// Add CSS for toasts
const toastStyles = document.createElement('style');
toastStyles.textContent = `
    .toast-content {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 1rem;
    }
    
    .toast-content i:first-child {
        font-size: 1.25rem;
        flex-shrink: 0;
    }
    
    .toast-content span {
        flex: 1;
        font-weight: 500;
    }
    
    .toast-close {
        background: none;
        border: none;
        cursor: pointer;
        padding: 0.25rem;
        opacity: 0.7;
        color: inherit;
        border-radius: 0.25rem;
        transition: opacity 0.2s ease-in-out;
    }
    
    .toast-close:hover {
        opacity: 1;
    }
    
    @keyframes slideInRight {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOutRight {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(toastStyles);
