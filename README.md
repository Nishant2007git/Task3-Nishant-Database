# InternHub — Database Architecture & Schema

This directory contains the database definition and initialization scripts for the InternHub application. The system uses **PostgreSQL** as its primary persistent database engine, with a query model that supports automatic in-memory mock fallback for local development.

---

## 📊 Database Schema Design

The database consists of 4 main tables structured to enforce data integrity through check constraints and foreign key cascading.

### Entity-Relationship Diagram (Mental Model)
```
  [users] ──(1:N)── [applications] ──(N:1)── [internships] ──(N:1)── [companies]
```

### Table Definitions (from `schema.sql`)

1.  **`users`**: Stores client profiles for students, recruiters, and admins.
    *   `id`: `SERIAL PRIMARY KEY`
    *   `name`: `VARCHAR(100) NOT NULL`
    *   `email`: `VARCHAR(150) UNIQUE NOT NULL`
    *   `password`: `VARCHAR(255) NOT NULL` (Hashed using `bcrypt`)
    *   `role`: `VARCHAR(50) DEFAULT 'student'` — Enforces `CHECK (role IN ('student', 'recruiter', 'admin'))`
    *   `created_at`: `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP`

2.  **`companies`**: Stores profiles of startup partners.
    *   `id`: `SERIAL PRIMARY KEY`
    *   `company_name`: `VARCHAR(100) NOT NULL`
    *   `description`: `TEXT`
    *   `website`: `VARCHAR(150)`
    *   `location`: `VARCHAR(100) NOT NULL`

3.  **`internships`**: Stores job vacancies posted by recruiters.
    *   `id`: `SERIAL PRIMARY KEY`
    *   `title`: `VARCHAR(100) NOT NULL`
    *   `description`: `TEXT NOT NULL`
    *   `stipend`: `VARCHAR(50) NOT NULL`
    *   `duration`: `VARCHAR(50) NOT NULL`
    *   `company_id`: `INTEGER REFERENCES companies(id) ON DELETE CASCADE`
    *   `created_at`: `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP`

4.  **`applications`**: Tracks the recruitment pipeline Kanban stage for applicants.
    *   `id`: `SERIAL PRIMARY KEY`
    *   `student_id`: `INTEGER REFERENCES users(id) ON DELETE CASCADE`
    *   `internship_id`: `INTEGER REFERENCES internships(id) ON DELETE CASCADE`
    *   `status`: `VARCHAR(50) DEFAULT 'Applied'` — Enforces `CHECK (status IN ('Applied', 'Reviewing', 'Interviewing', 'Offered', 'Archived'))`
    *   `applied_at`: `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP`

---

## 🛠️ CRUD Operations Mapping

The backend application interacts with the PostgreSQL database by executing parameterized SQL queries:

| Entity | Action | SQL Query / Operation | Executed in |
| :--- | :--- | :--- | :--- |
| **Users** | Create | `INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4) RETURNING *` | `authController.js` |
| | Read (Login) | `SELECT * FROM users WHERE email = $1` | `authController.js` |
| | Read (Admin) | `SELECT id, name, email, role, created_at FROM users` | `server.js` |
| **Internships** | Create | `INSERT INTO internships (title, description, stipend, duration, company_id) VALUES ($1, $2, $3, $4, $5) RETURNING *` | `internshipController.js` |
| | Read (List) | `SELECT i.*, c.company_name, c.location FROM internships i LEFT JOIN companies c ON i.company_id = c.id` | `internshipController.js` |
| | Update | `UPDATE internships SET title = COALESCE($1, title), ... WHERE id = $5 RETURNING *` | `internshipController.js` |
| | Delete | `DELETE FROM internships WHERE id = $1` | `internshipController.js` |
| **Applications**| Create | `INSERT INTO applications (student_id, internship_id, status) VALUES ($1, $2, 'Applied') RETURNING *` | `applicationController.js` |
| | Read (Student)| `SELECT a.*, i.title, c.company_name FROM applications a ... WHERE a.student_id = $1` | `applicationController.js` |
| | Read (Recruit)| `SELECT a.*, i.title, u.name AS student_name FROM applications a ...` | `applicationController.js` |
| | Update Status| `UPDATE applications SET status = $1 WHERE id = $2 RETURNING *` | `applicationController.js` |
| | Delete (Cancel)| `DELETE FROM applications WHERE id = $1` | `applicationController.js` |

---

## 🔗 Backend–Database Connection Code

The connection is configured in `backend/models/db.js` using the **`pg` (node-postgres)** library. 

### Key Design Pattern: Dual-Mode Connection with Auto-Fallback
The model script reads parameters from the environment and tries to instantiate a database pool. If connection configurations are missing or connection attempts fail, it gracefully switches to an in-memory SQL mock engine:

```javascript
const { Pool } = require('pg');

let pool;
let isMock = false;

// 1. Connection Pooling Setup
if (process.env.DATABASE_URL || (process.env.DB_USER && process.env.DB_PASSWORD)) {
  const config = process.env.DATABASE_URL 
    ? { connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } }
    : {
        user: process.env.DB_USER,
        host: process.env.DB_HOST || 'localhost',
        database: process.env.DB_NAME,
        password: process.env.DB_PASSWORD,
        port: process.env.DB_PORT || 5432,
      };
  pool = new Pool(config);
} else {
  isMock = true; // Fallback to in-memory db fallback
}

// 2. Safe Query Runner wrapper
const query = async (text, params = []) => {
  if (isMock) {
    return runMockQuery(text, params); // Simulated in-memory query engine
  }
  try {
    return await pool.query(text, params);
  } catch (err) {
    console.error('❌ Database error. Falling back to mock:', err.message);
    return runMockQuery(text, params);
  }
};
```

---

## 💻 Database Setup & Import Instructions

To set up the physical database locally, complete the following steps:

### 1. Start your PostgreSQL Instance
Ensure your PostgreSQL server is active on your machine (default port: `5432`).

### 2. Create the Database
Open terminal or `psql` shell and run:
```sql
CREATE DATABASE internhub;
```

### 3. Run the Schema Script
Import the tables and seed mock companies by executing `schema.sql` against your new database:
```bash
psql -U postgres -d internhub -f database/schema.sql
```
*(Replace `postgres` with your PostgreSQL username if different).*

### 4. Update the Backend Environment Config
Make sure your root `.env` file matches your credentials:
```ini
DB_USER=postgres
DB_HOST=localhost
DB_NAME=internhub
DB_PASSWORD=your_postgres_password
DB_PORT=5432
```
