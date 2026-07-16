# TinderHW3 — Full-Stack PoC

A small proof-of-concept full-stack app:

- **Database:** Microsoft SQL Server 2022 (running in Docker), database `TinderHW3`.
- **Backend:** Node.js + Express, using the `mssql` driver. Exposes `GET /api/profiles`.
- **Frontend:** a single `index.html` (vanilla JS/CSS). A "Load Profiles" button
  fetches the API and renders each profile as a Tinder-style card.

The API joins the `profiles` table with `photos` (the primary photo) so cards show
real photos, and computes each person's **age** from `birth_date`.

---

## Prerequisites

1. **Docker Desktop** installed and running.
2. **SQL Server** running in a container named `sqlserver`, with the `TinderHW3`
   database and its tables already created. It should be reachable at
   `localhost:1433` (user `sa`).
3. **Node.js** (v18+) installed. Check with: `node -v`

> If SQL Server isn't running yet, start it with:
> ```bash
> docker start sqlserver
> ```

---

## Setup & Run

```bash
# 1. Go into the backend folder
cd backend

# 2. Create your .env from the template and adjust if needed
cp .env.example .env

# 3. Install dependencies
npm install

# 4. Start the server
npm start
```

Then open **http://localhost:3000** in your browser and click **“Load Profiles”**.

---

## Project structure

```
בניית מערכת שיעור 3/
├── backend/
│   ├── server.js        # Express app: /api/profiles + serves the frontend
│   ├── db.js            # SQL Server connection pool
│   ├── package.json     # dependencies + "start" script
│   ├── .env             # your real credentials (ignored by git)
│   └── .env.example     # template
├── public/
│   └── index.html       # the UI (button + profile cards)
├── .gitignore
└── README.md
```

---

## API

### `GET /api/profiles`
Returns all profiles as JSON:

```json
[
  {
    "user_id": 1,
    "first_name": "Alice",
    "last_name": "Smith",
    "gender": "F",
    "bio": "Loves hiking and reading.",
    "location_name": "Tel Aviv",
    "birth_date": "1997-02-02",
    "age": 29,
    "photo_url": "https://randomuser.me/api/portraits/men/1.jpg"
  }
]
```

- **200** — success (returns `[]` if the table is empty).
- **503** — the database is unreachable.

### Authentication (`/api/auth`)
The app opens on a **login / sign-up** screen. Sessions are kept client-side
(localStorage) and the user id is sent as an `x-user-id` header to authorize
protected routes. (A production app would use signed JWT tokens — the checks
are shaped the same way.)

| Method | Route | Purpose |
|--------|-------|---------|
| `POST` | `/api/auth/register` | Create an account + profile, returns the session user |
| `POST` | `/api/auth/login` | Verify `identifier` (username or email) + `password`, returns the session user (401 on failure) |
| `GET`  | `/api/auth/me/:id` | Refresh the session user (after editing your profile) |

**Roles:** the `users.is_admin` flag controls access. Only admins can list all
users or create/delete accounts; a regular user may view/edit/delete only
themselves. Non-admin management calls return **403**.

**Demo accounts:**
- Admin — `admin` / `admin123` (sees the ⚙️ gear + user management)
- User — `alice` / `alice123` (has existing likes & matches)

### Users CRUD (`/api/users`)
A full REST resource. A "user" = the account (`users` table) + profile (`profiles`).

| Method | Route | Purpose |
|--------|-------|---------|
| `GET`  | `/api/users` | List all users. Filters: `?search=`, `?gender=M\|F\|O`, `?minAge=`, `?maxAge=`, `?city=`, `?sort=name\|age_asc\|age_desc\|city\|newest` |
| `GET`  | `/api/users/:id` | Full details of one user (404 if missing) |
| `POST` | `/api/users` | Create a user + profile. Body: `username, email, password, first_name, last_name, birth_date, gender` (required) + `bio, location_name, profile_photo_url` (optional). 409 on duplicate username/email |
| `PUT`  | `/api/users/:id` | Update any subset of account/profile fields |
| `DELETE` | `/api/users/:id` | Delete the user and every related row (swipes, matches, photos, etc.) in one transaction |

Passwords are hashed (SHA-256) before storing and never returned in responses.

Example — create a user:
```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"janed","email":"jane@x.com","password":"pw123",
       "first_name":"Jane","last_name":"Doe","birth_date":"1996-04-10",
       "gender":"F","location_name":"Tel Aviv"}'
```

### `GET /api/health`
Returns `{ "status": "ok" }` — a quick liveness check.

---

## Troubleshooting

- **“Could not fetch profiles”** → make sure the container is up: `docker ps`.
  If not: `docker start sqlserver`.
- **Login failed** → confirm the password in `.env` matches the container's
  `SA_PASSWORD` (`YourStrong@Passw0rd`).
- **Port 3000 in use** → change `PORT` in `.env`.
