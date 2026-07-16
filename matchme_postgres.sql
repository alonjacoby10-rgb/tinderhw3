-- Auto-converted from T-SQL to PostgreSQL
DROP TABLE IF EXISTS user_payments CASCADE;
DROP TABLE IF EXISTS subscription_types CASCADE;
DROP TABLE IF EXISTS superlikes_balance CASCADE;
DROP TABLE IF EXISTS blocks CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS swipes CASCADE;
DROP TABLE IF EXISTS photos CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50)UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE profiles (
    user_id INT PRIMARY KEY,  
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL, 
    birth_date DATE NOT NULL,
    gender CHAR(1) NOT NULL,
    bio TEXT,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    location_name VARCHAR(100),
    profile_photo_url TEXT,
    last_modified_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_profiles_users FOREIGN KEY (user_id) 
        REFERENCES users(user_id),

    CONSTRAINT chk_profiles_gender CHECK (gender IN ('M', 'F', 'O'))
);

CREATE TABLE photos (
    photo_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    url VARCHAR(500) NOT NULL,
    is_primary SMALLINT NOT NULL DEFAULT 0,
    uploaded_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_photos_users FOREIGN KEY (user_id)
        REFERENCES users(user_id) 
);

CREATE TABLE swipes (
    swipe_id SERIAL PRIMARY KEY,
    swiper_id INT NOT NULL,
    swiped_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_likes_swiper FOREIGN KEY (swiper_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_likes_swiped FOREIGN KEY (swiped_id)
        REFERENCES users(user_id)
);

CREATE TABLE matches (
    match_id SERIAL PRIMARY KEY,
    user1_id INT NOT NULL,
    user2_id INT NOT NULL,
    matched_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_matches_user1 FOREIGN KEY (user1_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_matches_user2 FOREIGN KEY (user2_id)
        REFERENCES users(user_id),

    CONSTRAINT uq_matches UNIQUE (user1_id, user2_id)
);

CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    match_id INT NOT NULL,
    sender_id INT NOT NULL,
    content TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_messages_matches FOREIGN KEY (match_id)
        REFERENCES matches(match_id),

    CONSTRAINT fk_messages_users FOREIGN KEY (sender_id)
        REFERENCES users(user_id)
);

CREATE TABLE user_preferences (
    user_id INT PRIMARY KEY,
    preferred_gender CHAR(1) NOT NULL,
    min_age INT CHECK (min_age >= 18),
    max_age INT,
    max_distance_km INT CHECK (max_distance_km >= 0),

    CONSTRAINT fk_user_preferences_users FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT chk_max_age CHECK (max_age >= min_age),
    CONSTRAINT chk_user_preferences_preferred_gender CHECK (preferred_gender IN ('M', 'F', 'O', 'B'))
);

CREATE TABLE reports (
    report_id SERIAL PRIMARY KEY,
    reporter_id INT NOT NULL,
    reported_user_id INT NOT NULL,
    reason TEXT NOT NULL,
    reported_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_reports_reporter FOREIGN KEY (reporter_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_reports_reported FOREIGN KEY (reported_user_id)
        REFERENCES users(user_id)
);

CREATE TABLE blocks (
    block_id SERIAL PRIMARY KEY,
    blocker_id INT NOT NULL,
    blocked_user_id INT NOT NULL,
    blocked_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_blocks_blocker FOREIGN KEY (blocker_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_blocks_blocked FOREIGN KEY (blocked_user_id)
        REFERENCES users(user_id)
);


-- SQL INSERT Commands for Dating App Schema with derived usernames and emails

-- Data for 'users' table (100 users with derived usernames and emails)
-- Usernames are first_name + first_character_of_last_name (lowercase)
-- Emails are first_name.last_name@example.com (lowercase)
INSERT INTO users (username, email, password_hash, created_at) VALUES
('alices', 'alice.smith@gmail.com', 'hashed_password_1', '2023-01-01 08:00:00'),
('bobj', 'bob.johnson@yahoo.com', 'hashed_password_2', '2023-01-12 09:30:00'),
('charlieb', 'charlie.brown@outlook.com', 'hashed_password_3', '2023-01-23 11:05:00'),
('dianap', 'diana.prince@gmail.com', 'hashed_password_4', '2023-02-03 12:35:00'),
('eveh', 'eve.adams@yahoo.com', 'hashed_password_5', '2023-02-14 14:10:00'),
('frankw', 'frank.white@outlook.com', 'hashed_password_6', '2023-02-25 15:40:00'),
('gracet', 'grace.taylor@gmail.com', 'hashed_password_7', '2023-03-08 17:15:00'),
('henrym', 'henry.moore@yahoo.com', 'hashed_password_8', '2023-03-19 18:45:00'),
('ivyk', 'ivy.king@outlook.com', 'hashed_password_9', '2023-03-30 20:20:00'),
('jackg', 'jack.green@gmail.com', 'hashed_password_10', '2023-04-10 21:50:00'),
('karenh', 'karen.hall@yahoo.com', 'hashed_password_11', '2023-04-21 23:25:00'),
('liama', 'liam.allen@outlook.com', 'hashed_password_12', '2023-05-03 00:55:00'),
('miay', 'mia.young@gmail.com', 'hashed_password_13', '2023-05-14 02:30:00'),
('noahw', 'noah.wright@yahoo.com', 'hashed_password_14', '2023-05-25 04:00:00'),
('olivias', 'olivia.scott@outlook.com', 'hashed_password_15', '2023-06-05 05:35:00'),
('peterh', 'peter.hill@gmail.com', 'hashed_password_16', '2023-06-16 07:05:00'),
('quinnc', 'quinn.clark@yahoo.com', 'hashed_password_17', '2023-06-27 08:40:00'),
('ryanl', 'ryan.lewis@outlook.com', 'hashed_password_18', '2023-07-08 10:10:00'),
('sophiar', 'sophia.roberts@gmail.com', 'hashed_password_19', '2023-07-19 11:45:00'),
('tomw', 'tom.walker@yahoo.com', 'hashed_password_20', '2023-07-30 13:15:00'),
('umah', 'uma.harris@outlook.com', 'hashed_password_21', '2023-08-10 14:50:00'),
('victorm', 'victor.martin@gmail.com', 'hashed_password_22', '2023-08-21 16:20:00'),
('wendyt', 'wendy.thompson@yahoo.com', 'hashed_password_23', '2023-09-01 17:55:00'),
('xavierg', 'xavier.garcia@outlook.com', 'hashed_password_24', '2023-09-12 19:25:00'),
('yaram', 'yara.martinez@gmail.com', 'hashed_password_25', '2023-09-23 21:00:00'),
('zaner', 'zane.robinson@yahoo.com', 'hashed_password_26', '2023-10-04 22:30:00'),
('amys', 'amy.clark@outlook.com', 'hashed_password_27', '2023-10-16 00:05:00'),
('benr', 'ben.rodriguez@gmail.com', 'hashed_password_28', '2023-10-27 01:35:00'),
('chloel', 'chloe.lewis@yahoo.com', 'hashed_password_29', '2023-11-07 03:10:00'),
('danield', 'daniel.lee@outlook.com', 'hashed_password_30', '2023-11-18 04:40:00'),
('ellaw', 'ella.white@gmail.com', 'hashed_password_31', '2023-11-29 06:15:00'),
('finnha', 'finn.harris@yahoo.com', 'hashed_password_32', '2023-12-10 07:45:00'),
('gracek', 'grace.king@outlook.com', 'hashed_password_33', '2023-12-21 09:20:00'),
('harryw', 'harry.wright@gmail.com', 'hashed_password_34', '2024-01-01 10:50:00'),
('islah', 'isla.scott@yahoo.com', 'hashed_password_35', '2024-01-12 12:25:00'),
('jakeh', 'jake.hill@outlook.com', 'hashed_password_36', '2024-01-23 13:55:00'),
('katiec', 'katie.clark@gmail.com', 'hashed_password_37', '2024-02-03 15:30:00'),
('leol', 'leo.lewis@yahoo.com', 'hashed_password_38', '2024-02-14 17:00:00'),
('monar', 'mona.roberts@outlook.com', 'hashed_password_39', '2024-02-25 18:35:00'),
('noahw_2', 'noah.walker@gmail.com', 'hashed_password_40', '2024-03-07 20:05:00'),
('oscarh', 'oscar.harris@yahoo.com', 'hashed_password_41', '2024-03-18 21:40:00'),
('pennym', 'penny.martin@outlook.com', 'hashed_password_42', '2024-03-29 23:10:00'),
('quinnth', 'quinn.thompson@gmail.com', 'hashed_password_43', '2024-04-10 00:45:00'),
('rachelg', 'rachel.garcia@yahoo.com', 'hashed_password_44', '2024-04-21 02:15:00'),
('samm', 'sam.martinez@outlook.com', 'hashed_password_45', '2024-05-02 03:50:00'),
('tinah', 'tina.robinson@gmail.com', 'hashed_password_46', '2024-05-13 05:20:00'),
('ulyssesc', 'ulysses.clark@yahoo.com', 'hashed_password_47', '2024-05-24 06:55:00'),
('violetro', 'violet.rodriguez@outlook.com', 'hashed_password_48', '2024-06-04 08:25:00'),
('williaml', 'william.lewis@gmail.com', 'hashed_password_49', '2024-06-15 10:00:00'),
('xenal', 'xena.lee@yahoo.com', 'hashed_password_50', '2024-06-26 11:30:00'),
('yaelw', 'yael.white@outlook.com', 'hashed_password_51', '2024-07-07 13:05:00'),
('zackh', 'zack.harris@gmail.com', 'hashed_password_52', '2024-07-18 14:35:00'),
('avaa', 'ava.king@yahoo.com', 'hashed_password_53', '2024-07-29 16:10:00'),
('blakew', 'blake.wright@outlook.com', 'hashed_password_54', '2024-08-09 17:40:00'),
('chloes', 'chloe.scott@gmail.com', 'hashed_password_55', '2024-08-20 19:15:00'),
('davidh', 'david.hill@yahoo.com', 'hashed_password_56', '2024-08-31 20:45:00'),
('emilyc', 'emily.clark@outlook.com', 'hashed_password_57', '2024-09-11 22:20:00'),
('frankl', 'frank.lewis@gmail.com', 'hashed_password_58', '2024-09-22 23:50:00'),
('gracer', 'grace.roberts@yahoo.com', 'hashed_password_59', '2024-10-04 01:25:00'),
('henryw', 'henry.walker@outlook.com', 'hashed_password_60', '2024-10-15 02:55:00'),
('isabellah', 'isabella.harris@gmail.com', 'hashed_password_61', '2024-10-26 04:30:00'),
('jackm', 'jack.martin@yahoo.com', 'hashed_password_62', '2024-11-06 06:00:00'),
('jessicat', 'jessica.thompson@outlook.com', 'hashed_password_63', '2024-11-17 07:35:00'),
('keving', 'kevin.garcia@gmail.com', 'hashed_password_64', '2024-11-28 09:05:00'),
('lilyl', 'lily.martinez@yahoo.com', 'hashed_password_65', '2024-12-09 10:40:00'),
('michaelr', 'michael.robinson@outlook.com', 'hashed_password_66', '2024-12-20 12:10:00'),
('nataliec', 'natalie.clark@gmail.com', 'hashed_password_67', '2024-12-31 13:45:00'),
('oliverr', 'oliver.rodriguez@yahoo.com', 'hashed_password_68', '2025-01-11 15:15:00'),
('penelopel', 'penelope.lewis@outlook.com', 'hashed_password_69', '2025-01-22 16:50:00'),
('quentinl', 'quentin.lee@gmail.com', 'hashed_password_70', '2025-02-02 18:20:00'),
('rebeccaw', 'rebecca.white@yahoo.com', 'hashed_password_71', '2025-02-13 19:55:00'),
('samuelh', 'samuel.harris@outlook.com', 'hashed_password_72', '2025-02-24 21:25:00'),
('sarahk', 'sarah.king@gmail.com', 'hashed_password_73', '2025-03-07 23:00:00'),
('thomast', 'thomas.wright@yahoo.com', 'hashed_password_74', '2025-03-18 00:30:00'),
('victorias', 'victoria.scott@outlook.com', 'hashed_password_75', '2025-03-29 02:05:00'),
('walterh', 'walter.hill@gmail.com', 'hashed_password_76', '2025-04-09 03:35:00'),
('xeniac', 'xenia.clark@yahoo.com', 'hashed_password_77', '2025-04-20 05:10:00'),
('yannickl', 'yannick.lewis@outlook.com', 'hashed_password_78', '2025-05-01 06:40:00'),
('zoer', 'zoe.roberts@gmail.com', 'hashed_password_79', '2025-05-12 08:15:00'),
('adamw', 'adam.walker@yahoo.com', 'hashed_password_80', '2025-05-23 09:45:00'),
('brendah', 'brenda.harris@outlook.com', 'hashed_password_81', '2025-06-03 11:20:00'),
('chrism', 'chris.martin@gmail.com', 'hashed_password_82', '2025-06-14 12:50:00'),
('danat', 'dana.thompson@yahoo.com', 'hashed_password_83', '2025-06-25 14:25:00'),
('ericg', 'eric.garcia@outlook.com', 'hashed_password_84', '2025-07-06 15:55:00'),
('fionam', 'fiona.martinez@gmail.com', 'hashed_password_85', '2025-07-17 17:30:00'),
('georger', 'george.robinson@yahoo.com', 'hashed_password_86', '2025-07-28 19:00:00'),
('hannahc', 'hannah.clark@outlook.com', 'hashed_password_87', '2025-08-08 20:35:00'),
('iani', 'ian.rodriguez@gmail.com', 'hashed_password_88', '2025-08-19 22:05:00'),
('julial', 'julia.lewis@yahoo.com', 'hashed_password_89', '2025-08-31 23:40:00'),
('kylel', 'kyle.lee@outlook.com', 'hashed_password_90', '2025-09-11 01:10:00'),
('lauraw', 'laura.white@gmail.com', 'hashed_password_91', '2025-09-22 02:45:00'),
('markh', 'mark.harris@yahoo.com', 'hashed_password_92', '2025-10-03 04:15:00'),
('nancyk', 'nancy.king@outlook.com', 'hashed_password_93', '2025-10-14 05:50:00'),
('owenw', 'owen.wright@gmail.com', 'hashed_password_94', '2025-10-25 07:20:00'),
('pamelas', 'pamela.scott@yahoo.com', 'hashed_password_95', '2025-11-05 08:55:00'),
('quincyh', 'quincy.hill@outlook.com', 'hashed_password_96', '2025-11-16 10:25:00'),
('rosec', 'rose.clark@gmail.com', 'hashed_password_97', '2025-11-27 12:00:00'),
('stevel', 'steve.lewis@yahoo.com', 'hashed_password_98', '2025-12-09 16:50:00'),
('tracyr', 'tracy.roberts@outlook.com', 'hashed_password_99', '2025-12-17 18:25:00'),
('ursulaw', 'ursula.walker@gmail.com', 'hashed_password_100', '2025-12-18 20:00:00');


INSERT INTO profiles (user_id, first_name, last_name, birth_date, gender, bio, latitude, longitude, location_name, profile_photo_url, last_modified_at) VALUES
(1, 'Alice', 'Smith', '1997-02-02', 'F', 'Loves hiking and reading.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User1', '2023-01-08 08:00:00'),
(2, 'Bob', 'Johnson', '1988-03-03', 'M', 'Into coding and gaming.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User2', '2023-01-20 12:30:00'),
(3, 'Charlie', 'Brown', '1989-04-04', 'F', 'Coffee enthusiast.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User3', '2023-02-01 17:05:00'),
(4, 'Diana', 'Prince', '1990-05-05', 'M', 'Adventurous soul.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User4', '2023-02-14 21:35:00'),
(5, 'Eve', 'Adams', '1991-06-06', 'F', 'Art lover.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User5', '2023-02-28 02:10:00'),
(6, 'Frank', 'White', '1992-07-07', 'M', 'Musician and foodie.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User6', '2023-03-13 06:40:00'),
(7, 'Grace', 'Taylor', '1993-08-08', 'F', 'Passionate about travel.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User7', '2023-03-26 11:15:00'),
(8, 'Henry', 'Moore', '1994-09-09', 'M', 'Fitness enthusiast.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User8', '2023-04-09 15:45:00'),
(9, 'Ivy', 'King', '1995-10-10', 'F', 'Bookworm and cat lover.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User9', '2023-04-22 20:20:00'),
(10, 'Jack', 'Green', '1986-11-11', 'M', 'Outdoor adventures.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User10', '2023-05-06 00:50:00'),
(11, 'Karen', 'Hall', '1987-12-12', 'F', 'Loves cooking and baking.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User11', '2023-05-19 05:25:00'),
(12, 'Liam', 'Allen', '1988-01-13', 'M', 'Tech enthusiast.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User12', '2023-06-01 09:55:00'),
(13, 'Mia', 'Young', '1989-02-14', 'F', 'Yoga and meditation.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User13', '2023-06-14 14:30:00'),
(14, 'Noah', 'Wright', '1990-03-15', 'M', 'Sports fanatic.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User14', '2023-06-28 19:00:00'),
(15, 'Olivia', 'Scott', '1991-04-16', 'F', 'Photography hobbyist.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User15', '2023-07-12 23:35:00'),
(16, 'Peter', 'Hill', '1992-05-17', 'M', 'Loves board games.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User16', '2023-07-27 04:05:00'),
(17, 'Quinn', 'Clark', '1993-06-18', 'F', 'Enjoys volunteering.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User17', '2023-08-10 08:40:00'),
(18, 'Ryan', 'Lewis', '1994-07-19', 'M', 'Avid traveler.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User18', '2023-08-23 13:10:00'),
(19, 'Sophia', 'Roberts', '1995-08-20', 'F', 'Loves classical music.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User19', '2023-09-06 17:45:00'),
(20, 'Tom', 'Walker', '1986-09-21', 'M', 'Gardening enthusiast.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User20', '2023-09-20 22:15:00'),
(21, 'Uma', 'Harris', '1987-10-22', 'F', 'Enjoys painting.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User21', '2023-10-04 02:50:00'),
(22, 'Victor', 'Martin', '1988-11-23', 'M', 'Loves learning new languages.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User22', '2023-10-17 07:20:00'),
(23, 'Wendy', 'Thompson', '1989-12-24', 'F', 'Enjoys playing piano.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User23', '2023-10-30 11:55:00'),
(24, 'Xavier', 'Garcia', '1990-01-25', 'M', 'Film buff.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User24', '2023-11-12 16:25:00'),
(25, 'Yara', 'Martinez', '1991-02-26', 'F', 'Loves dancing.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User25', '2023-11-26 21:00:00'),
(26, 'Zane', 'Robinson', '1992-03-27', 'M', 'Enjoys photography.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User26', '2023-12-10 01:30:00'),
(27, 'Amy', 'Clark', '1993-04-28', 'F', 'Passionate about science.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User27', '2023-12-23 06:05:00'),
(28, 'Ben', 'Rodriguez', '1994-05-01', 'M', 'Loves playing guitar.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User28', '2024-01-05 10:35:00'),
(29, 'Chloe', 'Lewis', '1995-06-02', 'F', 'Enjoys writing.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User29', '2024-01-19 15:10:00'),
(30, 'Daniel', 'Lee', '1986-07-03', 'M', 'Avid cyclist.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User30', '2024-02-02 19:40:00'),
(31, 'Ella', 'White', '1987-08-04', 'F', 'Loves hiking and reading.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User31', '2024-02-17 00:15:00'),
(32, 'Finn', 'Harris', '1988-09-05', 'M', 'Into coding and gaming.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User32', '2024-03-02 04:45:00'),
(33, 'Grace', 'King', '1989-10-06', 'F', 'Coffee enthusiast.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User33', '2024-03-15 09:20:00'),
(34, 'Harry', 'Wright', '1990-11-07', 'M', 'Adventurous soul.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User34', '2024-03-29 13:50:00'),
(35, 'Isla', 'Scott', '1991-12-08', 'F', 'Art lover.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User35', '2024-04-13 18:25:00'),
(36, 'Jake', 'Hill', '1992-01-09', 'M', 'Musician and foodie.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User36', '2024-04-27 22:55:00'),
(37, 'Katie', 'Clark', '1993-02-10', 'F', 'Passionate about travel.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User37', '2024-05-11 03:30:00'),
(38, 'Leo', 'Lewis', '1994-03-11', 'M', 'Fitness enthusiast.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User38', '2024-05-25 08:00:00'),
(39, 'Mona', 'Roberts', '1995-04-12', 'F', 'Bookworm and cat lover.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User39', '2024-06-08 12:35:00'),
(40, 'Noah', 'Walker', '1986-05-13', 'M', 'Outdoor adventures.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User40', '2024-06-22 17:05:00'),
(41, 'Oscar', 'Harris', '1987-06-14', 'F', 'Loves cooking and baking.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User41', '2024-07-06 21:40:00'),
(42, 'Penny', 'Martin', '1988-07-15', 'M', 'Tech enthusiast.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User42', '2024-07-20 02:10:00'),
(43, 'Quinn', 'Thompson', '1989-08-16', 'F', 'Yoga and meditation.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User43', '2024-08-03 06:45:00'),
(44, 'Rachel', 'Garcia', '1990-09-17', 'M', 'Sports fanatic.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User44', '2024-08-17 11:15:00'),
(45, 'Sam', 'Martinez', '1991-10-18', 'F', 'Photography hobbyist.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User45', '2024-08-31 15:50:00'),
(46, 'Tina', 'Robinson', '1992-11-19', 'M', 'Loves board games.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User46', '2024-09-14 20:20:00'),
(47, 'Ulysses', 'Clark', '1993-12-20', 'F', 'Enjoys volunteering.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User47', '2024-09-29 00:55:00'),
(48, 'Violet', 'Rodriguez', '1994-01-21', 'M', 'Avid traveler.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User48', '2024-10-13 05:25:00'),
(49, 'William', 'Lewis', '1995-02-22', 'F', 'Loves classical music.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User49', '2024-10-27 10:00:00'),
(50, 'Xena', 'Lee', '1986-03-23', 'M', 'Gardening enthusiast.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User50', '2024-11-10 14:30:00'),
(51, 'Yael', 'White', '1987-04-24', 'F', 'Enjoys painting.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User51', '2024-11-24 19:05:00'),
(52, 'Zack', 'Harris', '1988-05-25', 'M', 'Loves learning new languages.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User52', '2024-12-08 23:35:00'),
(53, 'Ava', 'King', '1989-06-26', 'F', 'Enjoys playing piano.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User53', '2024-12-23 04:10:00'),
(54, 'Blake', 'Wright', '1990-07-27', 'M', 'Film buff.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User54', '2025-01-06 08:40:00'),
(55, 'Chloe', 'Scott', '1991-08-28', 'F', 'Loves dancing.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User55', '2025-01-20 13:15:00'),
(56, 'David', 'Hill', '1992-09-01', 'M', 'Enjoys photography.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User56', '2025-02-03 17:45:00'),
(57, 'Emily', 'Clark', '1993-10-02', 'F', 'Passionate about science.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User57', '2025-02-17 22:20:00'),
(58, 'Frank', 'Lewis', '1994-11-03', 'M', 'Loves playing guitar.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User58', '2025-03-04 02:50:00'),
(59, 'Grace', 'Roberts', '1995-12-04', 'F', 'Enjoys writing.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User59', '2025-03-18 07:25:00'),
(60, 'Henry', 'Walker', '1986-01-05', 'M', 'Avid cyclist.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User60', '2025-04-01 11:55:00'),
(61, 'Isabella', 'Harris', '1987-02-06', 'F', 'Loves hiking and reading.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User61', '2025-04-16 16:30:00'),
(62, 'Jack', 'Martin', '1988-03-07', 'M', 'Into coding and gaming.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User62', '2025-04-30 21:00:00'),
(63, 'Jessica', 'Thompson', '1989-04-08', 'F', 'Coffee enthusiast.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User63', '2025-05-15 01:35:00'),
(64, 'Kevin', 'Garcia', '1990-05-09', 'M', 'Adventurous soul.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User64', '2025-05-29 06:05:00'),
(65, 'Lily', 'Martinez', '1991-06-10', 'F', 'Art lover.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User65', '2025-06-12 10:40:00'),
(66, 'Michael', 'Robinson', '1992-07-11', 'M', 'Musician and foodie.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User66', '2025-06-26 15:10:00'),
(67, 'Natalie', 'Clark', '1993-08-12', 'F', 'Passionate about travel.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User67', '2025-07-10 19:45:00'),
(68, 'Oliver', 'Rodriguez', '1994-09-13', 'M', 'Fitness enthusiast.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User68', '2025-07-25 00:15:00'),
(69, 'Penelope', 'Lewis', '1995-10-14', 'F', 'Bookworm and cat lover.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User69', '2025-08-08 04:50:00'),
(70, 'Quentin', 'Lee', '1986-11-15', 'M', 'Outdoor adventures.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User70', '2025-08-22 09:20:00'),
(71, 'Rebecca', 'White', '1987-12-16', 'F', 'Loves cooking and baking.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User71', '2025-09-05 13:55:00'),
(72, 'Samuel', 'Harris', '1988-01-17', 'M', 'Tech enthusiast.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User72', '2025-09-19 18:25:00'),
(73, 'Sarah', 'King', '1989-02-18', 'F', 'Yoga and meditation.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User73', '2025-10-04 23:00:00'),
(74, 'Thomas', 'Wright', '1990-03-19', 'M', 'Sports fanatic.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User74', '2025-10-19 03:30:00'),
(75, 'Victoria', 'Scott', '1991-04-20', 'F', 'Photography hobbyist.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User75', '2025-11-02 08:05:00'),
(76, 'Walter', 'Hill', '1992-05-21', 'M', 'Loves board games.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User76', '2025-11-16 12:35:00'),
(77, 'Xenia', 'Clark', '1993-06-22', 'F', 'Enjoys volunteering.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User77', '2025-11-30 17:10:00'),
(78, 'Yannick', 'Lewis', '1994-07-23', 'M', 'Avid traveler.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User78', '2025-12-15 21:40:00'),
(79, 'Zoe', 'Roberts', '1995-08-24', 'F', 'Loves classical music.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User79', '2025-12-23 19:50:00'),
(80, 'Adam', 'Walker', '1986-09-25', 'M', 'Gardening enthusiast.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User80', '2025-12-31 20:00:00'),
(81, 'Brenda', 'Harris', '1987-10-26', 'F', 'Enjoys painting.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User81', '2025-12-31 20:00:00'),
(82, 'Chris', 'Martin', '1988-11-27', 'M', 'Loves learning new languages.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User82', '2025-12-31 20:00:00'),
(83, 'Dana', 'Thompson', '1989-12-28', 'F', 'Enjoys playing piano.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User83', '2025-12-31 20:00:00'),
(84, 'Eric', 'Garcia', '1990-01-01', 'M', 'Film buff.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User84', '2025-12-31 20:00:00'),
(85, 'Fiona', 'Martinez', '1991-02-02', 'F', 'Loves dancing.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User85', '2025-12-31 20:00:00'),
(86, 'George', 'Robinson', '1992-03-03', 'M', 'Enjoys photography.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User86', '2025-12-31 20:00:00'),
(87, 'Hannah', 'Clark', '1993-04-04', 'F', 'Passionate about science.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User87', '2025-12-31 20:00:00'),
(88, 'Ian', 'Rodriguez', '1994-05-05', 'M', 'Loves playing guitar.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User88', '2025-12-31 20:00:00'),
(89, 'Julia', 'Lewis', '1995-06-06', 'F', 'Enjoys writing.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User89', '2025-12-31 20:00:00'),
(90, 'Kyle', 'Lee', '1986-07-07', 'M', 'Avid cyclist.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User90', '2025-12-31 20:00:00'),
(91, 'Laura', 'White', '1987-08-08', 'F', 'Loves hiking and reading.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User91', '2025-12-31 20:00:00'),
(92, 'Mark', 'Harris', '1988-09-09', 'M', 'Into coding and gaming.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User92', '2025-12-31 20:00:00'),
(93, 'Nancy', 'King', '1989-10-10', 'F', 'Coffee enthusiast.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User93', '2025-12-31 20:00:00'),
(94, 'Owen', 'Wright', '1990-11-11', 'M', 'Adventurous soul.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User94', '2025-12-31 20:00:00'),
(95, 'Pamela', 'Scott', '1991-12-12', 'F', 'Art lover.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User95', '2025-12-31 20:00:00'),
(96, 'Quincy', 'Hill', '1992-01-13', 'M', 'Musician and foodie.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User96', '2025-12-31 20:00:00'),
(97, 'Rose', 'Clark', '1993-02-14', 'F', 'Passionate about travel.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User97', '2025-12-31 20:00:00'),
(98, 'Steve', 'Lewis', '1994-03-15', 'M', 'Fitness enthusiast.', 31.8948, 34.8113, 'Rehovot', 'https://placehold.co/150x150/000/FFF?text=User98', '2025-12-31 20:00:00'),
(99, 'Tracy', 'Roberts', '1995-04-16', 'F', 'Bookworm and cat lover.', 31.7683, 35.2137, 'Jerusalem', 'https://placehold.co/150x150/000/FFF?text=User99', '2025-12-18 10:00:00'),
(100, 'Ursula', 'Walker', '1986-05-17', 'M', 'Outdoor adventures.', 32.0853, 34.7818, 'Tel Aviv', 'https://placehold.co/150x150/000/FFF?text=User100', '2025-12-18 20:00:00');


-- Data for 'photos' table
INSERT INTO photos (user_id, url, is_primary, uploaded_at) VALUES
(1, 'https://randomuser.me/api/portraits/men/1.jpg', 1, '2023-01-02 09:00:00'),
(1, 'https://randomuser.me/api/portraits/men/2.jpg', 0, '2023-01-13 04:51:05'),
(2, 'https://randomuser.me/api/portraits/women/2.jpg', 1, '2023-01-24 00:42:11'),
(3, 'https://randomuser.me/api/portraits/men/3.jpg', 1, '2023-02-03 20:33:16'),
(3, 'https://randomuser.me/api/portraits/men/4.jpg', 0, '2023-02-14 16:24:21'),
(4, 'https://randomuser.me/api/portraits/women/4.jpg', 1, '2023-02-25 12:15:27'),
(5, 'https://randomuser.me/api/portraits/men/5.jpg', 1, '2023-03-08 08:06:32'),
(6, 'https://randomuser.me/api/portraits/men/6.jpg', 1, '2023-03-19 03:57:38'),
(7, 'https://randomuser.me/api/portraits/men/7.jpg', 1, '2023-03-29 23:48:43'),
(8, 'https://randomuser.me/api/portraits/women/8.jpg', 1, '2023-04-09 19:39:48'),
(9, 'https://randomuser.me/api/portraits/men/9.jpg', 1, '2023-04-20 15:30:54'),
(10, 'https://randomuser.me/api/portraits/women/10.jpg', 1, '2023-05-01 11:21:59'),
(11, 'https://randomuser.me/api/portraits/men/11.jpg', 1, '2023-05-12 07:13:05'),
(12, 'https://randomuser.me/api/portraits/women/12.jpg', 1, '2023-05-23 03:04:10'),
(13, 'https://randomuser.me/api/portraits/men/13.jpg', 1, '2023-06-02 22:55:16'),
(14, 'https://randomuser.me/api/portraits/women/14.jpg', 1, '2023-06-13 18:46:21'),
(15, 'https://randomuser.me/api/portraits/men/15.jpg', 1, '2023-06-24 14:37:26'),
(16, 'https://randomuser.me/api/portraits/women/16.jpg', 1, '2023-07-05 10:28:32'),
(17, 'https://randomuser.me/api/portraits/men/17.jpg', 1, '2023-07-16 06:19:37'),
(18, 'https://randomuser.me/api/portraits/women/18.jpg', 1, '2023-07-27 02:10:43'),
(19, 'https://randomuser.me/api/portraits/men/19.jpg', 1, '2023-08-06 22:01:48'),
(20, 'https://randomuser.me/api/portraits/women/20.jpg', 1, '2023-08-17 17:52:54'),
(21, 'https://randomuser.me/api/portraits/men/21.jpg', 1, '2023-08-28 13:43:59'),
(22, 'https://randomuser.me/api/portraits/women/22.jpg', 1, '2023-09-08 09:35:04'),
(23, 'https://randomuser.me/api/portraits/men/23.jpg', 1, '2023-09-19 05:26:10'),
(24, 'https://randomuser.me/api/portraits/women/24.jpg', 1, '2023-09-30 01:17:15'),
(25, 'https://randomuser.me/api/portraits/men/25.jpg', 1, '2023-10-10 21:08:21'),
(26, 'https://randomuser.me/api/portraits/women/26.jpg', 1, '2023-10-21 16:59:26'),
(27, 'https://randomuser.me/api/portraits/men/27.jpg', 1, '2023-11-01 12:50:31'),
(28, 'https://randomuser.me/api/portraits/women/28.jpg', 1, '2023-11-12 08:41:37'),
(29, 'https://randomuser.me/api/portraits/men/29.jpg', 1, '2023-11-23 04:32:42'),
(30, 'https://randomuser.me/api/portraits/women/30.jpg', 1, '2023-12-04 00:23:47'),
(31, 'https://randomuser.me/api/portraits/men/31.jpg', 1, '2023-12-14 20:14:53'),
(32, 'https://randomuser.me/api/portraits/women/32.jpg', 1, '2023-12-25 16:05:58'),
(33, 'https://randomuser.me/api/portraits/men/33.jpg', 1, '2024-01-05 11:57:03'),
(34, 'https://randomuser.me/api/portraits/women/34.jpg', 1, '2024-01-16 07:48:09'),
(35, 'https://randomuser.me/api/portraits/men/35.jpg', 1, '2024-01-27 03:39:14'),
(36, 'https://randomuser.me/api/portraits/women/36.jpg', 1, '2024-02-06 23:30:20'),
(37, 'https://randomuser.me/api/portraits/men/37.jpg', 1, '2024-02-17 19:21:25'),
(38, 'https://randomuser.me/api/portraits/women/38.jpg', 1, '2024-02-28 15:12:30'),
(39, 'https://randomuser.me/api/portraits/men/39.jpg', 1, '2024-03-10 11:03:36'),
(40, 'https://randomuser.me/api/portraits/women/40.jpg', 1, '2024-03-21 06:54:41'),
(41, 'https://randomuser.me/api/portraits/men/41.jpg', 1, '2024-04-01 02:45:47'),
(42, 'https://randomuser.me/api/portraits/women/42.jpg', 1, '2024-04-11 22:36:52'),
(43, 'https://randomuser.me/api/portraits/men/43.jpg', 1, '2024-04-22 18:27:57'),
(44, 'https://randomuser.me/api/portraits/women/44.jpg', 1, '2024-05-03 14:19:03'),
(45, 'https://randomuser.me/api/portraits/men/45.jpg', 1, '2024-05-14 10:10:08'),
(46, 'https://randomuser.me/api/portraits/women/46.jpg', 1, '2024-05-25 06:01:13'),
(47, 'https://randomuser.me/api/portraits/men/47.jpg', 1, '2024-06-05 01:52:19'),
(48, 'https://randomuser.me/api/portraits/women/48.jpg', 1, '2024-06-15 21:43:24'),
(49, 'https://randomuser.me/api/portraits/men/49.jpg', 1, '2024-06-26 17:34:29'),
(50, 'https://randomuser.me/api/portraits/women/50.jpg', 1, '2024-07-07 13:25:35'),
(51, 'https://randomuser.me/api/portraits/men/51.jpg', 1, '2024-07-18 09:16:40'),
(52, 'https://randomuser.me/api/portraits/women/52.jpg', 1, '2024-07-29 05:07:46'),
(53, 'https://randomuser.me/api/portraits/men/53.jpg', 1, '2024-08-09 00:58:51'),
(54, 'https://randomuser.me/api/portraits/women/54.jpg', 1, '2024-08-19 20:49:56'),
(55, 'https://randomuser.me/api/portraits/men/55.jpg', 1, '2024-08-30 16:41:02'),
(56, 'https://randomuser.me/api/portraits/women/56.jpg', 1, '2024-09-10 12:32:07'),
(57, 'https://randomuser.me/api/portraits/men/57.jpg', 1, '2024-09-21 08:23:12'),
(58, 'https://randomuser.me/api/portraits/women/58.jpg', 1, '2024-10-02 04:14:18'),
(59, 'https://randomuser.me/api/portraits/men/59.jpg', 1, '2024-10-12 00:05:23'),
(60, 'https://randomuser.me/api/portraits/women/60.jpg', 1, '2024-10-22 19:56:28'),
(61, 'https://randomuser.me/api/portraits/men/61.jpg', 1, '2024-11-02 15:47:34'),
(62, 'https://randomuser.me/api/portraits/women/62.jpg', 1, '2024-11-13 11:38:39'),
(63, 'https://randomuser.me/api/portraits/men/63.jpg', 1, '2024-11-24 07:29:44'),
(64, 'https://randomuser.me/api/portraits/women/64.jpg', 1, '2024-12-05 03:20:50'),
(65, 'https://randomuser.me/api/portraits/men/65.jpg', 1, '2024-12-15 23:11:55'),
(66, 'https://randomuser.me/api/portraits/women/66.jpg', 1, '2024-12-26 19:03:00'),
(67, 'https://randomuser.me/api/portraits/men/67.jpg', 1, '2025-01-06 14:54:06'),
(68, 'https://randomuser.me/api/portraits/women/68.jpg', 1, '2025-01-17 10:45:11'),
(69, 'https://randomuser.me/api/portraits/men/69.jpg', 1, '2025-01-28 06:36:17'),
(70, 'https://randomuser.me/api/portraits/women/70.jpg', 1, '2025-02-08 02:27:22'),
(71, 'https://randomuser.me/api/portraits/men/71.jpg', 1, '2025-02-18 22:18:27'),
(72, 'https://randomuser.me/api/portraits/women/72.jpg', 1, '2025-03-01 18:09:33'),
(73, 'https://randomuser.me/api/portraits/men/73.jpg', 1, '2025-03-12 14:00:38'),
(74, 'https://randomuser.me/api/portraits/women/74.jpg', 1, '2025-03-23 09:51:43'),
(75, 'https://randomuser.me/api/portraits/men/75.jpg', 1, '2025-04-03 05:42:49'),
(76, 'https://randomuser.me/api/portraits/women/76.jpg', 1, '2025-04-14 01:33:54'),
(77, 'https://randomuser.me/api/portraits/men/77.jpg', 1, '2025-04-24 21:24:59'),
(78, 'https://randomuser.me/api/portraits/women/78.jpg', 1, '2025-05-05 17:16:05'),
(79, 'https://randomuser.me/api/portraits/men/79.jpg', 1, '2025-05-16 13:07:10'),
(80, 'https://randomuser.me/api/portraits/women/80.jpg', 1, '2025-05-27 08:58:16'),
(81, 'https://randomuser.me/api/portraits/men/81.jpg', 1, '2025-06-07 04:49:21'),
(82, 'https://randomuser.me/api/portraits/women/82.jpg', 1, '2025-06-18 00:40:26'),
(83, 'https://randomuser.me/api/portraits/men/83.jpg', 1, '2025-06-28 20:31:32'),
(84, 'https://randomuser.me/api/portraits/women/84.jpg', 1, '2025-07-09 16:22:37'),
(85, 'https://randomuser.me/api/portraits/men/85.jpg', 1, '2025-07-20 12:13:42'),
(86, 'https://randomuser.me/api/portraits/women/86.jpg', 1, '2025-07-31 08:04:48'),
(87, 'https://randomuser.me/api/portraits/men/87.jpg', 1, '2025-08-11 03:55:53'),
(88, 'https://randomuser.me/api/portraits/women/88.jpg', 1, '2025-08-21 23:46:58'),
(89, 'https://randomuser.me/api/portraits/men/89.jpg', 1, '2025-09-01 19:38:04'),
(90, 'https://randomuser.me/api/portraits/women/90.jpg', 1, '2025-09-12 15:29:09'),
(91, 'https://randomuser.me/api/portraits/men/91.jpg', 1, '2025-09-23 11:20:14'),
(92, 'https://randomuser.me/api/portraits/women/92.jpg', 1, '2025-10-04 07:11:20'),
(93, 'https://randomuser.me/api/portraits/men/93.jpg', 1, '2025-10-15 03:02:25'),
(94, 'https://randomuser.me/api/portraits/women/94.jpg', 1, '2025-10-25 22:53:30'),
(95, 'https://randomuser.me/api/portraits/men/95.jpg', 1, '2025-11-05 18:44:36'),
(96, 'https://randomuser.me/api/portraits/women/96.jpg', 1, '2025-11-16 14:35:41'),
(97, 'https://randomuser.me/api/portraits/men/97.jpg', 1, '2025-11-28 10:26:44'),
(98, 'https://randomuser.me/api/portraits/women/98.jpg', 1, '2025-12-09 06:17:49'),
(99, 'https://randomuser.me/api/portraits/men/99.jpg', 1, '2025-12-20 02:08:55'),
(100, 'https://randomuser.me/api/portraits/women/0.jpg', 1, '2025-12-30 22:00:00');



-- Data for 'user_preferences' table (100 preferences)
-- min_age/max_age ranges vary (not always 10), max_distance_km randomized 1-50
INSERT INTO user_preferences (user_id, preferred_gender, min_age, max_age, max_distance_km) VALUES
(1, 'B', 32, 33, 48),
(2, 'F', 26, 35, 15),
(3, 'F', 23, 33, 44),
(4, 'M', 20, 36, 3),
(5, 'M', 18, 26, 15),
(6, 'F', 24, 43, 2),
(7, 'M', 23, 37, 36),
(8, 'F', 25, 37, 46),
(9, 'M', 18, 24, 45),
(10, 'F', 22, 34, 29),
(11, 'M', 30, 47, 1),
(12, 'F', 22, 32, 49),
(13, 'F', 23, 29, 28),
(14, 'M', 26, 35, 18),
(15, 'M', 33, 45, 1),
(16, 'F', 32, 46, 8),
(17, 'M', 30, 37, 36),
(18, 'F', 27, 43, 40),
(19, 'M', 31, 37, 24),
(20, 'F', 33, 39, 23),
(21, 'M', 32, 43, 3),
(22, 'F', 21, 34, 2),
(23, 'F', 18, 34, 27),
(24, 'M', 24, 38, 5),
(25, 'M', 25, 36, 16),
(26, 'F', 25, 37, 36),
(27, 'M', 26, 37, 10),
(28, 'F', 18, 28, 49),
(29, 'M', 25, 35, 22),
(30, 'F', 24, 38, 7),
(31, 'M', 26, 40, 4),
(32, 'F', 18, 32, 46),
(33, 'F', 20, 36, 4),
(34, 'M', 30, 42, 26),
(35, 'M', 22, 34, 25),
(36, 'F', 29, 44, 9),
(37, 'M', 23, 39, 36),
(38, 'F', 18, 25, 36),
(39, 'M', 19, 37, 21),
(40, 'F', 18, 31, 46),
(41, 'M', 23, 33, 36),
(42, 'F', 21, 29, 49),
(43, 'F', 31, 37, 50),
(44, 'M', 28, 41, 24),
(45, 'M', 24, 41, 2),
(46, 'F', 30, 47, 10),
(47, 'M', 19, 36, 29),
(48, 'F', 21, 30, 15),
(49, 'M', 18, 27, 13),
(50, 'F', 22, 38, 30),
(51, 'M', 21, 36, 14),
(52, 'F', 19, 29, 5),
(53, 'F', 27, 42, 41),
(54, 'M', 32, 47, 34),
(55, 'M', 24, 35, 16),
(56, 'F', 23, 41, 16),
(57, 'M', 29, 38, 43),
(58, 'F', 24, 35, 17),
(59, 'M', 19, 25, 20),
(60, 'F', 18, 33, 31),
(61, 'M', 29, 44, 44),
(62, 'F', 18, 31, 32),
(63, 'F', 32, 48, 14),
(64, 'M', 25, 40, 6),
(65, 'M', 29, 41, 49),
(66, 'F', 32, 45, 21),
(67, 'M', 25, 35, 36),
(68, 'F', 20, 36, 35),
(69, 'M', 18, 34, 44),
(70, 'F', 32, 50, 38),
(71, 'M', 25, 39, 18),
(72, 'F', 33, 50, 21),
(73, 'F', 20, 35, 23),
(74, 'M', 29, 37, 47),
(75, 'M', 29, 44, 3),
(76, 'F', 30, 44, 10),
(77, 'M', 20, 26, 50),
(78, 'F', 30, 39, 49),
(79, 'M', 31, 49, 34),
(80, 'F', 33, 51, 22),
(81, 'M', 32, 43, 40),
(82, 'F', 25, 36, 9),
(83, 'F', 19, 34, 2),
(84, 'M', 19, 30, 47),
(85, 'M', 25, 39, 44),
(86, 'F', 19, 35, 23),
(87, 'M', 24, 39, 31),
(88, 'F', 24, 30, 22),
(89, 'M', 23, 41, 44),
(90, 'F', 23, 36, 46),
(91, 'M', 29, 46, 29),
(92, 'F', 18, 32, 3),
(93, 'F', 22, 34, 8),
(94, 'M', 31, 42, 15),
(95, 'M', 18, 24, 13),
(96, 'F', 21, 34, 26),
(97, 'M', 32, 47, 3),
(98, 'F', 30, 36, 25),
(99, 'M', 26, 44, 30),
(100, 'F', 27, 39, 45);

-- Likes with realistic distribution
-- Data for 'matches' table (based on mutual likes)
INSERT INTO swipes (swiper_id, swiped_id, created_at) VALUES
-- very popular users
(12, 1, '2023-02-14 18:05:00'),
(20, 1, '2023-03-22 09:10:00'),
(25, 1, '2023-05-05 21:15:00'),
(30, 1, '2023-06-19 07:20:00'),
(2, 5,  '2023-08-03 12:30:00'),
(6, 5,  '2023-09-27 19:35:00'),

-- moderately popular users
(3, 2, '2023-10-11 08:10:00'),
(4, 2, '2023-11-24 14:05:00'),
(7, 2, '2023-12-28 22:10:00'),
(2, 3, '2024-01-09 11:15:00'), -- mutual

-- some random one-sided likes
(8, 6,  '2024-01-22 16:20:00'),
(9, 7,  '2024-02-10 09:25:00'),
(10, 8, '2024-02-28 13:30:00'),
(11, 9, '2024-03-17 20:35:00'),

-- mutual pairs

-- mutual pair: 1 <-> 3
(1, 3,  '2024-04-06 18:42:00'),
(3, 1,  '2024-04-08 07:48:00'),

-- mutual pair: 1 <-> 3
(1, 5,  '2024-04-20 21:55:00'),
(5, 1,  '2023-01-08 10:00:00'),


-- mutual pair: 13 <-> 14
(13, 14, '2024-05-03 11:40:00'),
(14, 13, '2024-05-03 11:45:00'),

-- mutual pair: 15 <-> 16
(15, 16, '2024-06-12 19:50:00'),
(16, 15, '2024-06-13 07:55:00'),


-- mutual pair: 4 <-> 7
(4, 7,  '2023-02-20 19:10:00'),
(7, 4,  '2023-02-21 08:05:00'),

-- mutual pair: 6 <-> 8
(6, 8,  '2023-05-14 12:30:00'),
(8, 6,  '2023-05-14 13:05:00'),

-- mutual pair: 9 <-> 11
(9, 11, '2023-08-07 21:40:00'),
(11, 9, '2023-08-08 07:15:00'),

-- mutual pair: 10 <-> 13
(10, 13,'2023-11-19 18:00:00'),
(13, 10,'2023-11-20 09:25:00'),

-- mutual pair: 17 <-> 19
(17, 19,'2024-02-03 14:10:00'),
(19, 17,'2024-02-03 16:45:00'),

-- mutual pair: 26 <-> 28
(26, 28,'2024-04-18 10:05:00'),
(28, 26,'2024-04-18 10:40:00'),

-- mutual pair: 30 <-> 34
(30, 34,'2024-07-26 22:05:00'),
(34, 30,'2024-07-27 08:20:00'),

-- mutual pair: 36 <-> 38
(36, 38,'2024-10-09 13:15:00'),
(38, 36,'2024-10-09 14:05:00'),

-- mutual pair: 40 <-> 44
(40, 44,'2025-01-15 17:30:00'),
(44, 40,'2025-01-16 09:10:00'),

-- mutual pair: 46 <-> 48
(46, 48,'2025-03-28 20:45:00'),
(48, 46,'2025-03-29 07:05:00'),

-- mutual pair: 58 <-> 60
(58, 60,'2025-06-11 11:55:00'),
(60, 58,'2025-06-11 12:40:00'),

-- mutual pair: 70 <-> 72
(70, 72,'2025-11-08 18:25:00'),
(72, 70,'2025-11-09 10:15:00'),

-- less popular users (few likes)
(17, 18, '2024-07-02 12:00:00'),
(19, 20, '2024-07-18 12:05:00'),

-- some scattered mutual likes
(21, 22, '2024-08-09 12:10:00'),
(22, 21, '2024-08-09 12:15:00'),
(23, 24, '2024-09-05 12:20:00'),
(24, 23, '2024-09-05 12:25:00'),

-- more likes for popular users
(1, 12, '2024-10-12 12:30:00'),
(3, 12, '2024-10-13 12:35:00'),
(5, 12, '2024-10-14 12:40:00'),
(8, 12, '2024-10-15 12:45:00'),

-- many other scattered likes to fill 100 users realistically
(26, 27, '2024-11-02 13:00:00'),
(28, 29, '2024-11-10 13:05:00'),
(30, 31, '2024-11-18 13:10:00'),
(32, 33, '2024-11-26 13:15:00'),
(34, 35, '2024-12-04 13:20:00'),
(36, 37, '2024-12-12 13:25:00'),
(38, 39, '2025-01-03 13:30:00'),
(40, 41, '2025-01-11 13:35:00'),
(42, 43, '2025-01-19 13:40:00'),
(44, 45, '2025-01-27 13:45:00'),
(46, 47, '2025-02-04 13:50:00'),
(48, 49, '2025-02-12 13:55:00'),
(50, 51, '2025-02-20 14:00:00'),
(52, 53, '2025-02-28 14:05:00'),
(54, 55, '2025-03-08 14:10:00'),
(56, 57, '2025-03-16 14:15:00'),
(58, 59, '2025-03-24 14:20:00'),
(60, 61, '2025-04-01 14:25:00'),
(62, 63, '2025-04-09 14:30:00'),
(64, 65, '2025-04-17 14:35:00'),
(66, 67, '2025-04-25 14:40:00'),
(68, 69, '2025-05-03 14:45:00'),
(70, 71, '2025-05-11 14:50:00'),
(72, 73, '2025-05-19 14:55:00'),
(74, 75, '2025-05-27 15:00:00'),
(76, 77, '2025-06-04 15:05:00'),
(78, 79, '2025-06-12 15:10:00'),
(80, 81, '2025-06-20 15:15:00'),
(82, 83, '2025-06-28 15:20:00'),
(84, 85, '2025-07-06 15:25:00'),
(86, 87, '2025-07-14 15:30:00'),
(88, 89, '2025-07-22 15:35:00'),
(90, 91, '2025-07-30 15:40:00'),
(92, 93, '2025-09-05 15:45:00'),
(94, 95, '2025-09-18 15:50:00'),
(96, 97, '2025-10-04 15:55:00'),
(98, 99, '2025-11-12 16:00:00'),
(100, 1, '2025-12-27 16:05:00'); -- less popular like


-- Data for 'matches' table (based on mutual likes)
INSERT INTO matches (user1_id, user2_id, matched_at) VALUES
(1, 5,  '2024-04-21 09:15:00'),
(1, 3,  '2024-04-08 08:05:00'),
(2, 3,  '2024-01-09 11:30:00'),
(15, 16,'2024-06-13 08:10:00'),
(21, 22,'2024-08-09 12:20:00'),
(23, 24,'2024-09-05 12:30:00'),
(4, 7,   '2023-02-21 08:10:00'),
(6, 8,   '2023-05-14 13:10:00'),
(9, 11,  '2023-08-08 07:20:00'),
(10, 13, '2023-11-20 09:30:00'),
(17, 19, '2024-02-03 16:50:00'),
(26, 28, '2024-04-18 10:45:00'),
(30, 34, '2024-07-27 08:25:00'),
(36, 38, '2024-10-09 14:10:00'),
(40, 44, '2025-01-16 09:15:00'),
(46, 48, '2025-03-29 07:10:00'),
(58, 60, '2025-06-11 12:45:00'),
(70, 72, '2025-11-09 10:20:00');


-- Data for 'messages' table (example messages for matches)
-- Dates spread across Jan 2023 to Dec 2025
-- Some matches intentionally left with no messages
INSERT INTO messages (match_id, sender_id, content, sent_at) VALUES
-- Match 1 (users 1 & 5) - match_at: 2024-04-21 09:15:00
(1, 1, 'Hey! Nice to match - how is your week going?', '2024-04-21 09:22:00'),
(1, 5, 'Hi! Pretty good. Yours?',                         '2024-04-21 09:26:00'),
(1, 1, 'Busy but good. Any plans this weekend?',          '2024-04-21 09:31:00'),
(1, 5, 'Thinking of a coffee walk. Want to join?',        '2024-04-21 09:36:00'),
(1, 1, 'Sounds great. Which area?',                       '2024-04-21 09:40:00'),
(1, 5, 'Near the center. I will send a spot.',            '2024-04-21 09:45:00'),

-- Match 2 (users 1 & 3) - match_at: 2024-04-08 08:05:00
(2, 1, 'Hey! How is your day so far?',                    '2024-04-08 08:12:00'),
(2, 3, 'Hi :) Good morning! Pretty calm. You?',           '2024-04-08 08:16:00'),
(2, 1, 'Same here. I saw you like hiking - favorite trail?', '2024-04-08 08:22:00'),
(2, 3, 'Probably the forest routes. Great views.',        '2024-04-08 08:30:00'),
(2, 1, 'Nice. Any recommendations for an easy one?',      '2024-04-08 08:35:00'),
(2, 3, 'Sure - I will share 2 options later today.',      '2024-04-08 08:38:00'),

-- Match 3 (users 2 & 3) - match_at: 2024-01-09 11:30:00
(3, 2, 'Hey! What made you join the app?',                '2024-01-09 12:05:00'),
(3, 3, 'Hi! Mostly to meet new people in town :)',        '2024-01-09 12:09:00'),
(3, 2, 'Cool. Any favorite coffee place?',                '2024-01-09 12:14:00'),
(3, 3, 'Yes - small one near the market. Great espresso.', '2024-01-09 12:18:00'),
(3, 2, 'Nice, I love espresso. Want to go sometime?',     '2024-01-09 12:25:00'),
(3, 3, 'Sure, sounds fun!',                               '2024-01-09 12:28:00'),

-- Match 4 (users 15 & 16) - match_at: 2024-06-13 08:10:00
(4, 15, 'Hi! Nice match. What are you into lately?',      '2024-06-13 08:22:00'),
(4, 16, 'Hey :) Mostly cooking and some cycling.',        '2024-06-13 08:27:00'),
(4, 15, 'Same! Any signature dish?',                      '2024-06-13 08:34:00'),
(4, 16, 'Pasta. Always. You?',                            '2024-06-13 08:39:00'),
(4, 15, 'Shakshuka with extra spice. Team spicy?',        '2024-06-13 08:42:00'),
(4, 16, 'Definitely team spicy 😄',                       '2024-06-13 08:45:00'),
(4, 15, 'Nice 😄 What is your favorite pasta sauce?',      '2024-06-13 08:49:00'),
(4, 16, 'Classic tomato with garlic and basil. Simple.',    '2024-06-13 08:52:00'),
(4, 15, 'Great choice. Do you cook often during the week?', '2024-06-13 08:56:00'),
(4, 16, 'Usually 3-4 times. Weekends more.',                '2024-06-13 09:00:00'),
(4, 15, 'Same. Any cycling routes you like?',               '2024-06-13 09:04:00'),
(4, 16, 'Early morning rides by the park. Less traffic.',   '2024-06-13 09:07:00'),
(4, 15, 'That sounds perfect. Are you more road or trail?', '2024-06-13 09:11:00'),
(4, 16, 'Mostly road, but I like easy trails too.',         '2024-06-13 09:14:00'),
(4, 15, 'Cool. Maybe we can do a short ride then coffee?',  '2024-06-13 09:18:00'),
(4, 16, 'I would be up for that. This weekend?',            '2024-06-13 09:21:00'),
(4, 15, 'Saturday morning works. What time is best?',       '2024-06-13 09:25:00'),
(4, 16, 'Around 09:00? Not too early.',                     '2024-06-13 09:28:00'),
(4, 15, 'Perfect. Want a quick call later to coordinate?',  '2024-06-13 09:32:00'),
(4, 16, 'Sure, after 18:00 I am free.',                     '2024-06-13 09:35:00'),
(4, 15, 'Great - I will text you around 18:30.',            '2024-06-13 09:38:00'),
(4, 16, 'Sounds good 🙂',                                   '2024-06-13 09:40:00'),

-- Match 5 (users 21 & 22) - match_at: 2024-08-09 12:20:00
(5, 21, 'Hey! Nice to meet you. What are you watching these days?', '2024-08-09 12:33:00'),
(5, 22, 'Hi! Mostly thrillers. Any recommendations?',              '2024-08-09 12:36:00'),
(5, 21, 'If you like mysteries, I have a few.',                    '2024-08-09 12:41:00'),
(5, 22, 'Yes please - send your top 3!',                           '2024-08-09 12:45:00'),

-- Match 6 (users 23 & 24) - match_at: 2024-09-05 12:30:00
(6, 23, 'Hey! Your profile made me smile. How is your week?',      '2024-09-05 12:44:00'),
(6, 24, 'Aww thanks :) Busy but good. You?',                       '2024-09-05 12:49:00'),
(6, 23, 'Same. Want to grab coffee sometime?',                     '2024-09-05 12:55:00'),
(6, 24, 'Sure! This weekend could work.',                           '2024-09-05 13:02:00'),

-- Match 7 (users 4 & 7) - match_at: 2023-02-21 08:10:00
(7, 4,  'Hi! Good morning - how is your week going?',              '2023-02-21 08:22:00'),
(7, 7,  'Hey! Pretty good. Any fun plans?',                        '2023-02-21 08:28:00'),
(7, 4,  'Thinking of a walk later. You into outdoors?',            '2023-02-21 08:35:00'),
(7, 7,  'Yes! Especially sunsets.',                                 '2023-02-21 08:40:00'),

-- Match 8 (users 6 & 8) - match_at: 2023-05-14 13:10:00
(8, 6,  'Hey! Nice match. What is your go-to playlist?',           '2023-05-14 13:22:00'),
(8, 8,  'Hi :) Mostly chill and a SMALLINT of indie. You?',             '2023-05-14 13:26:00'),
(8, 6,  'Same vibe. Any concert you want to see?',                 '2023-05-14 13:33:00'),

-- Match 9 (users 9 & 11) - match_at: 2023-08-08 07:20:00
(9, 9,  'Hi! Your photos are great. Where was the last one taken?', '2023-08-08 07:31:00'),
(9, 11, 'Thanks! That was on a trip north.',                        '2023-08-08 07:35:00'),
(9, 9,  'Nice. I love it there. Any hidden spots you recommend?',    '2023-08-08 07:42:00'),
(9, 11, 'Yes - I will send a couple of places later.',              '2023-08-08 07:46:00'),
(9, 9,  'Perfect, thanks!',                                         '2023-08-08 07:50:00'),

-- Match 10 (users 10 & 13) - match_at: 2023-11-20 09:30:00
(10, 10,'Hey! What is your ideal weekend?',                         '2023-11-20 09:41:00'),
(10, 13,'Coffee, a book, and a long walk. You?',                    '2023-11-20 09:46:00'),
(10, 10,'That sounds perfect. Any book recommendations?',           '2023-11-20 09:52:00'),
(10, 13,'I will send a short list :)',                              '2023-11-20 09:57:00'),

-- Match 11 (users 17 & 19) - match_at: 2024-02-03 16:50:00
(11, 17,'Hey! Nice to match. How is your day?',                     '2024-02-03 17:05:00'),
(11, 19,'Hi! Going well. Just finished work.',                      '2024-02-03 17:10:00'),
(11, 17,'Same. Want to chat later tonight?',                        '2024-02-03 17:15:00'),

-- Match 12 (users 26 & 28) - match_at: 2024-04-18 10:45:00
-- intentionally no messages

-- Match 13 (users 30 & 34) - match_at: 2024-07-27 08:25:00
(13, 30,'Hey! You seem fun. Any hobbies?',                           '2024-07-27 08:40:00'),
(13, 34,'Hi :) Gym, cooking, and movies. You?',                      '2024-07-27 08:44:00'),
(13, 30,'Mostly cycling and trying new food spots.',                 '2024-07-27 08:50:00'),
(13, 34,'Nice - any place you recommend?',                           '2024-07-27 08:54:00'),

-- Match 14 (users 36 & 38) - match_at: 2024-10-09 14:10:00
-- intentionally no messages

-- Match 15 (users 40 & 44) - match_at: 2025-01-16 09:15:00
(15, 40,'Hey! Nice to match. What are you into?',                    '2025-01-16 09:28:00'),
(15, 44,'Hi! I like music and long walks. You?',                     '2025-01-16 09:33:00'),
(15, 40,'Same. Any favorite artist lately?',                         '2025-01-16 09:38:00'),
(15, 44,'A mix of classics and indie.',                               '2025-01-16 09:41:00'),
(15, 40,'Nice. Want to grab coffee this weekend?',                   '2025-01-16 09:47:00'),

-- Match 16 (users 46 & 48) - match_at: 2025-03-29 07:10:00
(16, 46,'Hi! Good morning. How is your week going?',                 '2025-03-29 07:22:00'),
(16, 48,'Hey :) Busy but good. You?',                                '2025-03-29 07:27:00'),

-- Match 17 (users 58 & 60) - match_at: 2025-06-11 12:45:00
-- intentionally no messages

-- Match 18 (users 70 & 72) - match_at: 2025-11-09 10:20:00
(18, 70,'Hey! Nice to match. Any plans for today?',                  '2025-11-09 10:33:00'),
(18, 72,'Hi! Mostly relaxing. You?',                                 '2025-11-09 10:36:00'),
(18, 70,'Same. Want to chat later?',                                 '2025-11-09 10:40:00');



-- Data for 'reports' table (expanded) - spread across Jan 2023 to Dec 2025
INSERT INTO reports (reporter_id, reported_user_id, reason, reported_at) VALUES
(1, 5,  'Inappropriate content in bio.', '2023-01-12 09:00:00'),
(2, 5,  'Harassment in messages.',      '2023-03-04 21:15:00'),
(3, 5,  'Spam messages.',              '2023-05-18 09:30:00'),
(10, 20,'Spamming messages.',          '2023-06-18 14:30:00'),
(11, 20,'Fake profile.',               '2023-09-02 10:45:00'),
(12, 20,'Impersonation.',              '2023-10-10 15:00:00'),
(30, 40,'Harassment.',                 '2023-11-27 11:00:00'),
(31, 40,'Offensive language.',         '2024-02-10 19:10:00'),
(32, 40,'Fake profile.',               '2024-03-22 11:20:00'),
(50, 60,'Fake profile.',               '2024-04-25 16:00:00'),
(51, 60,'Inappropriate photos.',       '2024-07-09 09:15:00'),
(52, 60,'Harassment in chat.',         '2024-08-18 16:30:00'),
(70, 80,'Offensive language.',         '2024-09-22 10:00:00'),
(71, 80,'Harassment.',                 '2024-12-05 18:10:00'),
(72, 80,'Inappropriate content.',      '2025-12-18 10:20:00'),

-- additional reports
(4, 15,  'Threatening messages.',       '2023-02-02 13:40:00'),
(7, 15,  'Hate speech.',                '2023-07-24 20:05:00'),
(9, 18,  'Scam attempt.',               '2023-12-09 08:10:00'),
(14, 22, 'Inappropriate photos.',       '2024-01-17 22:45:00'),
(16, 22, 'Harassment.',                 '2024-05-13 07:30:00'),
(18, 25, 'Spam links.',                 '2024-06-28 16:10:00'),
(19, 25, 'Impersonation.',              '2024-11-08 09:55:00'),
(23, 33, 'Fake profile.',               '2025-01-22 18:40:00'),
(24, 33, 'Offensive language.',         '2025-03-19 11:25:00'),
(27, 35, 'Inappropriate content.',      '2025-05-05 21:15:00'),
(28, 35, 'Harassment in chat.',         '2025-07-27 10:05:00'),
(34, 41, 'Spamming messages.',          '2025-09-14 14:50:00'),
(36, 41, 'Inappropriate content in bio.','2025-10-28 19:35:00'),
(44, 58, 'Scam attempt.',               '2025-11-22 08:20:00'),
(45, 58, 'Fake profile.',               '2025-12-30 16:55:00');



-- Data for 'blocks' table (expanded) - spread across Jan 2023 to Dec 2025
INSERT INTO blocks (blocker_id, blocked_user_id, blocked_at) VALUES
(1, 6,  '2023-01-20 10:00:00'),
(2, 7,  '2023-03-05 11:00:00'),
(3, 8,  '2023-04-18 12:00:00'),
(4, 9,  '2023-06-02 13:00:00'),
(5, 10, '2023-07-16 14:00:00'),
(6, 1,  '2023-09-01 15:00:00'),
(7, 2,  '2023-10-12 09:30:00'),
(8, 3,  '2023-12-03 10:00:00'),
(9, 4,  '2024-01-22 11:15:00'),
(10, 5, '2024-03-14 12:00:00'),
(11, 12,'2024-05-06 10:00:00'),
(12, 11,'2024-07-18 10:30:00'),
(13, 14,'2024-10-09 11:00:00'),
(14, 13,'2025-02-02 11:15:00'),
(15, 16,'2025-06-11 09:45:00'),
(16, 15,'2025-11-26 10:00:00'),

-- additional blocks
(17, 18,'2023-02-11 18:20:00'),
(18, 17,'2023-02-13 09:05:00'),
(19, 21,'2023-05-09 22:10:00'),
(20, 22,'2023-08-28 07:35:00'),
(22, 20,'2023-09-03 13:50:00'),
(23, 24,'2023-11-04 16:40:00'),
(25, 26,'2024-02-27 08:25:00'),
(26, 25,'2024-03-02 19:15:00'),
(27, 30,'2024-06-20 12:05:00'),
(28, 31,'2024-08-07 23:55:00'),
(29, 32,'2024-11-15 10:10:00'),
(30, 33,'2025-01-09 14:35:00'),
(31, 34,'2025-03-26 06:45:00'),
(32, 35,'2025-05-18 20:30:00'),
(33, 36,'2025-07-04 11:05:00'),
(34, 37,'2025-09-21 17:25:00'),
(35, 38,'2025-12-12 09:40:00');


CREATE TABLE superlikes_balance (
    superlike_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    balance INT NOT NULL DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

INSERT INTO superlikes_balance (user_id, balance) VALUES (1, 0);
INSERT INTO superlikes_balance (user_id, balance) VALUES (3, 5);
INSERT INTO superlikes_balance (user_id, balance) VALUES (7, 12);
INSERT INTO superlikes_balance (user_id, balance) VALUES (10, 1);
INSERT INTO superlikes_balance (user_id, balance) VALUES (14, 8);
INSERT INTO superlikes_balance (user_id, balance) VALUES (21, 0);
INSERT INTO superlikes_balance (user_id, balance) VALUES (27, 3);
INSERT INTO superlikes_balance (user_id, balance) VALUES (33, 20);
INSERT INTO superlikes_balance (user_id, balance) VALUES (42, 2);
INSERT INTO superlikes_balance (user_id, balance) VALUES (58, 15);
INSERT INTO superlikes_balance (user_id, balance) VALUES (64, 0);
INSERT INTO superlikes_balance (user_id, balance) VALUES (73, 6);
INSERT INTO superlikes_balance (user_id, balance) VALUES (81, 9);
INSERT INTO superlikes_balance (user_id, balance) VALUES (90, 4);
INSERT INTO superlikes_balance (user_id, balance) VALUES (100, 25);


ALTER TABLE swipes ADD swipetype VARCHAR(10) DEFAULT 'like' 
CHECK (swipetype IN ('like', 'dislike', 'superlike'));


UPDATE swipes SET swipetype = 'like';


ALTER TABLE users  ADD referred_by_user_id INT NULL;
ALTER TABLE users ADD CONSTRAINT fk_users_referred_by FOREIGN KEY (referred_by_user_id) REFERENCES users(user_id);

-- 1. Alice (ID 1) as a major referrer: refers users 2 through 11
UPDATE users
SET referred_by_user_id = 1
WHERE user_id BETWEEN 2 AND 11;
-- 2. Charlie (ID 3) refers a secondary group: users 15 through 20
UPDATE users
SET referred_by_user_id = 3
WHERE user_id BETWEEN 15 AND 20;
-- 3. Referral Chain: Liam (ID 12) refers Mia (ID 13), and Mia refers Noah (ID 14)
UPDATE users
SET referred_by_user_id = 12
WHERE user_id = 13;

UPDATE users
SET referred_by_user_id = 13
WHERE user_id = 14;

-- 4. Oscar (ID 41) refers a dedicated group: users 42 through 46
UPDATE users
SET referred_by_user_id = 41
WHERE user_id BETWEEN 42 AND 46;

-- 5. Isabella (ID 61) refers a second dedicated group: users 62 through 66
UPDATE users
SET referred_by_user_id = 61
WHERE user_id BETWEEN 62 AND 66;

-- 6. Batch assignment for the majority of remaining users (IDs 21-100)
-- This assumes that any user ID that was not targeted in the specific updates above (and is not a top referrer like ID 1) 
-- is referred by either Xena (ID 50) or Adam (ID 80).
UPDATE users
SET referred_by_user_id = 50 
WHERE referred_by_user_id IS NULL AND user_id BETWEEN 21 AND 50;

UPDATE users
SET referred_by_user_id = 80 
WHERE referred_by_user_id IS NULL AND user_id BETWEEN 51 AND 100;

-- 1. CREATE SUBSCRIPTION TYPES TABLE
CREATE TABLE subscription_types (
    subscription_type_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    monthly_price DECIMAL(6,2) NOT NULL
);

-- 2. ADD subscription_type TO USERS TABLE
ALTER TABLE users
ADD subscription_type_id INT;

-- 3. ADD FOREIGN KEY TO USERS TABLE
ALTER TABLE users
ADD CONSTRAINT fk_user_subscription FOREIGN KEY (subscription_type_id) REFERENCES subscription_types(subscription_type_id);

-- 4. CREATE USER PAYMENTS TABLE (Note: renamed to user_payments for clarity)
CREATE TABLE user_payments (
    payment_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    payment_date TIMESTAMP NOT NULL,
    amount DECIMAL(6,2) NOT NULL,
    last4_cc_digits CHAR(4) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- 5. INSERT SUBSCRIPTION DATA (FIXED: monthly_fee -> monthly_price)
INSERT INTO subscription_types (subscription_type_id, name, monthly_price) VALUES
(1, 'Free', 0.00),
(2, 'Plus', 9.99),
(3, 'Gold', 19.99),
(4, 'Platinum', 29.99);

UPDATE users
SET subscription_type_id = 1
WHERE user_id BETWEEN 1 AND 50;  -- Free 50%


UPDATE users
SET subscription_type_id = 2
WHERE user_id BETWEEN 51 AND 80; -- Plus 30%


UPDATE users
SET subscription_type_id = 3
WHERE user_id BETWEEN 81 AND 95; -- Gold 15%

UPDATE users
SET subscription_type_id = 4
WHERE user_id BETWEEN 96 AND 100; -- Platinum 5%


INSERT INTO user_payments (user_id, payment_date, amount, last4_cc_digits)
SELECT user_id, '2025-03-01', CASE subscription_type_id WHEN 2 THEN 9.99 WHEN 3 THEN 19.99 WHEN 4 THEN 29.99 END, '1234'  FROM users WHERE subscription_type_id > 1;

INSERT INTO user_payments (user_id, payment_date, amount, last4_cc_digits)
SELECT user_id, '2025-04-01', CASE subscription_type_id WHEN 2 THEN 9.99 WHEN 3 THEN 19.99 WHEN 4 THEN 29.99 END, '1234' FROM users WHERE subscription_type_id > 1;

INSERT INTO user_payments (user_id, payment_date, amount, last4_cc_digits)
SELECT user_id, '2025-05-01', CASE subscription_type_id WHEN 2 THEN 9.99 WHEN 3 THEN 19.99 WHEN 4 THEN 29.99 END, '1234' FROM users WHERE subscription_type_id > 1;

INSERT INTO user_payments (user_id, payment_date, amount, last4_cc_digits)
SELECT user_id, '2025-06-01', CASE subscription_type_id WHEN 2 THEN 9.99 WHEN 3 THEN 19.99 WHEN 4 THEN 29.99 END, '1234' FROM users WHERE subscription_type_id > 1;

INSERT INTO user_payments (user_id, payment_date, amount, last4_cc_digits)
SELECT user_id, '2025-07-01', CASE subscription_type_id WHEN 2 THEN 9.99 WHEN 3 THEN 19.99 WHEN 4 THEN 29.99 END, '1234' FROM users WHERE subscription_type_id > 1;
-- תל אביב: יוסי (1), דני (2), אורן (3)
INSERT INTO swipes (swiper_id, swiped_id, swipetype, created_at) VALUES 
(10, 1, 'dislike', '2023-01-15 08:30:00'), (11, 1, 'dislike', '2024-05-22 15:45:30'),
(12, 1, 'dislike', '2025-12-15 23:50:00'), (13, 1, 'dislike', '2023-08-05 22:10:12'),
(14, 1, 'dislike', '2024-02-08 17:20:00'), (15, 1, 'dislike', '2025-03-10 18:20:11'),
(16, 1, 'dislike', '2023-06-10 19:45:00'), (17, 1, 'dislike', '2024-11-10 07:20:15'),
(18, 1, 'dislike', '2025-07-12 19:33:00'), (19, 1, 'dislike', '2023-04-22 14:15:22'),
(20, 1, 'dislike', '2024-09-15 23:55:59'), (21, 1, 'dislike', '2025-01-20 10:15:00'),
(22, 1, 'dislike', '2024-12-01 13:40:00'), (23, 1, 'dislike', '2025-10-05 16:40:20'),
(24, 1, 'dislike', '2023-11-12 09:00:05'), (25, 1, 'dislike', '2024-03-14 12:00:00'),
(26, 1, 'dislike', '2025-05-18 14:12:30'), (27, 1, 'dislike', '2023-07-12 19:33:00'),
(28, 1, 'dislike', '2024-01-25 11:30:45'), (29, 1, 'dislike', '2025-08-30 22:15:45'),
(30, 1, 'dislike', '2023-09-14 11:00:00'), (31, 1, 'dislike', '2024-10-10 07:20:15'),
(32, 1, 'dislike', '2025-11-20 20:05:10'), (33, 1, 'dislike', '2024-12-01 13:40:00'),
(34, 1, 'dislike', '2025-04-05 21:05:00'),

(10, 2, 'dislike', '2023-02-10 10:00:00'), (11, 2, 'dislike', '2024-08-25 15:40:00'),
(12, 2, 'dislike', '2025-12-05 23:10:00'), (13, 2, 'dislike', '2023-05-15 13:20:00'),
(14, 2, 'dislike', '2024-04-12 21:30:10'), (15, 2, 'dislike', '2025-06-30 11:50:15'),
(16, 2, 'dislike', '2023-09-20 18:45:30'), (17, 2, 'dislike', '2024-12-08 22:10:55'),
(18, 2, 'dislike', '2025-02-14 07:20:00'), (19, 2, 'dislike', '2023-01-05 09:15:00'),
(20, 2, 'dislike', '2024-07-15 19:25:00'), (21, 2, 'dislike', '2025-09-10 20:40:00'),
(22, 2, 'dislike', '2023-11-20 17:30:00'), (23, 2, 'dislike', '2024-03-22 14:00:30'),
(24, 2, 'dislike', '2025-10-01 12:15:45'),

(10, 3, 'dislike', '2023-03-10 11:00:00'), (11, 3, 'dislike', '2024-10-12 22:30:10'),
(12, 3, 'dislike', '2025-12-30 20:50:15'), (13, 3, 'dislike', '2023-07-15 14:45:00'),
(14, 3, 'dislike', '2024-05-05 08:15:00'), (15, 3, 'dislike', '2025-06-08 12:10:55'),
(16, 3, 'dislike', '2023-11-20 19:20:30'), (17, 3, 'dislike', '2024-09-25 16:40:00'),
(18, 3, 'dislike', '2025-11-22 15:00:30'), (19, 3, 'dislike', '2025-08-14 09:20:00');

-- ירושלים: אייל (4), מיכל (5)
INSERT INTO swipes (swiper_id, swiped_id, swipetype, created_at) VALUES 
(40, 4, 'dislike', '2023-02-14 10:20:00'), (41, 4, 'dislike', '2024-06-22 19:10:30'),
(42, 4, 'dislike', '2025-12-01 22:55:00'), (43, 4, 'dislike', '2023-05-20 16:45:10'),
(44, 4, 'dislike', '2024-03-18 14:22:00'), (45, 4, 'dislike', '2025-10-15 09:12:00'),
(46, 4, 'dislike', '2023-08-11 21:30:00'), (47, 4, 'dislike', '2024-09-30 23:45:00'),
(48, 4, 'dislike', '2025-07-20 20:30:40'), (49, 4, 'dislike', '2023-12-05 08:15:45'),
(50, 4, 'dislike', '2024-01-12 11:05:15'), (51, 4, 'dislike', '2025-04-05 15:50:00'),

(40, 5, 'dislike', '2023-01-10 12:00:00'), (41, 5, 'dislike', '2024-05-20 17:55:00'),
(42, 5, 'dislike', '2025-12-25 23:40:10'), (43, 5, 'dislike', '2023-04-15 18:30:22'),
(44, 5, 'dislike', '2024-02-14 13:20:00'), (45, 5, 'dislike', '2025-11-18 08:30:00'),
(46, 5, 'dislike', '2023-07-25 21:10:00'), (47, 5, 'dislike', '2024-08-10 23:15:30'),
(48, 5, 'dislike', '2025-09-10 22:10:00'), (49, 5, 'dislike', '2023-10-30 07:45:10'),
(50, 5, 'dislike', '2024-11-05 10:40:00'), (51, 5, 'dislike', '2025-06-15 19:25:45'),
(52, 5, 'dislike', '2025-02-28 14:00:00');

-- רחובות: רוני (6), נועה (7)
INSERT INTO swipes (swiper_id, swiped_id, swipetype, created_at) VALUES 
(60, 6, 'dislike', '2023-03-05 09:10:00'), (61, 6, 'dislike', '2024-05-10 18:05:15'),
(62, 6, 'dislike', '2025-11-12 08:45:00'), (63, 6, 'dislike', '2023-06-12 15:40:20'),
(64, 6, 'dislike', '2024-02-25 11:30:00'), (65, 6, 'dislike', '2025-09-25 23:30:10'),
(66, 6, 'dislike', '2023-09-20 20:15:00'), (67, 6, 'dislike', '2024-08-14 21:40:00'),
(68, 6, 'dislike', '2025-06-18 19:10:00'), (69, 6, 'dislike', '2023-11-15 22:50:30'),
(70, 6, 'dislike', '2024-12-20 07:20:45'), (71, 6, 'dislike', '2025-03-01 14:55:00'),

(60, 7, 'dislike', '2023-02-20 13:15:00'), (61, 7, 'dislike', '2024-04-30 18:20:45'),
(62, 7, 'dislike', '2025-12-10 21:15:00'), (63, 7, 'dislike', '2023-05-05 17:40:00'),
(64, 7, 'dislike', '2024-01-10 12:55:00'), (65, 7, 'dislike', '2025-10-20 10:20:00'),
(66, 7, 'dislike', '2023-08-14 21:00:10'), (67, 7, 'dislike', '2024-07-15 22:10:00'),
(68, 7, 'dislike', '2025-08-08 23:55:00'), (69, 7, 'dislike', '2023-11-25 09:30:00'),
(70, 7, 'dislike', '2024-10-05 07:15:30'), (71, 7, 'dislike', '2025-05-12 19:00:15'),
(72, 7, 'dislike', '2025-01-20 14:40:00');