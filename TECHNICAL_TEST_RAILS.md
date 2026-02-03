# Technical Test: Room Reservation System

## General Information

| Field | Value |
|-------|-------|
| **Position** | Ruby on Rails Developer |
| **Maximum Duration** | 2 hours |
| **Mode** | Remote, AI usage permitted and recommended |
| **Deliverable** | Git repository with commit history |

---

## Test Objective

This test evaluates your ability to:

1. **Develop with TDD** (Test-Driven Development)
2. **Use AI tools** effectively (Claude Code, Copilot, etc.)
3. **Write idiomatic Ruby/Rails code**
4. **Model complex business rules**

> **IMPORTANT**: You are expected to use AI. This test is designed to be completed efficiently with AI assistance. What we evaluate is your ability to direct the AI, validate its output, and apply TDD correctly.

---

## Prerequisites

- Ruby 3.2+ installed
- Git installed
- Code editor with Claude Code or similar

**You DON'T need:**
- Docker
- PostgreSQL or any external database
- Additional service configuration

---

## Initial Setup

```bash
# Install Rails (if you don't have it)
gem install rails

# Create the project
rails new room_reservations --api -T
cd room_reservations

# Add RSpec for testing
# Edit the Gemfile and add to the :development, :test group
# gem 'rspec-rails'
# gem 'factory_bot_rails'
# gem 'shoulda-matchers'

bundle install
rails generate rspec:install

# Initialize git
git init
git add .
git commit -m "Initial Rails setup with RSpec"

# Verify it works
rails server
# Visit http://localhost:3000 - you should see the Rails page
```

---

## The Problem

**MeetingRooms Inc.** needs an API to manage their meeting room reservations. The system must be robust and prevent booking conflicts.

---

## Data Models

### Room
| Field | Type | Description |
|-------|------|-------------|
| name | string | Room name (unique, required) |
| capacity | integer | Maximum capacity |
| has_projector | boolean | Does it have a projector? |
| has_video_conference | boolean | Does it have video conference equipment? |
| floor | integer | Floor where it's located |

### User
| Field | Type | Description |
|-------|------|-------------|
| name | string | Full name (required) |
| email | string | Email (unique, required) |
| department | string | Department (required) |
| max_capacity_allowed | integer | Maximum room capacity they can book |
| is_admin | boolean | Is administrator? (default: false) |

### Reservation
| Field | Type | Description |
|-------|------|-------------|
| room_id | references | Reserved room |
| user_id | references | User making the reservation |
| title | string | Meeting title (required) |
| starts_at | datetime | Reservation start |
| ends_at | datetime | Reservation end |
| recurring | string | Recurrence type: null, 'daily', 'weekly' |
| recurring_until | date | Recurrence end date (if applicable) |
| cancelled_at | datetime | Cancellation date (null if active) |

---

## Business Rules (CRITICAL)

These are the rules your system MUST implement and test:

### BR1: No overlapping reservations
> There cannot be more than one active reservation for the same room during the same time period.

**Cases to consider:**
- New reservation that starts during an existing one
- New reservation that ends during an existing one
- New reservation that completely contains another
- New reservation contained within another

### BR2: Maximum duration
> A reservation cannot last more than 4 hours.

### BR3: Business hours only
> Reservations can only be between 9:00 AM and 6:00 PM, Monday through Friday.

**Cases to consider:**
- Cannot start before 9:00 AM
- Cannot end after 6:00 PM
- Cannot book on Saturdays or Sundays

### BR4: Capacity restriction by user
> A regular user (non-admin) can only book rooms whose capacity is ≤ their `max_capacity_allowed`. Administrators can book any room.

### BR5: Active reservation limit
> A user cannot have more than 3 active reservations (future and not cancelled) simultaneously. Administrators have no limit.

### BR6: Advance cancellation
> A reservation can only be cancelled if there are more than 60 minutes until its start time.

### BR7: Recurring reservations
> When creating a reservation with `recurring = 'weekly'` or `'daily'`:
> - All occurrences must be created until `recurring_until`
> - ALL occurrences must comply with rules BR1-BR5
> - If any occurrence violates a rule, NO reservations are created

---

## Required API Endpoints

### Rooms
```
GET    /api/v1/rooms                 # List all rooms
GET    /api/v1/rooms/:id             # Room details
POST   /api/v1/rooms                 # Create room (admin only)
GET    /api/v1/rooms/:id/availability?date=YYYY-MM-DD  # Day availability
```

### Users
```
GET    /api/v1/users                 # List users
POST   /api/v1/users                 # Create user
GET    /api/v1/users/:id             # User details
```

### Reservations
```
GET    /api/v1/reservations          # List reservations (filterable by room_id, user_id, date)
POST   /api/v1/reservations          # Create reservation
GET    /api/v1/reservations/:id      # Reservation details
PATCH  /api/v1/reservations/:id/cancel  # Cancel reservation
```

---

## Development Process (TDD Required)

**You MUST follow the Red-Green-Refactor cycle:**

### 1. RED: Write the test first
```ruby
# Example: spec/models/reservation_spec.rb
describe 'BR1: No overlapping' do
  it 'does not allow creating a reservation that overlaps with an existing one' do
    room = create(:room)
    user = create(:user)

    # Existing reservation from 10:00 to 12:00
    create(:reservation, room: room, starts_at: '2024-01-15 10:00', ends_at: '2024-01-15 12:00')

    # Try to book from 11:00 to 13:00 (overlaps)
    new_reservation = build(:reservation, room: room, starts_at: '2024-01-15 11:00', ends_at: '2024-01-15 13:00')

    expect(new_reservation).not_to be_valid
    expect(new_reservation.errors[:base]).to include('The room is already booked for that time slot')
  end
end
```

### 2. GREEN: Implement the minimum code to pass the test
```ruby
# app/models/reservation.rb
validate :no_overlapping_reservations

def no_overlapping_reservations
  # ... implementation
end
```

### 3. REFACTOR: Improve the code while keeping tests green

### 4. COMMIT: Make a commit with a descriptive message
```bash
git add .
git commit -m "feat(reservation): add validation for overlapping reservations

- Implement BR1: no overlapping reservations for same room
- Add custom validation with clear error message
- Tests: 4 cases covering all overlap scenarios"
```

---

## Expected Commit Structure

We want to see your process. Example of ideal history:

```
feat(setup): configure RSpec with FactoryBot
test(room): add model validations tests
feat(room): implement Room model with validations
test(user): add model validations tests
feat(user): implement User model with validations
test(reservation): add BR1 overlapping tests
feat(reservation): implement no-overlap validation
test(reservation): add BR2 max duration tests
feat(reservation): implement max duration validation
test(reservation): add BR3 business hours tests
feat(reservation): implement business hours validation
... etc
```

---

## Evaluation Criteria

| Criterion | Weight | What we look for |
|----------|------|--------------|
| **Correct TDD** | 30% | Tests written BEFORE code (visible in commits) |
| **Business Rules** | 30% | All BRs implemented and tested correctly |
| **Idiomatic Code** | 20% | Clean Ruby/Rails, conventions followed |
| **AI Usage** | 10% | Effective prompts, output validation |
| **Git Hygiene** | 10% | Atomic commits, descriptive messages |

### Bonus Points
- [ ] Elegant API error handling
- [ ] API documentation (can be with comments)
- [ ] Useful seeds for manual testing
- [ ] Any edge case we didn't mention but makes sense

---

## Deliverables

1. **Git Repository** (GitHub, GitLab, or zip with `.git`)
   - Must include full commit history

2. **Updated README** with:
   - How to run the tests
   - How to start the server
   - Important technical decisions (if any)

3. **Passing tests**
   ```bash
   bundle exec rspec
   # Should show all tests in green
   ```

---

## Frequently Asked Questions

### Can I use additional gems?
Yes, but justify their use. You don't need gems for basic business rules.

### Do I need authentication?
No. Assume the `user_id` comes in the request body. In a real app you'd use JWT or similar, but that's not the focus of this test.

### What if I don't have time for everything?
Prioritize quality over quantity. We prefer 3 business rules perfectly implemented with TDD over 7 half-done rules.

### Can I ask questions during the test?
Yes, but try to resolve ambiguities using your judgment (and document your decisions).

### How do you verify I used TDD?
We review the Git history. Commits must clearly show: test first → code after.

---

## Final Notes

This test is designed to be completed efficiently **using AI as a tool**.

The ideal flow is:
1. Read and understand a business rule
2. Ask the AI to generate the tests for that rule
3. Review that the tests cover the important cases
4. Ask the AI to implement the code
5. Verify that tests pass and the code makes sense
6. Commit
7. Next rule

**What we evaluate is NOT if you can write code without help**, but if you can **effectively direct an AI tool** to produce quality code following best practices.

---

Good luck!
