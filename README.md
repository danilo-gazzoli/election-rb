
# Web-based Elections System

Welcome to the Web-based Elections System for Schools repository!
This project aims to provide a practical, transparent, and cost-effective solution for conducting elections in a school environment, simulating aspects of the Brazilian electoral system.


## Table of Contents

#### 1. [Overview](#overview)
#### 2. [Key Features](#key-features)
#### 3. [Requirements](#requirements)
#### 4. [Getting Started](#getting-started)
#### 5. [Data Modeling (Summary)](#data-modeling-summary)
#### 6. [Main Business Rules](#main-business-rules)
#### 7. [Contributing](#contributing)
#### 9. [License](#license)
---

## Overview

This system is designed to manage:

- **School Elections** (e.g., student council, class leaders, or simulations of municipal elections).
- **Candidates and Parties**, supporting positions with a vice-candidate and a variable number of seats.
- **Ballots (tablets)** serving as voting terminals, requiring a validation code provided by a poll worker (mesário) before each vote.
- **Security Logs**, accessible to the public, to see which user performed which actions and when.
- **Cached Results** updated every 15 minutes, reducing costs and preventing database overload.

The primary focus is on **transparency, security, and cost-efficiency**.

---
## Key Features

#### 1. **Election Creation and Management**
   - Title, dates, positions (with or without vice-candidates), number of seats, and status (draft, scheduled, ongoing, completed, canceled).
#### 2. **Candidate and Party Registration**
   - Linking candidates to specific positions and optional parties.
#### 3. **Ballot (Tablet) Configuration**
   - Generating a username, password, and **validation code** for each voting terminal.
#### 4. **Voting Process**
   - Poll worker enters a validation code to unlock the ballot.
   - Voter casts their vote (with options for white/blank or null).
   - System records the vote with timestamp and ballot ID.
#### 5. **Security Logs**
   - Publicly accessible, tracking create/edit/delete actions and election start/end.
#### 6. **15-minute Data Refresh**
   - Cached (in Redis) statistics minimize heavy DB queries for real-time results.
#### 7. **Responsive Front-end**
   - Built with **HTML, CSS, JS, and Bootstrap** for consistent and accessible interfaces.

---
## Requirements



- **Language / Framework**:
  - **Ruby on Rails** (server-side), leveraging CRUD capabilities, built-in security conventions, and MVC structure.
- **Database**:
  - **PostgreSQL** for storing elections, candidates, votes, logs, etc.
- **Caching**:
  - **Redis** for in-memory storage of computed results, refreshed every 15 minutes.
- **Containerization**:
  - **Docker** and **Docker Compose** to standardize environments and streamline deployment.
- **Front-end**:
  - **HTML, CSS, JS, and Bootstrap** (Rails server-side rendering, using partials/layouts).
  - Can be extended with Stimulus or AJAX calls if needed for dynamic interactions.
- **Hosting**:
  - Any cloud provider (AWS, Heroku, DigitalOcean, etc.) capable of running Docker/Rails.
  - Simple DB backup strategy (daily or more frequent if needed).

### Common Dependencies

- **Ruby** (3.2.0 recommended)
- **Rails** (7.1.0 or higher)
- **PostgreSQL** (version 13+ or compatible)
- **Redis** (5+ or compatible)
- Typical Rails gems: `pg`, `redis`, `devise` (optional for authentication), `pundit` or `cancancan` (optional for authorization), etc.

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/web-based-school-elections.git
cd web-based-school-elections
```

### 2. Docker Setup (Optional)
If you prefer to run everything in containers (Rails, PostgreSQL, Redis), ensure Docker and Docker Compose are installed.

```bash
docker-compose build
docker-compose up
```

Services included might be:

* app (Rails application container)
* db (PostgreSQL container)
* redis (Redis container)

### 3. Manual Setup (Without Docker)

#### 1. **Install dependencies:**

* Ruby, Rails, PostgreSQL, Redis (locally).

#### 2. **Install gems:**

```bash
bundle install
```

#### 3. **Database setup:**

* Update config/database.yml with your PostgreSQL credentials.
* Run migrations:

```bash
rails db:create
rails db:migrate
```

#### 4. **Start the server**:

```bash
rails server
```
The application will be available at http://localhost:3000.

### 4. Access the Application

Open your browser at http://localhost:3000 (or your configured port).







## Data Modeling (Summary)

Suggested table structure (simplified example):

- **users**: Stores data for admins and poll workers (name, email, password, role).
- **elections**: Title, start and end time, status (draft, scheduled, ongoing, canceled).
- **offices**: Position name (e.g., “President”), whether it requires a vice, number of seats, etc.
- **parties**: Party name, abbreviation, description.
- **candidates**: Candidate name, number, party reference, photo, optional link to vice if required.
- **ballots**: Represents voting terminals (username, password, validation code).
- **votes**: Records each vote (election ID, office/candidate or blank/null, date/time, ballot ID).
- **logs**: Stores critical actions (creation, editing, deletion, election start/end).

## Main Business Rules

#### 1. **White/Blank and Null Votes**
   - Counted separately and do not contribute to any candidate, yet are included in overall vote totals.
#### 2. **Positions with Vice**
   - A “ticket” (candidate + vice) for positions requiring it.
#### 3. **Multiple Seats**
   - A voter can select multiple candidates if the position has multiple seats (e.g., a 3-member council).
#### 4. **Ballots (Tablets)**
   - Each ballot has a login, password, and a validation code required before every vote.
#### 5. **Security Logs**
   - Publicly accessible, no login required, capturing all relevant system actions.
#### 6. **15-minute Cache**
   - Prevents excessive load on the database by refreshing election statistics in Redis every 15 minutes.

---

## Contributing

Contributions are welcome! Feel free to open issues to ask questions, suggest features, or report bugs, and submit pull requests for improvements or fixes.

### Steps to Contribute

#### 1. **Fork** this repository.
#### 2. Create a branch for your feature/bug fix:
   ```bash
   git checkout -b feature/new-feature
   ```

#### 3. Commit your changes and push to your fork:
   ```bash
   git push origin feature/new-feature
   ```

#### 4. Open a **pull request** pointing to the main branch of the original repository.
## License

[MIT](https://choosealicense.com/licenses/mit/)

This project is licensed under the MIT License.

You are free to use and adapt it, as long as you respect the license terms.

