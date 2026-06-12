-- InternHub PostgreSQL Database Schema

-- Drop existing tables if they exist to start fresh
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS internships CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'student' CHECK (role IN ('student', 'recruiter', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Companies Table
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    description TEXT,
    website VARCHAR(150),
    location VARCHAR(100) NOT NULL
);

-- 3. Internships Table
CREATE TABLE internships (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    stipend VARCHAR(50) NOT NULL,
    duration VARCHAR(50) NOT NULL,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Applications Table
CREATE TABLE applications (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    internship_id INTEGER REFERENCES internships(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'Applied' CHECK (status IN ('Applied', 'Reviewing', 'Interviewing', 'Offered', 'Archived')),
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed Initial Mock Company Data
INSERT INTO companies (company_name, description, website, location) VALUES 
('Linear', 'Building the future of software project tracking.', 'https://linear.app', 'Remote'),
('Stripe', 'Global financial infrastructure for internet payments.', 'https://stripe.com', 'San Francisco, CA'),
('Vercel', 'Edge networks and deployment hosting engines.', 'https://vercel.com', 'Remote'),
('Notion', 'Modular connected workspaces for documents and wikis.', 'https://notion.so', 'New York, NY');
