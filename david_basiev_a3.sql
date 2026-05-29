-- david_basiev_a3.sql
-- fitness club — assignment 3 (DCL + DML)
-- запуск: pgAdmin → Query Tool → Execute (F5) на ВЕСЬ файл
--
-- ПЕРВЫЙ ЗАПУСК:  блок "повторный запуск"
-- ВТОРОЙ и дальше ЗАПУСК: раскомментировать блок "повторный запуск"
-- если drop role падает с "objects depend" - блок "revoke admin"


-- =============================================================================
-- повторный запуск
-- =============================================================================

-- drop user if exists db_reader_user;
-- drop user if exists db_admin_user;
-- drop role if exists fitness_club_readonly;
-- drop role if exists fitness_club_admin;


-- =============================================================================
-- revoke admin — только если drop role выше дал "objects depend"
-- =============================================================================

-- revoke all privileges on all tables in schema public from fitness_club_admin;
-- revoke all privileges on all sequences in schema public from fitness_club_admin;
-- revoke usage on schema public from fitness_club_admin;
-- drop owned by fitness_club_admin;
-- drop role if exists fitness_club_admin;


-- =============================================================================
-- tables
-- =============================================================================

set search_path to public;

create table if not exists membership_types (
    membership_type_id serial primary key,
    name varchar(50) not null unique,
    duration_months int not null check (duration_months > 0),
    price numeric(10, 2) not null check (price >= 0),
    access_level varchar(50) not null,
    record_ts date not null default current_date
);

create table if not exists members (
    member_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    date_of_birth date not null,
    membership_type_id int not null references membership_types (membership_type_id),
    record_ts date not null default current_date
);

create table if not exists instructors (
    instructor_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    specialization varchar(50) not null check (specialization in ('Yoga', 'Cardio', 'MMA', 'Gym')),
    record_ts date not null default current_date
);

create table if not exists classes (
    class_id serial primary key,
    name varchar(100) not null unique,
    description text,
    record_ts date not null default current_date
);

create table if not exists facilities (
    facility_id serial primary key,
    name varchar(50) not null,
    capacity int not null check (capacity >= 0),
    location_description varchar(100),
    record_ts date not null default current_date
);

create table if not exists schedule (
    schedule_id serial primary key,
    class_id int not null references classes (class_id),
    instructor_id int not null references instructors (instructor_id),
    facility_id int not null references facilities (facility_id),
    duration_minutes int not null check (duration_minutes > 0),
    duration_hours numeric(5, 2) generated always as (duration_minutes / 60.0) stored,
    record_ts date not null default current_date
);

create table if not exists schedule_enrollment (
    member_id int not null references members (member_id),
    schedule_id int not null references schedule (schedule_id),
    primary key (member_id, schedule_id),
    record_ts date not null default current_date
);

create table if not exists payments (
    payment_id serial primary key,
    amount numeric(10, 2) not null check (amount >= 0),
    payment_date timestamp default current_timestamp,
    payment_method varchar(30) not null check (payment_method in ('Cash', 'Card', 'Transfer')),
    member_id int not null references members (member_id),
    record_ts date not null default current_date,
    check (payment_date > '2026-01-01 00:00:00')
);


-- =============================================================================
-- part b — truncate + insert
-- =============================================================================

truncate table
    schedule_enrollment,
    payments,
    schedule,
    members,
    instructors,
    classes,
    facilities,
    membership_types
restart identity cascade;

insert into membership_types (name, duration_months, price, access_level)
values
    ('Basic Monthly', 1, 49.99, 'Gym Floor'),
    ('Premium Monthly', 1, 89.99, 'Gym + Group Classes'),
    ('Quarterly Plus', 3, 229.00, 'Gym + Pool + Classes'),
    ('Annual Elite', 12, 799.00, 'Full Access'),
    ('Student Semester', 6, 299.00, 'Gym + Selected Classes');

insert into members (first_name, last_name, date_of_birth, membership_type_id)
values
    ('Aida', 'Suleimenova', '1998-03-14',
        (select membership_type_id from membership_types where name = 'Premium Monthly')),
    ('Timur', 'Nurzhanov', '1992-07-22',
        (select membership_type_id from membership_types where name = 'Annual Elite')),
    ('Dana', 'Kairbekova', '2001-11-05',
        (select membership_type_id from membership_types where name = 'Student Semester')),
    ('Arman', 'Zhaksylykov', '1987-01-30',
        (select membership_type_id from membership_types where name = 'Basic Monthly')),
    ('Madina', 'Ospanova', '1995-09-18',
        (select membership_type_id from membership_types where name = 'Quarterly Plus'));

insert into instructors (first_name, last_name, specialization)
values
    ('Elena', 'Volkova', 'Yoga'),
    ('Ruslan', 'Akhmetov', 'Cardio'),
    ('Bekzat', 'Tulegenov', 'MMA'),
    ('Sergey', 'Petrov', 'Gym'),
    ('Aigerim', 'Sadykova', 'Yoga');

insert into classes (name, description)
values
    ('Morning Flow Yoga', 'Gentle vinyasa session focused on mobility and breathing.'),
    ('HIIT Cardio Blast', 'High-intensity interval training for endurance and fat burn.'),
    ('Intro to MMA', 'Beginner-friendly striking and grappling fundamentals.'),
    ('Strength Foundations', 'Barbell and dumbbell technique for safe progressive overload.'),
    ('Evening Power Yoga', 'Dynamic yoga flow to improve balance and core strength.');

insert into facilities (name, capacity, location_description)
values
    ('Studio A', 25, 'Second floor, east wing'),
    ('Cardio Zone', 40, 'Ground floor near reception'),
    ('Octagon Room', 16, 'Basement training area'),
    ('Free Weights Hall', 35, 'Ground floor, west wing'),
    ('Studio B', 20, 'Second floor, south wing');

insert into schedule (class_id, instructor_id, facility_id, duration_minutes)
values
    ((select class_id from classes where name = 'Morning Flow Yoga'),
     (select instructor_id from instructors where first_name = 'Elena' and last_name = 'Volkova'),
     (select facility_id from facilities where name = 'Studio A'), 60),
    ((select class_id from classes where name = 'HIIT Cardio Blast'),
     (select instructor_id from instructors where first_name = 'Ruslan' and last_name = 'Akhmetov'),
     (select facility_id from facilities where name = 'Cardio Zone'), 45),
    ((select class_id from classes where name = 'Intro to MMA'),
     (select instructor_id from instructors where first_name = 'Bekzat' and last_name = 'Tulegenov'),
     (select facility_id from facilities where name = 'Octagon Room'), 90),
    ((select class_id from classes where name = 'Strength Foundations'),
     (select instructor_id from instructors where first_name = 'Sergey' and last_name = 'Petrov'),
     (select facility_id from facilities where name = 'Free Weights Hall'), 75),
    ((select class_id from classes where name = 'Evening Power Yoga'),
     (select instructor_id from instructors where first_name = 'Aigerim' and last_name = 'Sadykova'),
     (select facility_id from facilities where name = 'Studio B'), 60);

insert into schedule_enrollment (member_id, schedule_id)
values
    ((select member_id from members where first_name = 'Aida' and last_name = 'Suleimenova'),
     (select s.schedule_id from schedule s join classes c on c.class_id = s.class_id where c.name = 'Morning Flow Yoga')),
    ((select member_id from members where first_name = 'Timur' and last_name = 'Nurzhanov'),
     (select s.schedule_id from schedule s join classes c on c.class_id = s.class_id where c.name = 'HIIT Cardio Blast')),
    ((select member_id from members where first_name = 'Dana' and last_name = 'Kairbekova'),
     (select s.schedule_id from schedule s join classes c on c.class_id = s.class_id where c.name = 'Intro to MMA')),
    ((select member_id from members where first_name = 'Arman' and last_name = 'Zhaksylykov'),
     (select s.schedule_id from schedule s join classes c on c.class_id = s.class_id where c.name = 'Strength Foundations')),
    ((select member_id from members where first_name = 'Madina' and last_name = 'Ospanova'),
     (select s.schedule_id from schedule s join classes c on c.class_id = s.class_id where c.name = 'Evening Power Yoga'));

insert into payments (amount, payment_date, payment_method, member_id)
values
    (89.99, '2026-02-03 10:15:00', 'Card',
        (select member_id from members where first_name = 'Aida' and last_name = 'Suleimenova')),
    (799.00, '2026-01-10 14:40:00', 'Transfer',
        (select member_id from members where first_name = 'Timur' and last_name = 'Nurzhanov')),
    (299.00, '2026-03-01 09:05:00', 'Cash',
        (select member_id from members where first_name = 'Dana' and last_name = 'Kairbekova')),
    (49.99, '2026-04-12 18:22:00', 'Card',
        (select member_id from members where first_name = 'Arman' and last_name = 'Zhaksylykov')),
    (229.00, '2026-05-05 11:30:00', 'Transfer',
        (select member_id from members where first_name = 'Madina' and last_name = 'Ospanova'));


-- =============================================================================
-- part c — update
-- =============================================================================

-- preview — row count: 1
select m.member_id, m.first_name, m.last_name, mt.name as current_membership
from members m
join membership_types mt on mt.membership_type_id = m.membership_type_id
where m.first_name = 'Arman' and m.last_name = 'Zhaksylykov';

update members
set membership_type_id = (select membership_type_id from membership_types where name = 'Premium Monthly')
where first_name = 'Arman' and last_name = 'Zhaksylykov';

-- preview — row count: 1
select membership_type_id, name, price from membership_types where name = 'Quarterly Plus';

update membership_types set price = 249.00 where name = 'Quarterly Plus';

-- preview — row count: 1
select s.schedule_id, c.name as class_name, s.duration_minutes
from schedule s
join classes c on c.class_id = s.class_id
where c.name = 'Intro to MMA';

update schedule s
set duration_minutes = 105
from classes c
where c.class_id = s.class_id and c.name = 'Intro to MMA';

-- preview — row count: 1
select p.payment_id, m.first_name, m.last_name, mt.name as membership, p.amount
from payments p
join members m on m.member_id = p.member_id
join membership_types mt on mt.membership_type_id = m.membership_type_id
where mt.name = 'Annual Elite';

update payments p
set amount = round(p.amount * 0.95, 2)
from members m
join membership_types mt on mt.membership_type_id = m.membership_type_id
where p.member_id = m.member_id and mt.name = 'Annual Elite';


-- =============================================================================
-- part d — delete (rollback)
-- =============================================================================

-- remove uncaptured card pre-authorizations below minimum charge
-- preview — row count: 1
select p.payment_id, m.first_name, m.last_name, p.amount, p.payment_method
from payments p
join members m on m.member_id = p.member_id
where p.payment_method = 'Card' and p.amount < 50.00;

begin;
delete from payments where payment_method = 'Card' and amount < 50.00;
-- remaining payments after delete: 4
select count(*) as remaining_payments from payments;
rollback;


-- =============================================================================
-- part a — dcl
-- =============================================================================

create role fitness_club_admin;
create role fitness_club_readonly;

grant usage on schema public to fitness_club_admin, fitness_club_readonly;

grant select, insert, update, delete on all tables in schema public to fitness_club_admin;
grant select on all tables in schema public to fitness_club_readonly;
grant usage, select on all sequences in schema public to fitness_club_admin;

revoke update, delete on all tables in schema public from fitness_club_readonly;

-- verify: \dp public.members
-- public | members | table | fitness_club_admin=arwdDxt/... + fitness_club_readonly=r/...

create user db_admin_user with password 'AdminPass123!';
create user db_reader_user with password 'ReaderPass123!';

grant fitness_club_admin to db_admin_user;
grant fitness_club_readonly to db_reader_user;

set search_path to public;


-- ====== verify db_admin_user ======
set role db_admin_user;
select current_user;
select count(*) from members;

insert into members (first_name, last_name, date_of_birth, membership_type_id)
select 'Nurlan', 'Baizhanov', date '1990-06-12', membership_type_id
from membership_types where name = 'Basic Monthly'
returning *;

update members set last_name = 'Baizhanuly'
where first_name = 'Nurlan' and last_name = 'Baizhanov';

delete from members
where first_name = 'Nurlan' and last_name = 'Baizhanuly';

reset role;


-- ====== verify db_reader_user ======
-- чтобы pgAdmin не останавливался на всём файле: 3 теста ниже закомментированы.
-- один раз выдели каждый блок (begin…rollback) и нажми F5 — увидишь permission denied.

set role db_reader_user;
select current_user;
select count(*) from members;

-- ERROR: permission denied for table members
-- begin;
-- insert into members (first_name, last_name, date_of_birth, membership_type_id)
-- select 'Reader', 'Blocked', date '2000-01-01', membership_type_id
-- from membership_types where name = 'Basic Monthly'
-- returning *;
-- rollback;

-- ERROR: permission denied for table members
-- begin;
-- update members set last_name = 'ShouldFail' where member_id = 1;
-- rollback;

-- ERROR: permission denied for table members
-- begin;
-- delete from members where member_id = 1;
-- rollback;

reset role;


-- =============================================================================
-- final cleanup (part a.4) — всегда выполняется
-- =============================================================================

revoke fitness_club_readonly from db_admin_user;

revoke all privileges on all tables in schema public from fitness_club_readonly;
revoke all privileges on all sequences in schema public from fitness_club_readonly;
revoke usage on schema public from fitness_club_readonly;
drop owned by fitness_club_readonly;

drop user if exists db_reader_user;
drop role if exists fitness_club_readonly;


-- check
select count(*) as members_count from members;
