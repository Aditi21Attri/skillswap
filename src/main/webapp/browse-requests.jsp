<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.skill.SkillDAO" %>
<%!
    // Simple HTML escaper for embedding values into attribute contexts
    private String esc(Object o) {
        if (o == null) return "";
        String s = o.toString();
        return s.replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }

%>
<%
    // Handle 'onlyMatching' filter param and persist to session
    // Read checkbox values robustly: handle the hidden field + checkbox case by checking all submitted values
    String[] onlyMatchingValues = request.getParameterValues("onlyMatching");
    Boolean onlyMatching = null;
    if (onlyMatchingValues != null) {
        boolean om = false;
        for (String v : onlyMatchingValues) {
            if (v != null && (v.equals("1") || v.equalsIgnoreCase("true"))) {
                om = true;
                break;
            }
        }
        session.setAttribute("onlyMatchingRequestsFilter", Boolean.valueOf(om));
        onlyMatching = Boolean.valueOf(om);
        // Show a small confirmation message after the user toggles the filter
        if (om) {
            request.setAttribute("message", "Filter applied: showing only requests you can do.");
        } else {
            request.setAttribute("message", "Filter cleared: showing all requests.");
        }
    } else {
        Object omSess = session.getAttribute("onlyMatchingRequestsFilter");
        onlyMatching = (omSess instanceof Boolean) ? (Boolean) omSess : Boolean.FALSE;
    }

    // Check if user is logged in
    String userEmail = (String) session.getAttribute("userEmail");
    Integer userId = (Integer) session.getAttribute("userId");
    if (userEmail == null || userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    
    // Database credentials
    String JDBC_URL = "jdbc:mysql://localhost:3306/skillexchange?useSSL=false&serverTimezone=UTC";
    String JDBC_USER = "root";
    String JDBC_PASS = "aTTri21..";
    
    // If the user toggled the filter (we received parameters), persist the preference to DB for this user
    if (onlyMatchingValues != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection prefCon = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
                // Create preferences table if it doesn't exist (safe, idempotent)
                String createSql = "CREATE TABLE IF NOT EXISTS UserPreferences (UserID INT PRIMARY KEY, OnlyMatching TINYINT(1))";
                try (Statement st = prefCon.createStatement()) {
                    st.executeUpdate(createSql);
                }

                // Upsert preference for current user
                String upsert = "INSERT INTO UserPreferences (UserID, OnlyMatching) VALUES (?, ?) ON DUPLICATE KEY UPDATE OnlyMatching = VALUES(OnlyMatching)";
                try (PreparedStatement psUp = prefCon.prepareStatement(upsert)) {
                    psUp.setInt(1, userId);
                    psUp.setInt(2, (onlyMatching != null && onlyMatching) ? 1 : 0);
                    psUp.executeUpdate();
                }
            }
        } catch (Exception e) {
            // Don't break the page for preference storage failures; log for debugging
            e.printStackTrace();
        }
    }
    
    // List to hold queries/requests
    List<Map<String, Object>> queries = new ArrayList<>();
    
    // Fetch all open queries (excluding user's own queries)
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            StringBuilder sqlBuilder = new StringBuilder();
            sqlBuilder.append("SELECT q.QueryID, q.Title, q.Description, q.PostDate, q.Status, q.SkillID, ")
                      .append("u.UserID as RequesterID, u.Username as RequesterName, u.FullName as RequesterFullName, ")
                      .append("s.SkillName, CASE WHEN us.UserID IS NULL THEN 0 ELSE 1 END as hasSkill ")
                      .append("FROM Queries q ")
                      .append("JOIN Users u ON q.RequesterID = u.UserID ")
                      .append("JOIN Skills s ON q.SkillID = s.SkillID ")
                      .append("LEFT JOIN UserSkills us ON us.SkillID = q.SkillID AND us.UserID = ? ")
                      .append("WHERE q.RequesterID != ? AND UPPER(TRIM(q.Status)) = 'OPEN' ");
            if (onlyMatching != null && onlyMatching) {
                sqlBuilder.append(" AND us.UserID IS NOT NULL ");
            }
            sqlBuilder.append(" ORDER BY q.PostDate DESC");
            String sql = sqlBuilder.toString();
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId); // for LEFT JOIN user skills
                ps.setInt(2, userId); // exclude user's own queries
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> query = new HashMap<>();
                        query.put("queryId", rs.getInt("QueryID"));
                        query.put("title", rs.getString("Title"));
                        query.put("description", rs.getString("Description"));
                        query.put("postDate", rs.getString("PostDate"));
                        query.put("status", rs.getString("Status"));
                        query.put("requesterId", rs.getInt("RequesterID"));
                        query.put("requesterName", rs.getString("RequesterFullName") != null ? 
                                  rs.getString("RequesterFullName") : rs.getString("RequesterName"));
                        query.put("skillId", rs.getObject("SkillID"));
                        query.put("skillName", rs.getString("SkillName"));
                        query.put("hasSkill", rs.getInt("hasSkill"));
                        // Fetch poster's skills for this requester to populate poster-skills select
                        String posterIds = "";
                        String posterNames = "";
                        try (PreparedStatement psPoster = con.prepareStatement("SELECT s.SkillID, s.SkillName FROM UserSkills us JOIN Skills s ON us.SkillID = s.SkillID WHERE us.UserID = ?")) {
                            psPoster.setInt(1, rs.getInt("RequesterID"));
                            try (ResultSet rsPoster = psPoster.executeQuery()) {
                                StringBuilder pid = new StringBuilder();
                                StringBuilder pnm = new StringBuilder();
                                boolean first = true;
                                while (rsPoster.next()) {
                                    if (!first) {
                                        pid.append(",");
                                        pnm.append("||");
                                    }
                                    pid.append(rsPoster.getInt("SkillID"));
                                    pnm.append(rsPoster.getString("SkillName"));
                                    first = false;
                                }
                                posterIds = pid.toString();
                                posterNames = pnm.toString();
                            }
                        } catch (Exception pe) {
                            // ignore poster skill fetch errors
                            pe.printStackTrace();
                        }
                        query.put("posterSkillIds", posterIds);
                        query.put("posterSkillNames", posterNames);
                        queries.add(query);
                    }
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    // Fetch logged-in user's skills to populate offered-skill dropdown
    String mySkillsOptions = "";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(JDBC_URL, JDBC_USER, JDBC_PASS)) {
            String msSql = "SELECT s.SkillID, s.SkillName FROM UserSkills us JOIN Skills s ON us.SkillID = s.SkillID WHERE us.UserID = ?";
            try (PreparedStatement ps = con.prepareStatement(msSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    StringBuilder sb = new StringBuilder();
                    while (rs.next()) {
                        sb.append("<option value=\"").append(rs.getInt("SkillID")).append("\">")
                          .append(esc(rs.getString("SkillName"))).append("</option>");
                    }
                    mySkillsOptions = sb.toString();
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Browse Requests - Skill Exchange Platform</title>
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/dashboard.css">
    <link rel="stylesheet" href="css/browse.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="dashboard-container">
        <!-- Header -->
        <header class="dashboard-header">
            <div class="header-content">
                <h1 class="platform-title">XpertiseXchange</h1>
                <p class="header-subtitle">Browse Requests</p>
                <button class="btn btn-outline btn-sm logout-btn" onclick="logout()">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </button>
            </div>
        </header>

        <!-- Navigation Tabs -->
        <nav class="tab-navigation">
            <div class="tab-list">
                <a href="dashboard.jsp" class="tab-trigger" data-tab="dashboard">
                    <i class="fas fa-home"></i>
                    Dashboard
                </a>
                <a href="myProfile.jsp" class="tab-trigger" data-tab="profile">
                    <i class="fas fa-user"></i>
                    Profile
                </a>
                <a href="my-skills.jsp" class="tab-trigger" data-tab="my-skills">
                    <i class="fas fa-book-open"></i>
                    My Skills
                </a>
                <a href="browse-requests.jsp" class="tab-trigger active" data-tab="browse-requests">
                    <i class="fas fa-search"></i>
                    Browse Requests
                </a>
                <a href="exchanges.jsp" class="tab-trigger" data-tab="exchanges">
                    <i class="fas fa-exchange-alt"></i>
                    Exchanges
                </a>
                <a href="messages.jsp" class="tab-trigger" data-tab="messages">
                    <i class="fas fa-comments"></i>
                    Messages
                </a>
            </div>
        </nav>

        <!-- Main Content -->
        <main class="dashboard-main">
            <div class="browse-container">
                <div class="browse-card">
                    <div class="browse-header">
                        <h2>Browse Skill Exchange Requests</h2>
                        <p class="browse-description">Find and respond to skill exchange requests from other users</p>
                    </div>
                    <div class="browse-content">
                        <% 
                            String message = (String) request.getAttribute("message");
                            String error = (String) request.getAttribute("error");
                            if (message != null) {
                        %>
                            <div class="alert alert-success" style="margin-bottom: 1rem; padding: 1rem; background: #d4edda; border: 1px solid #c3e6cb; border-radius: 8px; color: #155724;">
                                <%= message %>
                            </div>
                        <% } 
                            if (error != null) {
                        %>
                            <div class="alert alert-error" style="margin-bottom: 1rem; padding: 1rem; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 8px; color: #721c24;">
                                <%= error %>
                            </div>
                        <% } %>
                        
                        

                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
                            <div>
                                <form id="filterForm" method="get" action="browse-requests.jsp" style="display:inline; margin:0; padding:0;">
                                    <!-- hidden field ensures a value is submitted even when checkbox is unchecked -->
                                    <input type="hidden" name="onlyMatching" value="0">
                                    <label style="font-size:14px; color:#333; margin:0;"><input type="checkbox" id="onlyMatching" name="onlyMatching" value="1" style="margin-right:8px;" <%= (onlyMatching != null && onlyMatching) ? "checked" : "" %> onchange="document.getElementById('filterForm').submit()"> Show only requests I can do</label>
                                </form>
                            </div>
                            <div style="font-size:13px; color:#666;">Tip: Click <strong>Send Proposal</strong> to apply.</div>
                        </div>

                        <div class="requests-table">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Request ID</th>
                                        <th>Title</th>
                                        <th>Posted By</th>
                                        <th>Skill Needed</th>
                                        <th>Description</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody id="requestsTableBody">
                                    <% if (queries.isEmpty()) { %>
                                        <tr>
                                            <td colspan="6" style="text-align: center; padding: 2rem; color: #666;">
                                                <i class="fas fa-search" style="font-size: 2rem; margin-bottom: 1rem; opacity: 0.3; display: block;"></i>
                                                No open requests available at the moment.
                                            </td>
                                        </tr>
                                    <% } else {
                                        for (Map<String, Object> query : queries) {
                                    %>
                                        <tr data-hasmatch="<%= esc(query.get("hasSkill")) %>">
                                            <td class="request-id">REQ<%= String.format("%03d", ((Number)query.get("queryId")).intValue()) %></td>
                                            <td><strong><%= esc(query.get("title")) %></strong></td>
                                            <td>
                                                <a href="profile?id=<%= esc(query.get("requesterId")) %>"><%= esc(query.get("requesterName")) %></a>
                                            </td>
                                            <td>
                                                <% if (query.get("hasSkill") != null && ((Integer)query.get("hasSkill")) == 1) { %>
                                                    <span class="skill-match-badge" style="background:#e6ffed;color:#0b6623;padding:4px 8px;border-radius:12px;margin-right:8px;font-weight:600;">You match</span>
                                                <% } %>
                                                <span class="skill-badge"><%= esc(query.get("skillName")) %></span>
                                            </td>
                                            <td><%= esc(query.get("description") != null ? query.get("description") : "No description provided") %></td>
                                            <td>
                                                <!-- Single, safe button that stores values in data- attributes to avoid JS quoting issues -->
                        <button class="btn btn-primary btn-sm" 
                            type="button"
                            data-query-id="<%= esc(query.get("queryId")) %>"
                            data-requester="<%= esc(query.get("requesterName")) %>"
                            data-title="<%= esc(query.get("title")) %>"
                            data-skill="<%= esc(query.get("skillName")) %>"
                            data-skill-id="<%= esc(query.get("skillId")) %>"
                            onclick="openProposalModalFromButton(this)">
                                                    Send Proposal
                                                </button>
                                                <!-- Hidden poster skills select for this row -->
                                                <select class="poster-skills" data-query-id="<%= esc(query.get("queryId")) %>" style="display:none;">
                                                <% String pIds = (String) query.get("posterSkillIds");
                                                   String pNames = (String) query.get("posterSkillNames");
                                                   if (pIds != null && !pIds.isEmpty()) {
                                                       String[] ids = pIds.split(",");
                                                       String[] names = pNames != null ? pNames.split("\\|\\|") : new String[ids.length];
                                                       for (int i=0;i<ids.length;i++) {
                                                           String id = ids[i];
                                                           String nm = (names.length>i && names[i]!=null) ? names[i] : "";
                                                %>
                                                    <option value="<%= id %>"><%= esc(nm) %></option>
                                                <%     }
                                                   }
                                                %>
                                                </select>
                                            </td>
                                        </tr>
                                    <% 
                                        }
                                    } 
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- Proposal Modal -->
    <div id="proposalModal" class="modal" style="display: none;">
        <div class="modal-content">
            <div class="modal-header">
                <h3>Send Proposal</h3>
                <p class="modal-description">Send a proposal for this skill exchange request</p>
                <button class="modal-close" onclick="closeProposalModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="modal-body">
                <div class="request-details" id="requestDetails" style="background: #f8f9fa; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                    <!-- Request details will be populated dynamically -->
                </div>
                <form action="SubmitBid" method="post" id="proposalForm" class="modal-form">
                    <input type="hidden" id="queryId" name="queryId" value="">
                    <input type="hidden" id="wantedSkillHidden" name="wantedSkillId" value="">
                    <div class="form-group">
                        <label for="modalRequestedSkill">Requested Skill</label>
                        <select id="modalRequestedSkill" name="requestedSkillId" required>
                            <option value="">-- skill --</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="modalWantSkill">Skill You Want From Requester (optional)</label>
                        <select id="modalWantSkill">
                            <option value="">-- choose skill you want from requester (or volunteer) --</option>
                        </select>
                    </div>
                    <!-- Removed offered-skill select: UI records what you want from requester and you can volunteer -->
                    <div class="form-group" style="display:flex; align-items:center; gap:8px;">
                        <input type="checkbox" id="modalVolunteer" name="isVolunteer" value="1" onchange="onModalVolunteerToggle(this)">
                        <label for="modalVolunteer">I want to volunteer (no skill requested in exchange)</label>
                    </div>
                    <div class="form-group">
                        <label for="bidDetails">Your Proposal Details</label>
                        <textarea id="bidDetails" name="bidDetails" rows="4" placeholder="Describe your proposal and how you can help..." required></textarea>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline" onclick="closeProposalModal()">Cancel</button>
                        <button type="submit" class="btn btn-primary">Send Proposal</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="js/dashboard.js"></script>
    <script>
        function logout() {
            if (confirm('Are you sure you want to logout?')) {
                window.location.href = 'logout.jsp';
            }
        }

        function openProposalModalFromButton(btn) {
            // Read values from data- attributes (safer than embedding raw strings in onclick)
            const queryId = btn.getAttribute('data-query-id') || '';
            const requester = btn.getAttribute('data-requester') || '';
            const title = btn.getAttribute('data-title') || '';
            const skill = btn.getAttribute('data-skill') || '';
            const skillId = btn.getAttribute('data-skill-id') || '';

            // Debug output to the console so you can inspect values in DevTools
            try { console.log('openProposalModalFromButton', { queryId, requester, title, skill }); } catch(e){}

            openProposalModal(queryId, requester, title, skill, skillId);
        }

        function openProposalModal(queryId, requesterName, title, skill, skillId) {
            // Defensive fallbacks
            const q = queryId || '';
            const r = requesterName || 'Unknown';
            const t = title || 'Untitled';
            const s = skill || 'Unknown';

            // Log for debugging
            try { console.log('openProposalModal called', { queryId: q, requesterName: r, title: t, skill: s }); } catch(e){}

            const modal = document.getElementById('proposalModal');
            if (!modal) return;
            modal.style.display = 'flex';
            const qInput = document.getElementById('queryId');
            if (qInput) qInput.value = q;

            // set requested skill id into the hidden/selection control
            const reqSel = document.getElementById('modalRequestedSkill');
            if (reqSel) {
                reqSel.innerHTML = '';
                const opt = document.createElement('option');
                opt.value = skillId || '';
                opt.textContent = s;
                reqSel.appendChild(opt);
                // ensure it's selected
                reqSel.value = skillId || '';
            }

            const details = document.getElementById('requestDetails');
            if (details) {
                // Build text nodes to avoid accidental HTML parsing issues
                details.innerHTML = '';
                const p1 = document.createElement('p');
                p1.innerHTML = '<strong>Request:</strong> ' + escapeHtml(t);
                const p2 = document.createElement('p');
                p2.innerHTML = '<strong>Posted by:</strong> ' + escapeHtml(r);
                const p3 = document.createElement('p');
                p3.innerHTML = '<strong>Skill Needed:</strong> ' + escapeHtml(s);
                details.appendChild(p1);
                details.appendChild(p2);
                details.appendChild(p3);
            }

            // populate poster-skill-dependent selects
                try {
                // poster skills -> modalWantSkill (what you want from requester)
                const wantSel = document.getElementById('modalWantSkill');
                if (wantSel) {
                    wantSel.innerHTML = '<option value="">-- choose skill you want from requester (or volunteer) --</option>';
                    const posterSelect = document.querySelector('.poster-skills[data-query-id="' + q + '"]');
                    if (posterSelect) {
                        Array.from(posterSelect.options).forEach(opt => {
                            const o = document.createElement('option');
                            o.value = opt.value;
                            o.textContent = opt.textContent;
                            wantSel.appendChild(o);
                        });
                        if (wantSel.options.length > 1) wantSel.selectedIndex = 1;
                    }
                        // volunteer handling: if checked, disable/clear the wantSel
                    const volCb = document.getElementById('modalVolunteer');
                    if (volCb && volCb.checked) {
                        wantSel.disabled = true;
                        wantSel.value = '';
                    } else {
                        wantSel.disabled = false;
                    }
                    // mirror into hidden input so value is submitted even if select is disabled
                    const hidden = document.getElementById('wantedSkillHidden');
                    if (hidden) hidden.value = wantSel.value || '';
                    // keep hidden updated when user changes selection
                    wantSel.addEventListener('change', function(){ if (hidden) hidden.value = wantSel.value || ''; });
                }

                // no offered-skill select in the modal (we only record what you want from requester)
            } catch (e) { console.log('populate modal skills failed', e); }
        }

        // Small client-side escaper for safe insertion into innerHTML
        function escapeHtml(unsafe) {
            if (!unsafe && unsafe !== 0) return '';
            return String(unsafe)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        function closeProposalModal() {
            document.getElementById('proposalModal').style.display = 'none';
            document.getElementById('proposalForm').reset();
            const reqSel = document.getElementById('modalRequestedSkill'); if (reqSel) reqSel.innerHTML = '<option value="">-- skill --</option>';
            // clear hidden mirror so stale values are not submitted
            const hidden = document.getElementById('wantedSkillHidden'); if (hidden) hidden.value = '';
        }

        function onModalVolunteerToggle(cb) {
            // When volunteering, you are not requesting a skill in exchange from the requester,
            // so disable/clear the 'want' select which lists poster skills. Keep your offered-skill enabled.
            const wantSel = document.getElementById('modalWantSkill');
            if (wantSel) {
                if (cb.checked) {
                    wantSel.disabled = true;
                    wantSel.value = '';
                    // mirror the cleared value into the hidden input as well
                    const hidden = document.getElementById('wantedSkillHidden'); if (hidden) hidden.value = '';
                } else {
                    wantSel.disabled = false;
                }
            }
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('proposalModal');
            if (event.target == modal) {
                closeProposalModal();
            }
        }

        // Filter rows to show only matching requests when checkbox is toggled
        (function(){
            const checkbox = document.getElementById('onlyMatching');
            if (!checkbox) return;

            function applyFilter() {
                const showOnly = checkbox.checked;
                const rows = document.querySelectorAll('#requestsTableBody tr');
                rows.forEach(r => {
                    const hasMatch = r.getAttribute('data-hasmatch') === '1';
                    r.style.display = (showOnly && !hasMatch) ? 'none' : '';
                });
            }

            // No client-side persistence: filter state is stored server-side in session.
            // The checkbox submits the page (GET) and the server sets the session preference.
            checkbox.addEventListener('change', function(e){
                // The checkbox is inside a form that submits on change, so no extra client logic needed.
            });

            // initial
            applyFilter();

            // Ensure checkbox reliably submits the filter form when toggled (some browsers/HTML setups may ignore onchange)
            try {
                const frm = document.getElementById('filterForm');
                if (frm && checkbox) {
                    checkbox.addEventListener('click', function(e){
                        // small delay to let checkbox state update before submitting
                        setTimeout(() => {
                            try { frm.submit(); } catch (ex) { console.log('Filter submit failed', ex); }
                        }, 10);
                    });
                }
            } catch (e) { console.log('attach submit handler failed', e); }
        })();
    </script>
</body>
</html>
