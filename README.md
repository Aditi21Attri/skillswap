# SkillSwap (Skill Exchange Platform)

 A small Java Servlet + JSP web application for exchanging skills between users. Users can post requests for help, browse requests, propose trades, accept/reject bids, and manage their skills and profile.

---

## Table of contents

- Project overview
- Features
- Architecture & file map
- Servlets and endpoints
- JSP pages and client assets
- Database schema (tables & important columns)
- Security notes
- Local setup & prerequisites
- Build and run
- Common troubleshooting
- Testing

---

## Project overview

SkillSwap is a lightweight skill-exchange platform built with Java Servlets, JSP, and MySQL. The app supports user registration and login, posting and browsing skill requests, submitting proposals (bids) from providers who possess matching skills, and managing user profiles and skills.

This repository contains server-side servlet controllers, JSP views, static assets (CSS/JS), and SQL-related code via JDBC.

## Features

- User registration and authentication (email-based login)
- Passwords stored using PBKDF2 hashing (secure password storage)
- Post skill requests (title, description, required skill)
- Browse requests with an indicator for requests the current user can fulfill (matching skill)
- Submit proposals/bids to fulfill requests (server-side enforcement that provider has the skill)
- Accept / reject bids and complete transactions
- Manage personal skills and profile
- Persist user preference: "Show only requests I can do"

## Architecture & file map (high-level)

Key folders:

- `src/main/java/com/skill/` — Java servlets and utility classes
- `src/main/webapp/` — JSP views and static assets
- `src/main/webapp/css/`, `js/` — front-end styles and scripts
- `build/classes/` — compiled classes (build artifact)

Core Java classes (present in the repo):

- `AcceptBid.java` — Accept a provider's bid on a request.
- `RejectBid.java` — Reject a provider's bid.
- `SubmitBid.java` — Submit a bid to a request (includes check that provider has required skill).
- `PostRequest.java` — Create a new skill request.
- `MyLogin.java` — Authenticate user and create session.
- `Register.java` — Create a new user account (hashes password before save).
- `UpdateProfile.java` — Update user profile information and skills.
- `AddSkill.java`, `DeleteSkill.java` — Manage the user's skills list.
- `CompleteTransaction.java` — Mark a request/transaction as completed.
- `PasswordUtils.java` — PBKDF2 password hashing & verification helper.

Important JSPs (views):

- `index.jsp` — Login page / landing page.
- `register.jsp` — User registration page.
- `browse-requests.jsp` — Browse posted requests, open a propose modal.
- `post-request.jsp` — Form to post a new request.
- `dashboard.jsp` — User dashboard showing activity, accepted bids, etc.
- `exchanges.jsp` — Active exchanges and transaction history.
- `my-skills.jsp` — Manage your skill list.
- `profile.jsp` — View and edit profile.

Static assets:

- `src/main/webapp/css/` — styles including `auth.css`, `styles.css`, and page-specific CSS files.
- `src/main/webapp/js/` — front-end JavaScript for modals, filtering, and client interactions.

## Servlets and endpoints

The application routes requests from forms and AJAX to servlets in `com.skill` (mapped via `web.xml`). Major endpoints include:

- `Register` (POST)
  - Registers a new user. Expects `username`, `email`, `password`, and profile fields. Hashes password via `PasswordUtils` and stores `PasswordHash`.
- `MyLogin` (POST)
  - Authenticates a user by email + password. Loads `PasswordHash` and verifies with `PasswordUtils.verifyPassword`. On success sets session attributes (UserID, Email, Username, etc.).
- `PostRequest` (POST)
  - Creates a new query/request (title, description, skill id/name, requester id).
- `SubmitBid` (POST)
  - Provider proposes to fulfill a query. Server checks that the provider has the required skill and prevents duplicates.
- `AcceptBid`, `RejectBid` (POST)
  - Request owner can accept or reject bids; acceptance may trigger completing the exchange flow.
- `AddSkill`, `DeleteSkill` (POST)
  - Manage user skill list.
- `UpdateProfile` (POST)
  - Update user personal details.

Note: Check `WEB-INF/web.xml` for exact URL mappings in your deployed environment.

## Database schema (overview)

The app uses MySQL via JDBC. The default JDBC URL referenced in the code is:

```
jdbc:mysql://localhost:3306/skillexchange
```

Known / expected tables and important columns (please adapt as necessary in your DB):

- `Users`
  - `UserID` (INT PRIMARY KEY AUTO_INCREMENT)
  - `Username` (VARCHAR)
  - `Email` (VARCHAR, UNIQUE)
  - `PasswordHash` (VARCHAR) — stores PBKDF2 hashed password as iterations:salt:hash base64
  - `FullName`, `Bio`, other profile fields

- `Queries` (or `Requests`)
  - `QueryID` (INT PK)
  - `Title`, `Description`
  - `RequesterID` (FK -> Users.UserID)
  - `SkillID` or `SkillName` (the required skill)
  - `Status` (e.g., OPEN, ASSIGNED, COMPLETED)

- `Bids`
  - `BidID`, `QueryID`, `ProviderID`, `Message`, `Status` (PENDING/ACCEPTED/REJECTED)

- `UserSkills`
  - mapping table: `UserID`, `SkillID` (or SkillName)

- `UserPreferences` (added by the app if missing)
  - `UserID` INT PRIMARY KEY
  - `OnlyMatching` TINYINT(1) — whether user prefers to see only requests they can do

Example SQL (create the preferences table):

```sql
CREATE TABLE IF NOT EXISTS UserPreferences (
  UserID INT PRIMARY KEY,
  OnlyMatching TINYINT(1) DEFAULT 0,
  FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
```

Be sure your `Users` table has a `PasswordHash` column for the PBKDF2 hashes.

## Security notes

- Passwords are hashed with PBKDF2 (SHA-256) using `PasswordUtils.java`.
- All DB queries should use prepared statements to avoid SQL injection (the project uses prepared statements in servlets).
- Server-side checks are enforced where important (for example `SubmitBid` checks the provider has the required skill before accepting a bid).
- Do not deploy the repository to production with default DB credentials or with the embedded `root` user — create an application-dedicated DB user and use secure passwords and connection settings.

## Local setup & prerequisites

- Java JDK 11+ installed and available on PATH.
- Apache Tomcat (9/10/11) or another servlet container.
- MySQL server with a database created (default: `skillexchange`).

Create the database and user (example):

```powershell
# Run in PowerShell on Windows (adjust credentials as required)
mysql -u root -p
CREATE DATABASE skillexchange;
CREATE USER 'skillapp'@'localhost' IDENTIFIED BY 'strongpassword';
GRANT ALL PRIVILEGES ON skillexchange.* TO 'skillapp'@'localhost';
FLUSH PRIVILEGES;
```

Update JDBC credentials in your servlets if they are hard-coded (search for `jdbc:mysql://` in the Java sources) or configure them via environment / web.xml context params.

## Build and run

This project does not include a build tool config (Maven/Gradle) in the repo root. You can either import the project into an IDE (Eclipse/IntelliJ) as a Dynamic Web Project or manually compile and deploy.

Manual compile (example used during development):

```powershell
# From repository root (adjust paths if needed)
javac -d build/classes src/main/java/com/skill/*.java
# Place compiled classes under the webapp's WEB-INF/classes (or package into a WAR)
```

Deploy to Tomcat:

1. Package into a WAR or copy the exploded webapp folder into Tomcat's `webapps/` directory.
2. Ensure `WEB-INF/web.xml` has the correct servlet mappings and context parameters.
3. Start Tomcat and visit http://localhost:8080/<context>/

If you use an IDE, create a Tomcat run configuration and deploy the webapp from the IDE.

## Common troubleshooting

- ClassNotFound for servlets: ensure compiled classes are under `WEB-INF/classes/com/skill` or packaged into the WAR.
- JDBC connection errors: check JDBC URL, username/password, and that MySQL is running and accessible from Tomcat.
- Password verification fails after migration: ensure stored `Users.PasswordHash` values were generated via the PBKDF2 format used by `PasswordUtils` (format: iterations:salt:hash in base64). If users were stored as plaintext, run a migration to re-hash passwords after obtaining secure passwords.
- JSP blank fields or broken modal behavior: ensure strings rendered into attributes are HTML-escaped; modernized code uses data- attributes and safe escaping.

## Testing

- Unit tests for `PasswordUtils` are recommended (verify hash generation and verification across several inputs and edge cases).
- Add integration tests for `SubmitBid` to ensure server-side enforcement that providers must have the skill.

## Contributing

Contributions are welcome:

1. Fork the repo.
2. Create a topic branch for your change.
3. Add tests for new behavior where relevant.
4. Submit a pull request describing the change.

Please follow these guidelines:

- Keep server-side validations authoritative (don't trust client-only checks).
- Use prepared statements for DB access.
- Add small, focused commits.
