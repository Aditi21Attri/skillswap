// Messages Page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    loadMessages();
    
    const messageForm = document.getElementById('messageForm');
    if (messageForm) {
        messageForm.addEventListener('submit', handleSendMessage);
    }
    
    const messageInput = document.getElementById('messageInput');
    if (messageInput) {
        messageInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                handleSendMessage(e);
            }
        });
    }
    
    // Scroll to bottom on load
    scrollToBottom();
});

let messages = [
    {
        id: '1',
        sender: 'Alice',
        content: 'Hi! Ready for our first React lesson?',
        timestamp: '2024-01-15T10:30:00Z',
        type: 'received'
    },
    {
        id: '2',
        sender: 'Me',
        content: 'Absolutely! I have Python materials ready too.',
        timestamp: '2024-01-15T10:35:00Z',
        type: 'sent'
    },
    {
        id: '3',
        sender: 'Alice',
        content: 'Perfect! Let\'s start with React hooks. Do you have any specific questions?',
        timestamp: '2024-01-15T10:40:00Z',
        type: 'received'
    }
];

let currentChat = {
    id: 'chat-alice',
    withUser: 'Alice Smith',
    lastActive: '2024-01-15T10:40:00Z'
};

function loadMessages() {
    // Load from localStorage
    try {
        const savedMessages = localStorage.getItem(`messages_${currentChat.id}`);
        if (savedMessages) {
            messages = JSON.parse(savedMessages);
        }
    } catch (e) {
        console.error('Error loading messages:', e);
    }
    
    renderMessages();
}

function renderMessages() {
    const chatHistory = document.getElementById('chatHistory');
    
    if (!chatHistory) return;
    
    if (messages.length === 0) {
        chatHistory.innerHTML = `
            <div class="messages-empty">
                <i class="fas fa-comments"></i>
                <h3>No Messages Yet</h3>
                <p>Start a conversation by sending a message below.</p>
            </div>
        `;
        return;
    }
    
    chatHistory.innerHTML = messages.map(message => `
        <div class="message message-${message.type}" data-message-id="${message.id}">
            <div class="message-content">
                <p class="message-text">${escapeHtml(message.content)}</p>
                <p class="message-meta">${message.sender} • ${formatTime(message.timestamp)}</p>
            </div>
        </div>
    `).join('');
    
    // Scroll to bottom after rendering
    setTimeout(scrollToBottom, 100);
}

function handleSendMessage(e) {
    e.preventDefault();
    
    const messageInput = document.getElementById('messageInput');
    const content = messageInput.value.trim();
    
    if (!content) {
        messageInput.focus();
        return;
    }
    
    if (content.length > 1000) {
        showToast('Message is too long. Please keep it under 1000 characters.', 'warning');
        return;
    }
    
    // Create new message
    const newMessage = {
        id: generateId(),
        sender: 'Me',
        content: content,
        timestamp: new Date().toISOString(),
        type: 'sent'
    };
    
    // Add to messages array
    messages.push(newMessage);
    
    // Clear input
    messageInput.value = '';
    
    // Show message immediately
    addMessageToDOM(newMessage);
    
    // Simulate sending (in real app, this would be an API call)
    simulateSendMessage(newMessage);
    
    // Save to localStorage
    saveMessages();
}

function addMessageToDOM(message) {
    const chatHistory = document.getElementById('chatHistory');
    
    // Remove empty state if exists
    const emptyState = chatHistory.querySelector('.messages-empty');
    if (emptyState) {
        emptyState.remove();
    }
    
    // Create message element
    const messageDiv = document.createElement('div');
    messageDiv.className = `message message-${message.type}`;
    messageDiv.setAttribute('data-message-id', message.id);
    
    messageDiv.innerHTML = `
        <div class="message-content">
            <p class="message-text">${escapeHtml(message.content)}</p>
            <p class="message-meta">${message.sender} • ${formatTime(message.timestamp)}</p>
        </div>
    `;
    
    // Add sending state for sent messages
    if (message.type === 'sent') {
        messageDiv.classList.add('sending');
    }
    
    chatHistory.appendChild(messageDiv);
    scrollToBottom();
}

function simulateSendMessage(message) {
    const messageElement = document.querySelector(`[data-message-id="${message.id}"]`);
    
    setTimeout(() => {
        // Remove sending state
        if (messageElement) {
            messageElement.classList.remove('sending');
        }
        
        // Show delivery confirmation
        showToast('Message sent', 'success', 2000);
        
        // Simulate receiving a response (for demo purposes)
        if (Math.random() > 0.5) {
            setTimeout(() => {
                simulateReceivedMessage();
            }, 2000 + Math.random() * 3000);
        }
        
    }, 500 + Math.random() * 1000);
}

function simulateReceivedMessage() {
    const responses = [
        'Thanks for the message!',
        'That sounds great! When should we schedule our next session?',
        'I agree. Let me know what works best for you.',
        'Perfect! I\'ll prepare some materials for our exchange.',
        'Looking forward to learning from you!',
        'That\'s a great point. I hadn\'t considered that before.'
    ];
    
    const response = responses[Math.floor(Math.random() * responses.length)];
    
    const receivedMessage = {
        id: generateId(),
        sender: currentChat.withUser,
        content: response,
        timestamp: new Date().toISOString(),
        type: 'received'
    };
    
    // Add to messages
    messages.push(receivedMessage);
    
    // Show typing indicator first
    showTypingIndicator();
    
    setTimeout(() => {
        hideTypingIndicator();
        addMessageToDOM(receivedMessage);
        saveMessages();
        
        // Show notification if page is not visible
        if (document.hidden) {
            showNotification('New message', `${currentChat.withUser}: ${response}`);
        }
    }, 1500 + Math.random() * 2000);
}

function showTypingIndicator() {
    const chatHistory = document.getElementById('chatHistory');
    
    const typingDiv = document.createElement('div');
    typingDiv.className = 'typing-indicator';
    typingDiv.id = 'typingIndicator';
    
    typingDiv.innerHTML = `
        <span>${currentChat.withUser} is typing</span>
        <div class="typing-dots">
            <div class="typing-dot"></div>
            <div class="typing-dot"></div>
            <div class="typing-dot"></div>
        </div>
    `;
    
    chatHistory.appendChild(typingDiv);
    scrollToBottom();
}

function hideTypingIndicator() {
    const typingIndicator = document.getElementById('typingIndicator');
    if (typingIndicator) {
        typingIndicator.remove();
    }
}

function scrollToBottom() {
    const chatHistory = document.getElementById('chatHistory');
    if (chatHistory) {
        chatHistory.scrollTop = chatHistory.scrollHeight;
    }
}

function saveMessages() {
    try {
        localStorage.setItem(`messages_${currentChat.id}`, JSON.stringify(messages));
    } catch (e) {
        console.error('Error saving messages:', e);
        showToast('Error saving messages', 'error');
    }
}

function formatTime(timestamp) {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    
    if (days === 0) {
        return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
    } else if (days === 1) {
        return 'Yesterday';
    } else if (days < 7) {
        return date.toLocaleDateString('en-US', { weekday: 'short' });
    } else {
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric'
        });
    }
}

function showNotification(title, body) {
    if ('Notification' in window && Notification.permission === 'granted') {
        new Notification(title, {
            body: body,
            icon: '/favicon.ico',
            tag: 'skill-exchange-message'
        });
    } else if ('Notification' in window && Notification.permission !== 'denied') {
        Notification.requestPermission().then(permission => {
            if (permission === 'granted') {
                showNotification(title, body);
            }
        });
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

// Message input enhancements
document.addEventListener('DOMContentLoaded', function() {
    const messageInput = document.getElementById('messageInput');
    
    if (messageInput) {
        // Auto-resize and character counter
        messageInput.addEventListener('input', function() {
            const length = this.value.length;
            
            // Add character counter near max
            if (length > 800) {
                let counter = document.querySelector('.message-char-counter');
                if (!counter) {
                    counter = document.createElement('div');
                    counter.className = 'message-char-counter';
                    counter.style.cssText = `
                        position: absolute;
                        right: 60px;
                        bottom: 12px;
                        font-size: 0.75rem;
                        color: #64748b;
                        pointer-events: none;
                    `;
                    this.parentElement.style.position = 'relative';
                    this.parentElement.appendChild(counter);
                }
                
                counter.textContent = `${1000 - length} left`;
                counter.style.color = length > 950 ? '#dc2626' : '#64748b';
            } else {
                const counter = document.querySelector('.message-char-counter');
                if (counter) counter.remove();
            }
            
            // Visual feedback for long messages
            if (length > 1000) {
                this.style.borderColor = '#dc2626';
            } else {
                this.style.borderColor = '';
            }
        });
        
        // Placeholder cycling (for fun)
        const placeholders = [
            'Type your message...',
            'Share your thoughts...',
            'Ask a question...',
            'Say something nice...'
        ];
        
        let placeholderIndex = 0;
        setInterval(() => {
            if (messageInput.value === '' && document.activeElement !== messageInput) {
                messageInput.placeholder = placeholders[placeholderIndex];
                placeholderIndex = (placeholderIndex + 1) % placeholders.length;
            }
        }, 5000);
    }
});

// Keyboard shortcuts
document.addEventListener('keydown', function(e) {
    // Ctrl/Cmd + Enter to send message
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
        const messageInput = document.getElementById('messageInput');
        if (messageInput && document.activeElement === messageInput) {
            handleSendMessage(e);
        }
    }
    
    // Escape to clear input
    if (e.key === 'Escape') {
        const messageInput = document.getElementById('messageInput');
        if (messageInput && document.activeElement === messageInput && messageInput.value) {
            messageInput.value = '';
            messageInput.blur();
        }
    }
});

// Auto-save draft
let draftTimeout;
document.addEventListener('DOMContentLoaded', function() {
    const messageInput = document.getElementById('messageInput');
    
    if (messageInput) {
        // Load draft
        const draft = localStorage.getItem(`draft_${currentChat.id}`);
        if (draft) {
            messageInput.value = draft;
        }
        
        // Save draft as user types
        messageInput.addEventListener('input', function() {
            clearTimeout(draftTimeout);
            draftTimeout = setTimeout(() => {
                if (this.value.trim()) {
                    localStorage.setItem(`draft_${currentChat.id}`, this.value);
                } else {
                    localStorage.removeItem(`draft_${currentChat.id}`);
                }
            }, 500);
        });
        
        // Clear draft when message is sent
        const originalSendMessage = handleSendMessage;
        handleSendMessage = function(e) {
            originalSendMessage(e);
            localStorage.removeItem(`draft_${currentChat.id}`);
        };
    }
});
