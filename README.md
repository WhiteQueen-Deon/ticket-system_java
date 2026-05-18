# Easy Ticket System

A full-stack ticket booking web application built with Spring Boot. Users can browse events, purchase tickets, and manage their orders. Managers and administrators have additional tools for event and order management.

**Live Demo:** [ticket-systemjava-production.up.railway.app](https://ticket-systemjava-production.up.railway.app)

## Test Accounts

| Role | Username | Password |
|------|----------|----------|
| Admin | admin | admin123 |
| Manager | manager1 | manager123 |

## Features

**For Users**
- Register with email activation, log in with captcha verification
- Browse available events with search and pagination
- Purchase tickets and track order status (pending → paid → completed)
- Cancel pending orders; inventory is automatically restored
- Download PDF invoices for paid orders
- Manage profile and change password

**For Managers**
- Create, edit, enable/disable, and delete events
- View and manage all orders under their events

**For Administrators**
- Full access to all events and orders
- User account management

**System**
- Scheduled job automatically cancels unpaid orders after timeout
- Email notifications for account activation

## Screenshots

**Login**
<img width="852" height="488" alt="Login page" src="https://github.com/user-attachments/assets/8c911cf0-3639-4e1e-8066-f0bb5ea11abf" />

**Register**
<img width="842" height="685" alt="Register page" src="https://github.com/user-attachments/assets/53c2e0db-0919-4347-a6f0-550a11054049" />

**Main Dashboard**
<img width="1327" height="604" alt="Main dashboard" src="https://github.com/user-attachments/assets/7b78115a-8fbb-4f15-85fe-33e3d0ca4214" />

## Tech Stack

- **Java / Spring Boot** — MVC web framework, Spring Security, Spring Scheduler
- **MyBatis + MySQL** — data persistence with XML-mapped queries
- **Spring Security** — authentication, role-based access control (ADMIN / MANAGER / USER), session management
- **JSP + Layui** — server-side rendered frontend
- **iText (PDF)** — invoice generation
- **Kaptcha** — CAPTCHA generation
- **JavaMail** — email activation
- **HikariCP** — connection pooling

## Setup

### Prerequisites
- Java 8+
- MySQL 5.7+
- Maven

### Run

```bash
# 1. Create the database
mysql -u root -p < src/main/resources/sql/easy_ticket_db.sql

# 2. Configure database and mail credentials in application.yml
#    spring.datasource.username / password
#    spring.mail.username / password

# 3. Build and run
mvn spring-boot:run
```

The application starts at `http://localhost:8080`.

## Project Structure

```
src/main/java/com/easyticket/
├── controller/     # MVC controllers (Auth, Ticket, Event, User, Invoice, Profile)
├── service/        # Business logic, OrderCancelScheduler, EmailService
├── entity/         # JPA entities (User, Event, Order, IdentityCard)
├── mapper/         # MyBatis mappers
├── security/       # Spring Security config, CustomUserDetailsService
└── config/         # Web and password config

src/main/resources/
├── mapper/         # MyBatis XML query files
├── sql/            # Database schema
└── static/         # Frontend assets (Layui)

src/main/webapp/WEB-INF/jsp/   # JSP view templates
```