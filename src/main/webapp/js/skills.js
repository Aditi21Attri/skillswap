// Skills Page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    loadUserSkills();
    
    const addSkillForm = document.getElementById('addSkillForm');
    if (addSkillForm) {
        addSkillForm.addEventListener('submit', handleAddSkill);
    }
});

let userSkills = [
    {
        id: '1',
        title: 'React Development',
        type: 'offer',
        description: 'Advanced React and TypeScript development'
    },
    {
        id: '2',
        title: 'Photography',
        type: 'want',
        description: 'Learn portrait and landscape photography'
    }
];

function loadUserSkills() {
    // Load skills from localStorage
    const savedSkills = localStorage.getItem('userSkills');
    if (savedSkills) {
        try {
            userSkills = JSON.parse(savedSkills);
        } catch (e) {
            console.error('Error loading skills:', e);
        }
    }
    
    renderSkills();
}

function renderSkills() {
    const skillsList = document.getElementById('skillsList');
    
    if (!skillsList) return;
    
    if (userSkills.length === 0) {
        skillsList.innerHTML = `
            <div class="skills-empty">
                <i class="fas fa-book-open"></i>
                <h3>No Skills Added</h3>
                <p>Start by adding skills you can offer or want to learn.</p>
                <button class="btn btn-primary" onclick="openAddSkillModal()">
                    <i class="fas fa-plus"></i> Add Your First Skill
                </button>
            </div>
        `;
        return;
    }
    
    skillsList.innerHTML = userSkills.map(skill => `
        <div class="skill-item" data-skill-id="${skill.id}">
            <div class="skill-info">
                <div class="skill-title-row">
                    <h3 class="skill-title">${escapeHtml(skill.title)}</h3>
                    <span class="skill-badge skill-${skill.type}">
                        ${skill.type === 'offer' ? 'Offering' : 'Seeking'}
                    </span>
                </div>
                <p class="skill-description">${escapeHtml(skill.description)}</p>
            </div>
            <button class="btn btn-outline btn-sm delete-btn" onclick="deleteSkill('${skill.id}')">
                <i class="fas fa-trash"></i>
            </button>
        </div>
    `).join('');
}

function openAddSkillModal() {
    const modal = document.getElementById('addSkillModal');
    if (modal) {
        modal.classList.add('show');
        modal.style.display = 'flex';
        
        // Reset form
        document.getElementById('addSkillForm').reset();
        clearFormErrors();
        
        // Focus first input
        document.getElementById('skillTitle').focus();
    }
}

function closeAddSkillModal() {
    const modal = document.getElementById('addSkillModal');
    if (modal) {
        modal.classList.remove('show');
        setTimeout(() => {
            modal.style.display = 'none';
        }, 200);
    }
}

function handleAddSkill(e) {
    e.preventDefault();
    
    const title = document.getElementById('skillTitle').value.trim();
    const type = document.getElementById('skillType').value;
    const description = document.getElementById('skillDescription').value.trim();
    
    // Validation
    if (!title) {
        showFormError('skillTitle', 'Skill title is required');
        return;
    }
    
    if (title.length < 3) {
        showFormError('skillTitle', 'Skill title must be at least 3 characters');
        return;
    }
    
    if (!description) {
        showFormError('skillDescription', 'Description is required');
        return;
    }
    
    if (description.length < 10) {
        showFormError('skillDescription', 'Description must be at least 10 characters');
        return;
    }
    
    // Check for duplicate titles
    const existingSkill = userSkills.find(skill => 
        skill.title.toLowerCase() === title.toLowerCase()
    );
    
    if (existingSkill) {
        showFormError('skillTitle', 'You already have a skill with this title');
        return;
    }
    
    // Clear errors
    clearFormErrors();
    
    // Show loading
    setFormLoading(true);
    
    // Simulate API call
    setTimeout(() => {
        const newSkill = {
            id: generateId(),
            title,
            type,
            description
        };
        
        userSkills.unshift(newSkill); // Add to beginning
        saveSkillsToStorage();
        renderSkills();
        
        setFormLoading(false);
        closeAddSkillModal();
        showToast(`Skill "${title}" added successfully!`, 'success');
        
        // Highlight new skill
        highlightSkill(newSkill.id);
    }, 500);
}

function deleteSkill(skillId) {
    const skill = userSkills.find(s => s.id === skillId);
    if (!skill) return;
    
    if (confirm(`Are you sure you want to delete the skill "${skill.title}"?`)) {
        // Add loading state to skill item
        const skillItem = document.querySelector(`[data-skill-id="${skillId}"]`);
        if (skillItem) {
            skillItem.classList.add('loading');
        }
        
        // Simulate API call
        setTimeout(() => {
            userSkills = userSkills.filter(s => s.id !== skillId);
            saveSkillsToStorage();
            renderSkills();
            showToast(`Skill "${skill.title}" deleted successfully!`, 'success');
        }, 300);
    }
}

function saveSkillsToStorage() {
    try {
        localStorage.setItem('userSkills', JSON.stringify(userSkills));
    } catch (e) {
        console.error('Error saving skills:', e);
        showToast('Error saving skills. Please try again.', 'error');
    }
}

function showFormError(fieldId, message) {
    const field = document.getElementById(fieldId);
    const formGroup = field.parentElement;
    
    // Remove existing error
    clearFormError(fieldId);
    
    // Add error class
    formGroup.classList.add('error');
    
    // Add error message
    const errorDiv = document.createElement('div');
    errorDiv.className = 'field-error';
    errorDiv.textContent = message;
    formGroup.appendChild(errorDiv);
    
    // Focus field
    field.focus();
}

function clearFormError(fieldId) {
    const field = document.getElementById(fieldId);
    const formGroup = field.parentElement;
    
    formGroup.classList.remove('error');
    const existingError = formGroup.querySelector('.field-error');
    if (existingError) {
        existingError.remove();
    }
}

function clearFormErrors() {
    const modal = document.getElementById('addSkillModal');
    const formGroups = modal.querySelectorAll('.form-group');
    
    formGroups.forEach(group => {
        group.classList.remove('error');
        const error = group.querySelector('.field-error');
        if (error) error.remove();
    });
}

function setFormLoading(isLoading) {
    const form = document.getElementById('addSkillForm');
    const submitBtn = form.querySelector('button[type="submit"]');
    const cancelBtn = form.querySelector('button[type="button"]');
    
    if (isLoading) {
        form.style.opacity = '0.7';
        submitBtn.disabled = true;
        cancelBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Adding...';
    } else {
        form.style.opacity = '1';
        submitBtn.disabled = false;
        cancelBtn.disabled = false;
        submitBtn.innerHTML = 'Add Skill';
    }
}

function highlightSkill(skillId) {
    setTimeout(() => {
        const skillItem = document.querySelector(`[data-skill-id="${skillId}"]`);
        if (skillItem) {
            skillItem.classList.add('success');
            skillItem.scrollIntoView({ behavior: 'smooth', block: 'center' });
            
            setTimeout(() => {
                skillItem.classList.remove('success');
            }, 2000);
        }
    }, 100);
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

// Close modal when clicking outside
document.addEventListener('click', function(e) {
    const modal = document.getElementById('addSkillModal');
    if (modal && e.target === modal) {
        closeAddSkillModal();
    }
});

// Close modal with Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeAddSkillModal();
    }
});

// Real-time validation
document.addEventListener('DOMContentLoaded', function() {
    const titleField = document.getElementById('skillTitle');
    const descField = document.getElementById('skillDescription');
    
    if (titleField) {
        titleField.addEventListener('input', debounce(function() {
            const value = this.value.trim();
            if (value && value.length >= 3) {
                clearFormError('skillTitle');
            }
        }, 300));
    }
    
    if (descField) {
        descField.addEventListener('input', debounce(function() {
            const value = this.value.trim();
            if (value && value.length >= 10) {
                clearFormError('skillDescription');
            }
        }, 300));
    }
});
