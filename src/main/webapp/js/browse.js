// Browse Requests Page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    loadSkillRequests();
    
    const proposalForm = document.getElementById('proposalForm');
    if (proposalForm) {
        proposalForm.addEventListener('submit', handleSendProposal);
    }
});

let skillRequests = [
    {
        id: 'REQ001',
        postedBy: 'Alice Smith',
        skillOffered: 'Python Programming',
        skillWanted: 'React Development',
        description: 'I can teach Python data science in exchange for React lessons'
    },
    {
        id: 'REQ002',
        postedBy: 'Bob Johnson',
        skillOffered: 'Guitar Lessons',
        skillWanted: 'Photography',
        description: 'Professional guitar instructor looking to learn photography'
    },
    {
        id: 'REQ003',
        postedBy: 'Carol White',
        skillOffered: 'Digital Marketing',
        skillWanted: 'Web Development',
        description: 'Marketing expert seeking web development skills'
    },
    {
        id: 'REQ004',
        postedBy: 'David Wilson',
        skillOffered: 'Graphic Design',
        skillWanted: 'Video Editing',
        description: 'Creative designer wanting to learn video editing techniques'
    },
    {
        id: 'REQ005',
        postedBy: 'Emma Davis',
        skillOffered: 'Spanish Language',
        skillWanted: 'Cooking',
        description: 'Native Spanish speaker looking to learn culinary skills'
    }
];

let selectedRequest = null;

function loadSkillRequests() {
    renderRequests();
}

function renderRequests() {
    const tableBody = document.getElementById('requestsTableBody');
    
    if (!tableBody) return;
    
    if (skillRequests.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="5" class="browse-empty">
                    <i class="fas fa-search"></i>
                    <h3>No Requests Available</h3>
                    <p>Check back later for new skill exchange opportunities.</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tableBody.innerHTML = skillRequests.map(request => `
        <tr>
            <td class="request-id" data-label="Request ID">${request.id}</td>
            <td data-label="Posted By">${escapeHtml(request.postedBy)}</td>
            <td data-label="Skill Offered">${escapeHtml(request.skillOffered)}</td>
            <td data-label="Skill Wanted">${escapeHtml(request.skillWanted)}</td>
            <td data-label="Actions">
                <button class="btn btn-primary btn-sm" 
                        onclick="openProposalModal('${request.id}', '${escapeHtml(request.postedBy)}', '${escapeHtml(request.skillOffered)}', '${escapeHtml(request.skillWanted)}')">
                    Send Proposal
                </button>
            </td>
        </tr>
    `).join('');
}

function openProposalModal(requestId, postedBy, skillOffered, skillWanted) {
    selectedRequest = skillRequests.find(req => req.id === requestId);
    
    if (!selectedRequest) {
        showToast('Request not found', 'error');
        return;
    }
    
    const modal = document.getElementById('proposalModal');
    const requestDetails = document.getElementById('requestDetails');
    
    if (modal && requestDetails) {
        // Populate request details
        requestDetails.innerHTML = `
            <p><strong>They offer:</strong> ${escapeHtml(selectedRequest.skillOffered)}</p>
            <p><strong>They want:</strong> ${escapeHtml(selectedRequest.skillWanted)}</p>
            <p class="text-sm text-muted-foreground mt-2">${escapeHtml(selectedRequest.description)}</p>
        `;
        
        // Reset form
        document.getElementById('proposalForm').reset();
        clearFormErrors();
        
        // Show modal
        modal.classList.add('show');
        modal.style.display = 'flex';
        
        // Focus message field
        document.getElementById('proposalMessage').focus();
    }
}

function closeProposalModal() {
    const modal = document.getElementById('proposalModal');
    if (modal) {
        modal.classList.remove('show');
        setTimeout(() => {
            modal.style.display = 'none';
        }, 200);
    }
    selectedRequest = null;
}

function handleSendProposal(e) {
    e.preventDefault();
    
    if (!selectedRequest) {
        showToast('No request selected', 'error');
        return;
    }
    
    const message = document.getElementById('proposalMessage').value.trim();
    
    // Validation
    if (!message) {
        showFormError('proposalMessage', 'Proposal message is required');
        return;
    }
    
    if (message.length < 20) {
        showFormError('proposalMessage', 'Proposal message must be at least 20 characters');
        return;
    }
    
    if (message.length > 500) {
        showFormError('proposalMessage', 'Proposal message must be less than 500 characters');
        return;
    }
    
    // Clear errors
    clearFormErrors();
    
    // Show loading
    setFormLoading(true);
    
    // Simulate API call
    setTimeout(() => {
        const proposal = {
            id: generateId(),
            requestId: selectedRequest.id,
            toUser: selectedRequest.postedBy,
            message: message,
            timestamp: new Date().toISOString(),
            status: 'pending'
        };
        
        // Save proposal to localStorage (in real app, this would be sent to server)
        saveProposal(proposal);
        
        setFormLoading(false);
        closeProposalModal();
        
        showToast(`Proposal sent to ${selectedRequest.postedBy} successfully!`, 'success');
        
        // Optionally remove the request from the list or mark as applied
        markRequestAsApplied(selectedRequest.id);
        
    }, 1000);
}

function saveProposal(proposal) {
    try {
        const existingProposals = JSON.parse(localStorage.getItem('sentProposals') || '[]');
        existingProposals.push(proposal);
        localStorage.setItem('sentProposals', JSON.stringify(existingProposals));
    } catch (e) {
        console.error('Error saving proposal:', e);
    }
}

function markRequestAsApplied(requestId) {
    const tableRow = document.querySelector(`tr td[data-label="Request ID"]:contains("${requestId}")`);
    if (tableRow) {
        const row = tableRow.closest('tr');
        const actionCell = row.querySelector('td:last-child');
        if (actionCell) {
            actionCell.innerHTML = `
                <span class="badge badge-success">
                    <i class="fas fa-check"></i> Applied
                </span>
            `;
        }
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
    const modal = document.getElementById('proposalModal');
    const formGroups = modal.querySelectorAll('.form-group');
    
    formGroups.forEach(group => {
        group.classList.remove('error');
        const error = group.querySelector('.field-error');
        if (error) error.remove();
    });
}

function setFormLoading(isLoading) {
    const form = document.getElementById('proposalForm');
    const submitBtn = form.querySelector('button[type="submit"]');
    const cancelBtn = form.querySelector('button[type="button"]');
    
    if (isLoading) {
        form.style.opacity = '0.7';
        submitBtn.disabled = true;
        cancelBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
    } else {
        form.style.opacity = '1';
        submitBtn.disabled = false;
        cancelBtn.disabled = false;
        submitBtn.innerHTML = 'Send Proposal';
    }
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

// Search functionality (future enhancement)
function searchRequests() {
    const searchInput = document.getElementById('searchInput');
    if (!searchInput) return;
    
    const searchTerm = searchInput.value.toLowerCase().trim();
    
    if (searchTerm === '') {
        renderRequests();
        return;
    }
    
    const filteredRequests = skillRequests.filter(request => 
        request.postedBy.toLowerCase().includes(searchTerm) ||
        request.skillOffered.toLowerCase().includes(searchTerm) ||
        request.skillWanted.toLowerCase().includes(searchTerm) ||
        request.description.toLowerCase().includes(searchTerm)
    );
    
    // Temporarily update the skillRequests array for rendering
    const originalRequests = [...skillRequests];
    skillRequests = filteredRequests;
    renderRequests();
    skillRequests = originalRequests;
}

// Close modal when clicking outside
document.addEventListener('click', function(e) {
    const modal = document.getElementById('proposalModal');
    if (modal && e.target === modal) {
        closeProposalModal();
    }
});

// Close modal with Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeProposalModal();
    }
});

// Real-time validation
document.addEventListener('DOMContentLoaded', function() {
    const messageField = document.getElementById('proposalMessage');
    
    if (messageField) {
        messageField.addEventListener('input', function() {
            const value = this.value.trim();
            const length = value.length;
            
            // Add character counter
            let counter = this.parentElement.querySelector('.char-counter');
            if (!counter) {
                counter = document.createElement('div');
                counter.className = 'char-counter';
                counter.style.cssText = 'font-size: 0.75rem; color: #64748b; margin-top: 0.25rem; text-align: right;';
                this.parentElement.appendChild(counter);
            }
            
            counter.textContent = `${length}/500 characters`;
            
            if (length > 500) {
                counter.style.color = '#dc2626';
                this.parentElement.classList.add('error');
            } else if (length >= 20) {
                counter.style.color = '#10b981';
                this.parentElement.classList.remove('error');
            } else {
                counter.style.color = '#64748b';
                this.parentElement.classList.remove('error');
            }
        });
    }
});

// Helper for contains selector (since CSS doesn't have this)
function findElementByText(selector, text) {
    const elements = document.querySelectorAll(selector);
    return Array.from(elements).find(el => el.textContent.includes(text));
}
