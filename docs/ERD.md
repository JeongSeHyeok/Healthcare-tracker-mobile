# DB ERD 요약

```text
User
- id PK
- email UNIQUE
- password
- name
- age
- height
- weight
- bmr
- muscle_mass
- privacy_consent

Exercise
- id PK
- user_id FK
- type
- duration
- speed
- incline
- calories
- exercise_date

Nutrition
- id PK
- user_id FK
- food_name
- calories
- intake_time

Goal
- id PK
- user_id FK
- goal_type
- target_value
- current_value

WearableLog
- id PK
- user_id FK
- steps
- heart_rate
- source
- logged_at

Notification
- id PK
- user_id FK
- message
- is_read
- created_at
```

관계:
- User 1 : N Exercise
- User 1 : N Nutrition
- User 1 : N Goal
- User 1 : N WearableLog
- User 1 : N Notification
