<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
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
    Object uidObj = session.getAttribute("userId");
    if (uidObj == null) { response.sendRedirect("index.jsp"); return; }
    int userId = Integer.parseInt(uidObj.toString());
    String tid = request.getParameter("transactionId");
    if (tid == null) { response.sendRedirect("exchanges.jsp"); return; }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Leave a Review</title>
    <link rel="stylesheet" href="css/styles.css">
    <style>
        .review-card { max-width:640px;margin:48px auto;background:#fff;padding:20px;border-radius:10px;border:1px solid #e6e6e6; }
        .rating { display:flex;gap:8px;margin-bottom:12px; }
        textarea { width:100%; min-height:120px; padding:10px; border-radius:6px; border:1px solid #d1d5db; }
        .btn { padding:8px 12px; border-radius:6px; }
        .btn-primary { background:#2563eb;color:#fff;border:none; }
        .btn-muted { background:#f3f4f6;border:1px solid #e5e7eb; }
    </style>
</head>
<body>
    <div class="review-card">
        <h2>Leave a review for this exchange</h2>
        <p>You can rate your experience and leave optional comments. If you choose to skip, you can submit later from your exchanges or profile.</p>
        <form method="post" action="CompleteTransaction">
            <input type="hidden" name="transactionId" value="<%= esc(tid) %>">
            <div class="rating">
                <label>Rating:
                    <select name="rating">
                        <option value="">(no rating)</option>
                        <option value="5">5 - Excellent</option>
                        <option value="4">4 - Good</option>
                        <option value="3">3 - OK</option>
                        <option value="2">2 - Poor</option>
                        <option value="1">1 - Bad</option>
                    </select>
                </label>
            </div>
            <div>
                <label>Comments (optional)</label>
                <textarea name="comments" placeholder="Describe your experience..."></textarea>
            </div>
            <div style="margin-top:12px;display:flex;gap:8px;">
                <button type="submit" name="reviewSubmitted" value="1" class="btn btn-primary">Submit Review and Complete</button>
                <button type="submit" name="skipReview" value="1" class="btn btn-muted">Skip & Complete</button>
                <a href="exchanges.jsp" class="btn btn-muted">Cancel</a>
            </div>
        </form>
    </div>
</body>
</html>
