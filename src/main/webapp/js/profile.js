// Profile Page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    loadUserProfile();
    
    const profileForm = document.getElementById('profileForm');
    if (profileForm) {
        profileForm.addEventListener('submit', handleSaveProfile);
    }
});

function loadUserProfile() {
    // Load profile from localStorage or use defaults
    const savedProfile = localStorage.getItem('userProfile');
    const session = JSON.parse(localStorage.getItem('userSession') || '{}');
    
    let profile = {
        name: 'John Doe',
        email: session.email || 'john@example.com',
        location: 'San Francisco, CA',
        bio: 'Passionate developer and teacher looking to exchange skills.'
    };
    
    if (savedProfile) {
        try {
            profile = { ...profile, ...JSON.parse(savedProfile) };
        } catch (e) {
            console.error('Error loading profile:', e);
        }
    }
    
    // Populate form fields
    document.getElementById('name').value = profile.name;
    document.getElementById('email-readonly').value = profile.email;
    document.getElementById('location').value = profile.location;
    document.getElementById('bio').value = profile.bio;
}

function handleSaveProfile(e) {
    e.preventDefault();
    
    // Get form values
    const profile = {
        name: document.getElementById('name').value.trim(),
        email: document.getElementById('email-readonly').value,
        location: document.getElementById('location').value.trim(),
        bio: document.getElementById('bio').value.trim()
    };
    
    // Validate required fields
    if (!profile.name) {
        showFieldError('name', 'Name is required');
        return;
    }
    
    if (profile.name.length < 2) {
        showFieldError('name', 'Name must be at least 2 characters');
        return;
    }
    
    if (profile.bio && profile.bio.length > 500) {
        showFieldError('bio', 'Bio must be less than 500 characters');
        return;
    }
    
    // Clear any existing errors
    clearFieldErrors();
    
    // Show loading state
    setProfileLoading(true);
    
    // Simulate API save
    setTimeout(() => {
        try {
            // Save to localStorage
            localStorage.setItem('userProfile', JSON.stringify(profile));
            
            setProfileLoading(false);
            showSuccessMessage('Profile saved successfully!');
            showToast('Profile updated successfully!', 'success');
            
        } catch (error) {
            console.error('Error saving profile:', error);
            setProfileLoading(false);
            showToast('Error saving profile. Please try again.', 'error');
        }
    }, 1000);
}

function showFieldError(fieldId, message) {
    const field = document.getElementById(fieldId);
    const formGroup = field.parentElement;
    
    // Remove existing error
    clearFieldError(fieldId);
    
    // Add error class
    formGroup.classList.add('error');
    
    // Add error message
    const errorDiv = document.createElement('div');
    errorDiv.className = 'field-error';
    errorDiv.textContent = message;
    formGroup.appendChild(errorDiv);
    
    // Focus the field
    field.focus();
}

function clearFieldError(fieldId) {
    const field = document.getElementById(fieldId);
    const formGroup = field.parentElement;
    
    formGroup.classList.remove('error', 'success');
    
    const existingError = formGroup.querySelector('.field-error');
    if (existingError) {
        existingError.remove();
    }
}

function clearFieldErrors() {
    const formGroups = document.querySelectorAll('.form-group');
    formGroups.forEach(group => {
        group.classList.remove('error', 'success');
        const error = group.querySelector('.field-error');
        if (error) error.remove();
    });
}

function setProfileLoading(isLoading) {
    const form = document.getElementById('profileForm');
    const submitBtn = form.querySelector('button[type="submit"]');
    
    if (isLoading) {
        form.classList.add('loading');
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
    } else {
        form.classList.remove('loading');
        submitBtn.disabled = false;
        submitBtn.innerHTML = 'Save Profile';
    }
}

function showSuccessMessage(message) {
    // Remove existing success messages
    const existingMessages = document.querySelectorAll('.success-message');
    existingMessages.forEach(msg => msg.remove());
    
    // Create success message
    const successDiv = document.createElement('div');
    successDiv.className = 'success-message';
    successDiv.innerHTML = `
        <i class="fas fa-check-circle"></i>
        <span>${message}</span>
    `;
    
    // Insert at top of profile content
    const profileContent = document.querySelector('.profile-content');
    profileContent.insertBefore(successDiv, profileContent.firstChild);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (successDiv.parentNode) {
            successDiv.style.animation = 'fadeOut 0.3s ease-out';
            setTimeout(() => successDiv.remove(), 300);
        }
    }, 5000);
}

// Real-time validation
document.addEventListener('DOMContentLoaded', function() {
    const nameField = document.getElementById('name');
    const bioField = document.getElementById('bio');
    
    if (nameField) {
        nameField.addEventListener('input', debounce(function() {
            const value = this.value.trim();
            if (value && value.length >= 2) {
                clearFieldError('name');
                this.parentElement.classList.add('success');
            }
        }, 300));
    }
    
    if (bioField) {
        bioField.addEventListener('input', function() {
            const remaining = 500 - this.value.length;
            let counter = this.parentElement.querySelector('.char-counter');
            
            if (!counter) {
                counter = document.createElement('div');
                counter.className = 'char-counter';
                counter.style.cssText = 'font-size: 0.75rem; color: #64748b; margin-top: 0.25rem; text-align: right;';
                this.parentElement.appendChild(counter);
            }
            
            counter.textContent = `${remaining} characters remaining`;
            counter.style.color = remaining < 0 ? '#dc2626' : '#64748b';
            
            if (remaining < 0) {
                this.parentElement.classList.add('error');
            } else {
                this.parentElement.classList.remove('error');
            }
        });
    }
});

// Add CSS for animations
const profileStyles = document.createElement('style');
profileStyles.textContent = `
    @keyframes fadeOut {
        from { opacity: 1; }
        to { opacity: 0; }
    }
    
    .form-group.success input,
    .form-group.success textarea {
        border-color: #10b981;
    }
    
    .char-counter {
        font-size: 0.75rem;
        color: #64748b;
        margin-top: 0.25rem;
        text-align: right;
    }
`;
document.head.appendChild(profileStyles);
