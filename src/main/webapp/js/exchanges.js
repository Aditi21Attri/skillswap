// Exchanges Page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    loadExchangeData();
});

let receivedProposals = [
    {
        id: 'PROP001',
        requestId: 'REQ001',
        fromUser: 'David Wilson',
        message: 'Hi Alice! I have 5 years of React experience and would love to learn Python data science. When can we start?',
        status: 'pending'
    },
    {
        id: 'PROP002',
        requestId: 'REQ002',
        fromUser: 'Emma Davis',
        message: 'I am a professional photographer and would enjoy learning guitar. Let me know if you are interested!',
        status: 'pending'
    }
];

let activeExchanges = [
    {
        id: 'EX001',
        withUser: 'Alice Smith',
        offeredSkill: 'React Development',
        requestedSkill: 'Python Programming',
        status: 'ongoing'
    }
];

function loadExchangeData() {
    // Load from localStorage
    try {
        const savedProposals = localStorage.getItem('receivedProposals');
        if (savedProposals) {
            receivedProposals = JSON.parse(savedProposals);
        }
        
        const savedExchanges = localStorage.getItem('activeExchanges');
        if (savedExchanges) {
            activeExchanges = JSON.parse(savedExchanges);
        }
    } catch (e) {
        console.error('Error loading exchange data:', e);
    }
    
    renderProposals();
    renderExchanges();
}

function renderProposals() {
    const tableBody = document.getElementById('proposalsTableBody');
    
    if (!tableBody) return;
    
    if (receivedProposals.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="4" class="panel-empty">
                    <i class="fas fa-inbox"></i>
                    <h4>No Proposals Yet</h4>
                    <p>Proposals from other users will appear here.</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tableBody.innerHTML = receivedProposals.map(proposal => `
        <tr data-proposal-id="${proposal.id}">
            <td class="proposal-id" data-label="Proposal ID">${proposal.id}</td>
            <td data-label="From User">${escapeHtml(proposal.fromUser)}</td>
            <td data-label="Status">
                <span class="status-badge status-${proposal.status}">${proposal.status}</span>
            </td>
            <td data-label="Actions">
                ${proposal.status === 'pending' ? `
                    <div class="action-buttons">
                        <button class="btn btn-success btn-sm" 
                                onclick="acceptProposal('${proposal.id}')"
                                title="Accept">
                            <i class="fas fa-check"></i>
                        </button>
                        <button class="btn btn-danger btn-sm" 
                                onclick="rejectProposal('${proposal.id}')"
                                title="Reject">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                ` : `
                    <span class="badge badge-${proposal.status === 'accepted' ? 'success' : 'danger'}">
                        ${proposal.status === 'accepted' ? 'Accepted' : 'Rejected'}
                    </span>
                `}
            </td>
        </tr>
    `).join('');
}

function renderExchanges() {
    const tableBody = document.getElementById('exchangesTableBody');
    
    if (!tableBody) return;
    
    if (activeExchanges.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="4" class="panel-empty">
                    <i class="fas fa-handshake"></i>
                    <h4>No Active Exchanges</h4>
                    <p>Accepted exchanges will appear here.</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tableBody.innerHTML = activeExchanges.map(exchange => `
        <tr data-exchange-id="${exchange.id}">
            <td class="exchange-id" data-label="Exchange ID">${exchange.id}</td>
            <td data-label="With User">${escapeHtml(exchange.withUser)}</td>
            <td data-label="Status">
                <span class="status-badge status-${exchange.status}">${exchange.status}</span>
            </td>
            <td data-label="Actions">
                ${exchange.status === 'ongoing' ? `
                    <button class="btn btn-primary btn-sm" 
                            onclick="markCompleted('${exchange.id}')">
                        Mark Completed
                    </button>
                ` : `
                    <span class="badge badge-success">
                        <i class="fas fa-check"></i> Completed
                    </span>
                `}
            </td>
        </tr>
    `).join('');
}

function acceptProposal(proposalId) {
    const proposal = receivedProposals.find(p => p.id === proposalId);
    
    if (!proposal) {
        showToast('Proposal not found', 'error');
        return;
    }
    
    if (confirm(`Accept proposal from ${proposal.fromUser}?`)) {
        // Add loading state
        const row = document.querySelector(`tr[data-proposal-id="${proposalId}"]`);
        if (row) {
            row.style.opacity = '0.7';
            row.style.pointerEvents = 'none';
        }
        
        // Simulate API call
        setTimeout(() => {
            // Update proposal status
            const proposalIndex = receivedProposals.findIndex(p => p.id === proposalId);
            if (proposalIndex !== -1) {
                receivedProposals[proposalIndex].status = 'accepted';
            }
            
            // Create new exchange
            const newExchange = {
                id: `EX${Date.now()}`,
                withUser: proposal.fromUser,
                offeredSkill: 'My Skill', // In real app, would get from request mapping
                requestedSkill: 'Their Skill',
                status: 'ongoing'
            };
            
            activeExchanges.unshift(newExchange);
            
            // Save to localStorage
            saveExchangeData();
            
            // Re-render both tables
            renderProposals();
            renderExchanges();
            
            showToast(`Proposal from ${proposal.fromUser} accepted! Exchange moved to active.`, 'success');
            
            // Highlight new exchange
            highlightExchange(newExchange.id);
            
        }, 500);
    }
}

function rejectProposal(proposalId) {
    const proposal = receivedProposals.find(p => p.id === proposalId);
    
    if (!proposal) {
        showToast('Proposal not found', 'error');
        return;
    }
    
    if (confirm(`Reject proposal from ${proposal.fromUser}?`)) {
        // Add loading state
        const row = document.querySelector(`tr[data-proposal-id="${proposalId}"]`);
        if (row) {
            row.style.opacity = '0.7';
            row.style.pointerEvents = 'none';
        }
        
        // Simulate API call
        setTimeout(() => {
            // Update proposal status
            const proposalIndex = receivedProposals.findIndex(p => p.id === proposalId);
            if (proposalIndex !== -1) {
                receivedProposals[proposalIndex].status = 'rejected';
            }
            
            // Save to localStorage
            saveExchangeData();
            
            // Re-render proposals
            renderProposals();
            
            showToast(`Proposal from ${proposal.fromUser} rejected.`, 'info');
            
        }, 500);
    }
}

function markCompleted(exchangeId) {
    const exchange = activeExchanges.find(ex => ex.id === exchangeId);
    
    if (!exchange) {
        showToast('Exchange not found', 'error');
        return;
    }
    
    if (confirm(`Mark exchange with ${exchange.withUser} as completed?`)) {
        // Add loading state
        const row = document.querySelector(`tr[data-exchange-id="${exchangeId}"]`);
        if (row) {
            row.style.opacity = '0.7';
            row.style.pointerEvents = 'none';
        }
        
        // Simulate API call
        setTimeout(() => {
            // Update exchange status
            const exchangeIndex = activeExchanges.findIndex(ex => ex.id === exchangeId);
            if (exchangeIndex !== -1) {
                activeExchanges[exchangeIndex].status = 'completed';
            }
            
            // Save to localStorage
            saveExchangeData();
            
            // Re-render exchanges
            renderExchanges();
            
            showToast(`Exchange with ${exchange.withUser} marked as completed!`, 'success');
            
            // Show celebration animation
            celebrateCompletion(exchangeId);
            
        }, 500);
    }
}

function saveExchangeData() {
    try {
        localStorage.setItem('receivedProposals', JSON.stringify(receivedProposals));
        localStorage.setItem('activeExchanges', JSON.stringify(activeExchanges));
    } catch (e) {
        console.error('Error saving exchange data:', e);
        showToast('Error saving data. Please try again.', 'error');
    }
}

function highlightExchange(exchangeId) {
    setTimeout(() => {
        const row = document.querySelector(`tr[data-exchange-id="${exchangeId}"]`);
        if (row) {
            row.classList.add('success');
            row.scrollIntoView({ behavior: 'smooth', block: 'center' });
            
            setTimeout(() => {
                row.classList.remove('success');
            }, 2000);
        }
    }, 100);
}

function celebrateCompletion(exchangeId) {
    const row = document.querySelector(`tr[data-exchange-id="${exchangeId}"]`);
    if (row) {
        // Add celebration class
        row.style.background = 'linear-gradient(45deg, #f0fdf4, #dcfce7)';
        row.style.transition = 'all 0.5s ease';
        
        // Create confetti effect (simple version)
        createConfetti(row);
        
        setTimeout(() => {
            row.style.background = '';
        }, 3000);
    }
}

function createConfetti(element) {
    const rect = element.getBoundingClientRect();
    const colors = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444'];
    
    for (let i = 0; i < 10; i++) {
        const confetti = document.createElement('div');
        confetti.style.cssText = `
            position: fixed;
            left: ${rect.left + Math.random() * rect.width}px;
            top: ${rect.top}px;
            width: 6px;
            height: 6px;
            background: ${colors[Math.floor(Math.random() * colors.length)]};
            border-radius: 50%;
            pointer-events: none;
            z-index: 1000;
            animation: confettiFall 1s ease-out forwards;
        `;
        
        document.body.appendChild(confetti);
        
        setTimeout(() => confetti.remove(), 1000);
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

// Statistics for dashboard (future enhancement)
function getExchangeStats() {
    return {
        totalProposals: receivedProposals.length,
        pendingProposals: receivedProposals.filter(p => p.status === 'pending').length,
        acceptedProposals: receivedProposals.filter(p => p.status === 'accepted').length,
        activeExchanges: activeExchanges.filter(ex => ex.status === 'ongoing').length,
        completedExchanges: activeExchanges.filter(ex => ex.status === 'completed').length
    };
}

// Add CSS for animations
const exchangeStyles = document.createElement('style');
exchangeStyles.textContent = `
    @keyframes confettiFall {
        from {
            transform: translateY(0) rotate(0deg);
            opacity: 1;
        }
        to {
            transform: translateY(100px) rotate(360deg);
            opacity: 0;
        }
    }
    
    .success {
        animation: successPulse 0.6s ease-in-out;
    }
    
    @keyframes successPulse {
        0%, 100% { transform: scale(1); }
        50% { transform: scale(1.02); }
    }
    
    .action-buttons .btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }
`;
document.head.appendChild(exchangeStyles);

// Auto-refresh data every 30 seconds (future enhancement)
setInterval(() => {
    // In a real app, this would fetch fresh data from the server
    console.log('Auto-refreshing exchange data...');
}, 30000);
