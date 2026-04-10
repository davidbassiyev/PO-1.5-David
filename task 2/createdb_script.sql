CREATE SCHEMA IF NOT EXISTS fitness_club_db;
SET search_path TO fitness_club_db;

CREATE TABLE IF NOT EXISTS membership_types (
    membership_type_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    duration_months INT NOT NULL CHECK (duration_months > 0),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0), -- фильтрация на негативное число
    access_level VARCHAR(50) NOT NULL,
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS members (
    member_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    membership_type_id INT NOT NULL REFERENCES membership_types(membership_type_id),
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS instructors (
    instructor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(50) NOT NULL CHECK (specialization IN ('Yoga', 'Cardio', 'MMA', 'Gym')), -- ограничиваю список специализаций для фильтрации
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS classes (
    class_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS facilities (
    facility_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    capacity INT NOT NULL CHECK (capacity >= 0),
    location_description VARCHAR(100),
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS schedule (
    schedule_id SERIAL PRIMARY KEY,
    class_id INT NOT NULL REFERENCES classes(class_id),
    instructor_id INT NOT NULL REFERENCES instructors(instructor_id),
    facility_id INT NOT NULL REFERENCES facilities(facility_id),
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    duration_hours NUMERIC(5,2) GENERATED ALWAYS AS (duration_minutes / 60.0) STORED,
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS schedule_enrollment (
    member_id INT NOT NULL REFERENCES members(member_id),
    schedule_id INT NOT NULL REFERENCES schedule(schedule_id),
    PRIMARY KEY (member_id, schedule_id),
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id SERIAL PRIMARY KEY,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('Cash', 'Card', 'Transfer')),
    member_id INT NOT NULL REFERENCES members(member_id),
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE,
    CHECK (payment_date > '2026-01-01 00:00:00') -- проверка даты позднее 1 января 2026 года
);

TRUNCATE TABLE 
    payments,
    schedule_enrollment,
    schedule,
    facilities,
    classes,
    instructors,
    members,
    membership_types
RESTART IDENTITY CASCADE;

INSERT INTO membership_types (name, duration_months, price, access_level)
VALUES ('Gold', 12, 500.00, 'VIP');

INSERT INTO membership_types (name, duration_months, price, access_level)
VALUES ('Silver', 6, 250.00, 'Medium');

INSERT INTO members (first_name, last_name, date_of_birth, membership_type_id)
VALUES ('John', 'Smith', '2001-02-15', 1);

INSERT INTO members (first_name, last_name, date_of_birth, membership_type_id)
VALUES ('Dias', 'Ermekov', '2003-04-23', 2);

INSERT INTO members (first_name, last_name, date_of_birth, membership_type_id)
VALUES ('Anna', 'Brown', '2006-03-10', 2);

INSERT INTO instructors (first_name, last_name, specialization)
VALUES ('Mike', 'Johnson', 'Yoga');

INSERT INTO instructors (first_name, last_name, specialization)
VALUES ('John', 'Pork', 'MMA');

INSERT INTO instructors (first_name, last_name, specialization)
VALUES ('Sara', 'Lee', 'Cardio');

INSERT INTO classes (name, description)
VALUES ('Morning Yoga', 'Relaxing yoga class');

INSERT INTO classes (name, description)
VALUES ('HIIT Training', 'Intensive cardio workout');

INSERT INTO classes (name, description)
VALUES ('MMA', 'Mixed Martial Arts');
INSERT INTO facilities (name, capacity, location_description)
VALUES ('Room A', 30, 'First floor');

INSERT INTO facilities (name, capacity, location_description)
VALUES ('Gym Hall', 50, 'Second floor');

INSERT INTO schedule (class_id, instructor_id, facility_id, duration_minutes)
VALUES (1, 1, 1, 60);

INSERT INTO schedule (class_id, instructor_id, facility_id, duration_minutes)
VALUES (2, 2, 2, 90);

INSERT INTO schedule (class_id, instructor_id, facility_id, duration_minutes)
VALUES (3, 3, 1, 90);

INSERT INTO schedule_enrollment (member_id, schedule_id)
VALUES (1, 1);

INSERT INTO schedule_enrollment (member_id, schedule_id)
VALUES (2, 2);

INSERT INTO payments (amount, payment_method, member_id)
VALUES (500.00, 'Card', 1);

INSERT INTO payments (amount, payment_method, member_id)
VALUES (250.00, 'Cash', 2);