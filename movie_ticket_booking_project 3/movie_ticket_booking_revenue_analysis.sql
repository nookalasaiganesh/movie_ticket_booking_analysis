/*
-- =====================================================================
--  MOVIE TICKET BOOKING & REVENUE ANALYSIS | MYSQL PROJECT
-- =====================================================================
--  Contents:
--    PART 1  : Database & Table Creation
--    PART 2  : Sample Data
--    PART 3  : Indexes
--    PART 4  : Views
--    PART 5  : Stored Procedures
--    PART 6  : Triggers and Booking Status History
--    PART 7  : Query Bank - Beginner to Medium (Q1-Q15)
--    PART 8  : Demo Calls / Useful Checks
--
--  RDBMS : MySQL 8.0+
--  Purpose: Analyze movies, theatres, screens, shows, seats, bookings,
--           payments, revenue, occupancy, cancellations and booking trends.
--  Revenue rule used here: successful payments for CONFIRMED or COMPLETED
--           bookings count as revenue. Cancelled bookings do not count.
--  Occupancy rule: confirmed/completed bookings divided by seats in screen.
-- =====================================================================

-- =====================================================================
-- PART 1: DATABASE & TABLE CREATION
-- =====================================================================
DROP DATABASE IF EXISTS movie_ticket_booking;
CREATE DATABASE movie_ticket_booking;
USE movie_ticket_booking;

-- ---------- Strong Entity: MOVIES ----------
CREATE TABLE movies (
    movie_id       INT AUTO_INCREMENT PRIMARY KEY,
    movie_title    VARCHAR(150) NOT NULL,
    genre          VARCHAR(50),
    language       VARCHAR(40),
    release_date   DATE,
    duration_mins  INT,
    certificate    VARCHAR(10)
);

-- ---------- Strong Entity: THEATRES ----------
CREATE TABLE theatres (
    theatre_id    INT AUTO_INCREMENT PRIMARY KEY,
    theatre_name  VARCHAR(120) NOT NULL,
    city          VARCHAR(60) NOT NULL,
    address       VARCHAR(200)
);

-- ---------- Strong Entity: SCREENS ----------
CREATE TABLE screens (
    screen_id    INT AUTO_INCREMENT PRIMARY KEY,
    theatre_id   INT NOT NULL,
    screen_name  VARCHAR(50) NOT NULL,
    screen_type  VARCHAR(30),
    FOREIGN KEY (theatre_id) REFERENCES theatres(theatre_id),
    UNIQUE (theatre_id, screen_name)
);

-- ---------- Strong Entity: SEATS ----------
CREATE TABLE seats (
    seat_id       INT AUTO_INCREMENT PRIMARY KEY,
    screen_id     INT NOT NULL,
    seat_number   VARCHAR(10) NOT NULL,
    seat_type     ENUM('Regular', 'Premium', 'Recliner') DEFAULT 'Regular',
    FOREIGN KEY (screen_id) REFERENCES screens(screen_id),
    UNIQUE (screen_id, seat_number)
);

-- ---------- Strong Entity: SHOWS ----------
CREATE TABLE shows (
    show_id       INT AUTO_INCREMENT PRIMARY KEY,
    movie_id      INT NOT NULL,
    screen_id     INT NOT NULL,
    show_datetime DATETIME NOT NULL,
    base_price    DECIMAL(10,2) NOT NULL,
    show_status   ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled',
    FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    FOREIGN KEY (screen_id) REFERENCES screens(screen_id),
    UNIQUE (screen_id, show_datetime),
    CHECK (base_price >= 0)
);

-- ---------- Strong Entity: BOOKINGS ----------
-- One booking row represents one seat for one show.
CREATE TABLE bookings (
    booking_id     INT AUTO_INCREMENT PRIMARY KEY,
    show_id        INT NOT NULL,
    seat_id        INT NOT NULL,
    customer_name  VARCHAR(100) NOT NULL,
    customer_email VARCHAR(150),
    booking_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    booking_status ENUM('Confirmed', 'Cancelled', 'Completed') DEFAULT 'Confirmed',
    ticket_price   DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (show_id) REFERENCES shows(show_id),
    FOREIGN KEY (seat_id) REFERENCES seats(seat_id),
    UNIQUE (show_id, seat_id),
    CHECK (ticket_price >= 0)
);

-- ---------- Strong Entity: PAYMENTS ----------
-- A booking can have at most one payment record in this beginner project.
CREATE TABLE payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT NOT NULL UNIQUE,
    payment_datetime DATETIME,
    payment_method  ENUM('UPI', 'Card', 'Cash', 'Net Banking', 'Wallet'),
    payment_status  ENUM('Successful', 'Pending', 'Failed', 'Refunded') DEFAULT 'Pending',
    amount          DECIMAL(10,2) NOT NULL,
    transaction_ref VARCHAR(80),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    CHECK (amount >= 0)
);

-- =====================================================================
-- PART 2: SAMPLE DATA
-- =====================================================================

-- Movies
INSERT INTO movies (movie_title, genre, language, release_date, duration_mins, certificate) VALUES
('Sky Warriors', 'Action', 'Telugu', '2026-01-16', 148, 'UA'),
('The Last Signal', 'Thriller', 'English', '2025-11-21', 132, 'UA'),
('Little Big Dreams', 'Drama', 'Hindi', '2026-02-06', 126, 'U'),
('Laugh Out Loud', 'Comedy', 'Telugu', '2025-12-12', 119, 'U'),
('Ocean Mystery', 'Adventure', 'English', '2026-03-20', 141, 'UA'),
('Midnight Chase', 'Action', 'Hindi', '2025-10-03', 137, 'A');

-- Theatres
INSERT INTO theatres (theatre_name, city, address) VALUES
('PVR Central', 'Visakhapatnam', 'Central Avenue'),
('INOX Seaside', 'Visakhapatnam', 'Beach Road'),
('CineMax Grand', 'Hyderabad', 'Hitech City'),
('Galaxy Screens', 'Vijayawada', 'MG Road');

-- Screens
INSERT INTO screens (theatre_id, screen_name, screen_type) VALUES
(1, 'Screen 1', 'Standard'), (1, 'Screen 2', 'IMAX'),
(2, 'Screen 1', 'Standard'), (3, 'Screen 1', 'Dolby Atmos'),
(3, 'Screen 2', 'Standard'), (4, 'Screen 1', 'Standard');

-- Seats: 10 seats per screen for a small, easy-to-check demo dataset
INSERT INTO seats (screen_id, seat_number, seat_type) VALUES
(1,'A1','Regular'),(1,'A2','Regular'),(1,'A3','Regular'),(1,'A4','Premium'),(1,'A5','Premium'),
(1,'B1','Regular'),(1,'B2','Regular'),(1,'B3','Regular'),(1,'B4','Recliner'),(1,'B5','Recliner'),
(2,'A1','Regular'),(2,'A2','Regular'),(2,'A3','Regular'),(2,'A4','Premium'),(2,'A5','Premium'),
(2,'B1','Regular'),(2,'B2','Regular'),(2,'B3','Regular'),(2,'B4','Recliner'),(2,'B5','Recliner'),
(3,'A1','Regular'),(3,'A2','Regular'),(3,'A3','Regular'),(3,'A4','Premium'),(3,'A5','Premium'),
(3,'B1','Regular'),(3,'B2','Regular'),(3,'B3','Regular'),(3,'B4','Recliner'),(3,'B5','Recliner'),
(4,'A1','Regular'),(4,'A2','Regular'),(4,'A3','Regular'),(4,'A4','Premium'),(4,'A5','Premium'),
(4,'B1','Regular'),(4,'B2','Regular'),(4,'B3','Regular'),(4,'B4','Recliner'),(4,'B5','Recliner'),
(5,'A1','Regular'),(5,'A2','Regular'),(5,'A3','Regular'),(5,'A4','Premium'),(5,'A5','Premium'),
(5,'B1','Regular'),(5,'B2','Regular'),(5,'B3','Regular'),(5,'B4','Recliner'),(5,'B5','Recliner'),
(6,'A1','Regular'),(6,'A2','Regular'),(6,'A3','Regular'),(6,'A4','Premium'),(6,'A5','Premium'),
(6,'B1','Regular'),(6,'B2','Regular'),(6,'B3','Regular'),(6,'B4','Recliner'),(6,'B5','Recliner');

-- Shows: mix of weekdays and weekends
INSERT INTO shows (movie_id, screen_id, show_datetime, base_price, show_status) VALUES
(1,1,'2026-10-05 18:00:00',220,'Completed'),
(2,2,'2026-10-06 19:00:00',200,'Completed'),
(3,3,'2026-10-10 14:00:00',180,'Scheduled'),
(4,4,'2026-10-11 17:30:00',190,'Scheduled'),
(5,5,'2026-10-09 20:00:00',210,'Scheduled'),
(1,6,'2026-10-11 20:00:00',230,'Scheduled'),
(6,1,'2026-10-07 21:00:00',200,'Completed'),
(2,3,'2026-10-10 19:30:00',220,'Scheduled'),
(4,2,'2026-10-04 16:00:00',170,'Completed'),
(5,4,'2026-10-08 18:30:00',210,'Scheduled');

-- Bookings: each row reserves one seat for one show
INSERT INTO bookings (show_id, seat_id, customer_name, customer_email, booking_datetime, booking_status, ticket_price) VALUES
(1,1,'Ananya Rao','ananya@example.com','2026-10-01 10:00:00','Completed',220),
(1,2,'Ravi Kumar','ravi@example.com','2026-10-02 11:00:00','Completed',220),
(1,3,'Meera Das','meera@example.com','2026-10-03 12:00:00','Completed',220),
(1,4,'Kiran Reddy','kiran@example.com','2026-10-04 09:00:00','Completed',250),
(1,5,'Sana Ali','sana@example.com','2026-10-04 14:00:00','Cancelled',250),
(2,11,'Arjun Shah','arjun@example.com','2026-10-02 12:00:00','Completed',200),
(2,12,'Nisha Paul','nisha@example.com','2026-10-03 12:30:00','Completed',200),
(2,13,'Dev Singh','dev@example.com','2026-10-04 13:00:00','Cancelled',200),
(2,14,'Tara Sen','tara@example.com','2026-10-05 15:00:00','Completed',230),
(3,21,'Pooja Nair','pooja@example.com','2026-10-06 10:00:00','Confirmed',180),
(3,22,'Rahul Jain','rahul@example.com','2026-10-07 11:00:00','Confirmed',180),
(3,23,'Isha Roy','isha@example.com','2026-10-08 12:00:00','Cancelled',180),
(4,31,'Vamsi Teja','vamsi@example.com','2026-10-07 13:00:00','Confirmed',190),
(4,32,'Harini G','harini@example.com','2026-10-08 14:00:00','Confirmed',190),
(4,33,'Sai Charan','sai@example.com','2026-10-09 15:00:00','Confirmed',190),
(5,41,'John Mathew','john@example.com','2026-10-05 16:00:00','Confirmed',210),
(5,42,'Maya Krish','maya@example.com','2026-10-06 16:30:00','Confirmed',210),
(5,43,'Rohan D','rohan@example.com','2026-10-07 17:00:00','Cancelled',210),
(6,51,'Sowmya K','sowmya@example.com','2026-10-07 09:00:00','Confirmed',230),
(6,52,'Bharat M','bharat@example.com','2026-10-08 09:30:00','Confirmed',230),
(7,6,'Neel Joshi','neel@example.com','2026-10-03 10:00:00','Completed',200),
(7,7,'Diya Bose','diya@example.com','2026-10-04 11:00:00','Completed',200),
(8,24,'Akhil P','akhil@example.com','2026-10-08 12:00:00','Confirmed',220),
(8,25,'Sreeja M','sreeja@example.com','2026-10-08 13:00:00','Confirmed',220),
(9,15,'Farah Khan','farah@example.com','2026-10-01 09:00:00','Completed',170),
(9,16,'Mohan R','mohan@example.com','2026-10-02 10:00:00','Cancelled',170),
(10,34,'Latha P','latha@example.com','2026-10-06 11:00:00','Confirmed',210);

-- Payments: cancelled bookings are refunded; a few payments remain pending/failed
INSERT INTO payments (booking_id, payment_datetime, payment_method, payment_status, amount, transaction_ref) VALUES
(1,'2026-10-01 10:01:00','UPI','Successful',220,'TXN1001'),
(2,'2026-10-02 11:01:00','Card','Successful',220,'TXN1002'),
(3,'2026-10-03 12:01:00','UPI','Successful',220,'TXN1003'),
(4,'2026-10-04 09:01:00','Card','Successful',250,'TXN1004'),
(5,'2026-10-04 14:01:00','UPI','Refunded',250,'TXN1005'),
(6,'2026-10-02 12:01:00','UPI','Successful',200,'TXN1006'),
(7,'2026-10-03 12:31:00','Cash','Successful',200,'TXN1007'),
(8,'2026-10-04 13:01:00','UPI','Refunded',200,'TXN1008'),
(9,'2026-10-05 15:01:00','Card','Successful',230,'TXN1009'),
(10,'2026-10-06 10:01:00','UPI','Successful',180,'TXN1010'),
(11,'2026-10-07 11:01:00','UPI','Successful',180,'TXN1011'),
(12,'2026-10-08 12:01:00','UPI','Refunded',180,'TXN1012'),
(13,'2026-10-07 13:01:00','Card','Successful',190,'TXN1013'),
(14,'2026-10-08 14:01:00','UPI','Pending',190,'TXN1014'),
(15,'2026-10-09 15:01:00','Card','Successful',190,'TXN1015'),
(16,'2026-10-05 16:01:00','UPI','Successful',210,'TXN1016'),
(17,'2026-10-06 16:31:00','Card','Successful',210,'TXN1017'),
(18,'2026-10-07 17:01:00','UPI','Refunded',210,'TXN1018'),
(19,'2026-10-07 09:01:00','UPI','Successful',230,'TXN1019'),
(20,'2026-10-08 09:31:00','Card','Successful',230,'TXN1020'),
(21,'2026-10-03 10:01:00','UPI','Successful',200,'TXN1021'),
(22,'2026-10-04 11:01:00','Card','Successful',200,'TXN1022'),
(23,'2026-10-08 12:01:00','UPI','Successful',220,'TXN1023'),
(24,'2026-10-08 13:01:00','Card','Pending',220,'TXN1024'),
(25,'2026-10-01 09:01:00','Cash','Successful',170,'TXN1025'),
(26,'2026-10-02 10:01:00','UPI','Refunded',170,'TXN1026'),
(27,'2026-10-06 11:01:00','UPI','Successful',210,'TXN1027');

-- =====================================================================
-- PART 3: INDEXES
-- =====================================================================
CREATE INDEX idx_movies_title ON movies(movie_title);
CREATE INDEX idx_theatres_city ON theatres(city);
CREATE INDEX idx_screens_theatre ON screens(theatre_id);
CREATE INDEX idx_seats_screen ON seats(screen_id);
CREATE INDEX idx_shows_movie_date ON shows(movie_id, show_datetime);
CREATE INDEX idx_shows_screen_date ON shows(screen_id, show_datetime);
CREATE INDEX idx_bookings_show_status ON bookings(show_id, booking_status);
CREATE INDEX idx_bookings_datetime ON bookings(booking_datetime);
CREATE INDEX idx_payments_status ON payments(payment_status);

-- =====================================================================
-- PART 4: VIEWS
-- =====================================================================

-- 4.1 Booking, movie, theatre and payment details
CREATE OR REPLACE VIEW view_booking_details AS
SELECT b.booking_id, b.customer_name, m.movie_title, t.theatre_name,
       t.city, s.show_datetime, b.seat_id, b.booking_status,
       b.ticket_price, p.payment_method, p.payment_status, p.amount
FROM bookings b
JOIN shows s ON b.show_id = s.show_id
JOIN movies m ON s.movie_id = m.movie_id
JOIN screens sc ON s.screen_id = sc.screen_id
JOIN theatres t ON sc.theatre_id = t.theatre_id
LEFT JOIN payments p ON b.booking_id = p.booking_id;

-- 4.2 Revenue by movie (only successful payments and valid bookings)
CREATE OR REPLACE VIEW view_movie_revenue AS
SELECT m.movie_id, m.movie_title,
       COALESCE(SUM(CASE WHEN p.payment_status = 'Successful'
                    AND b.booking_status IN ('Confirmed','Completed')
                    THEN p.amount ELSE 0 END), 0) AS total_revenue
FROM movies m
LEFT JOIN shows s ON m.movie_id = s.movie_id
LEFT JOIN bookings b ON s.show_id = b.show_id
LEFT JOIN payments p ON b.booking_id = p.booking_id
GROUP BY m.movie_id, m.movie_title;

-- 4.3 Cancellation summary by movie
CREATE OR REPLACE VIEW view_movie_cancellations AS
SELECT m.movie_title,
       COUNT(b.booking_id) AS total_bookings,
       SUM(CASE WHEN b.booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings
FROM movies m
LEFT JOIN shows s ON m.movie_id = s.movie_id
LEFT JOIN bookings b ON s.show_id = b.show_id
GROUP BY m.movie_id, m.movie_title;

-- =====================================================================
-- =====================================================================
-- PART 5: STORED PROCEDURES
-- =====================================================================

-- 5.1 Show revenue for one movie. Pass NULL to show revenue for all movies.
DELIMITER $$
CREATE PROCEDURE sp_movie_revenue(IN p_movie_id INT)
BEGIN
    SELECT m.movie_id, m.movie_title,
           COALESCE(SUM(CASE WHEN p.payment_status = 'Successful'
                        AND b.booking_status IN ('Confirmed','Completed')
                        THEN p.amount ELSE 0 END), 0) AS total_revenue
    FROM movies m
    LEFT JOIN shows s ON m.movie_id = s.movie_id
    LEFT JOIN bookings b ON s.show_id = b.show_id
    LEFT JOIN payments p ON b.booking_id = p.booking_id
    WHERE p_movie_id IS NULL OR m.movie_id = p_movie_id
    GROUP BY m.movie_id, m.movie_title
    ORDER BY total_revenue DESC;
END $$

-- 5.2 Show occupancy for every showtime.
CREATE PROCEDURE sp_show_occupancy()
BEGIN
    SELECT s.show_id, m.movie_title, t.theatre_name, sc.screen_name,
           s.show_datetime,
           COUNT(DISTINCT CASE WHEN b.booking_status IN ('Confirmed','Completed')
                               THEN b.seat_id END) AS booked_seats,
           COUNT(DISTINCT st.seat_id) AS total_seats,
           ROUND(100.0 * COUNT(DISTINCT CASE
                 WHEN b.booking_status IN ('Confirmed','Completed') THEN b.seat_id END)
                 / NULLIF(COUNT(DISTINCT st.seat_id), 0), 2) AS occupancy_percent
    FROM shows s
    JOIN movies m ON s.movie_id = m.movie_id
    JOIN screens sc ON s.screen_id = sc.screen_id
    JOIN theatres t ON sc.theatre_id = t.theatre_id
    LEFT JOIN seats st ON st.screen_id = sc.screen_id
    LEFT JOIN bookings b ON b.show_id = s.show_id AND b.seat_id = st.seat_id
    GROUP BY s.show_id, m.movie_title, t.theatre_name, sc.screen_name, s.show_datetime
    ORDER BY occupancy_percent DESC;
END $$

-- 5.3 Cancel a booking by booking ID. The trigger below records the status change.
CREATE PROCEDURE sp_cancel_booking(IN p_booking_id INT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM bookings WHERE booking_id = p_booking_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking ID was not found';
    ELSE
        UPDATE bookings
        SET booking_status = 'Cancelled'
        WHERE booking_id = p_booking_id
          AND booking_status <> 'Cancelled';
        SELECT booking_id, booking_status
        FROM bookings
        WHERE booking_id = p_booking_id;
    END IF;
END $$
DELIMITER ;

-- Example procedure calls (run manually after the full script):
-- CALL sp_movie_revenue(NULL);  -- revenue for all movies
-- CALL sp_movie_revenue(1);     -- revenue for movie_id 1
-- CALL sp_show_occupancy();
-- CALL sp_cancel_booking(1);     -- example only; changes booking 1 to Cancelled

-- =====================================================================
-- PART 6: TRIGGERS AND BOOKING STATUS HISTORY
-- =====================================================================

-- This table stores a small history whenever a booking status changes.
CREATE TABLE booking_status_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

DELIMITER $$

-- Trigger 1: A seat must belong to the same screen as the selected show.
-- It also prevents booking a show that has been cancelled.
CREATE TRIGGER trg_validate_booking_before_insert
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE v_show_screen_id INT;
    DECLARE v_seat_screen_id INT;
    DECLARE v_show_status VARCHAR(20);

    SELECT screen_id, show_status
    INTO v_show_screen_id, v_show_status
    FROM shows WHERE show_id = NEW.show_id;

    SELECT screen_id INTO v_seat_screen_id
    FROM seats WHERE seat_id = NEW.seat_id;

    IF v_show_screen_id <> v_seat_screen_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Selected seat does not belong to the screen for this show';
    END IF;

    IF v_show_status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot book a cancelled show';
    END IF;
END $$

-- Trigger 2: A successful payment must match the booking amount and cannot
-- be created for a cancelled booking.
CREATE TRIGGER trg_validate_payment_before_insert
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_ticket_price DECIMAL(10,2);
    DECLARE v_booking_status VARCHAR(20);

    SELECT ticket_price, booking_status
    INTO v_ticket_price, v_booking_status
    FROM bookings WHERE booking_id = NEW.booking_id;

    IF NEW.amount <> v_ticket_price THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Payment amount must match the booking ticket price';
    END IF;

    IF NEW.payment_status = 'Successful' AND v_booking_status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot record a successful payment for a cancelled booking';
    END IF;
END $$

-- Trigger 3: Record every booking status change for simple audit/history.
CREATE TRIGGER trg_booking_status_after_update
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF OLD.booking_status <> NEW.booking_status THEN
        INSERT INTO booking_status_history (booking_id, old_status, new_status)
        VALUES (NEW.booking_id, OLD.booking_status, NEW.booking_status);
    END IF;
END $$
DELIMITER ;

-- Example trigger check (run manually after changing a booking status):
-- UPDATE bookings SET booking_status = 'Cancelled' WHERE booking_id = 2;
-- SELECT * FROM booking_status_history;

-- =====================================================================
-- PART 7: QUERY BANK - BEGINNER TO MEDIUM
-- =====================================================================

-- Q1. Show all movies
SELECT * FROM movies;

-- Q2. List shows with movie, theatre, screen and show time
SELECT s.show_id, m.movie_title, t.theatre_name, sc.screen_name,
       s.show_datetime, s.base_price, s.show_status
FROM shows s
JOIN movies m ON s.movie_id = m.movie_id
JOIN screens sc ON s.screen_id = sc.screen_id
JOIN theatres t ON sc.theatre_id = t.theatre_id
ORDER BY s.show_datetime;

-- Q3. Highest-grossing movies (successful payments only)
SELECT m.movie_title, SUM(p.amount) AS total_revenue
FROM movies m
JOIN shows s ON m.movie_id = s.movie_id
JOIN bookings b ON s.show_id = b.show_id
JOIN payments p ON b.booking_id = p.booking_id
WHERE p.payment_status = 'Successful'
  AND b.booking_status IN ('Confirmed', 'Completed')
GROUP BY m.movie_id, m.movie_title
ORDER BY total_revenue DESC;

-- Q4. Top 3 highest-grossing movies
SELECT movie_title, total_revenue
FROM view_movie_revenue
ORDER BY total_revenue DESC
LIMIT 3;

-- Q5. Seat occupancy percentage for each showtime
SELECT s.show_id, m.movie_title, s.show_datetime, t.theatre_name, sc.screen_name,
       COUNT(DISTINCT se.seat_id) AS total_seats,
       COUNT(DISTINCT CASE WHEN b.booking_status IN ('Confirmed','Completed')
                           THEN b.seat_id END) AS occupied_seats,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN b.booking_status IN ('Confirmed','Completed')
                           THEN b.seat_id END) / NULLIF(COUNT(DISTINCT se.seat_id), 0), 2) AS occupancy_percent
FROM shows s
JOIN movies m ON s.movie_id = m.movie_id
JOIN screens sc ON s.screen_id = sc.screen_id
JOIN theatres t ON sc.theatre_id = t.theatre_id
JOIN seats se ON sc.screen_id = se.screen_id
LEFT JOIN bookings b ON s.show_id = b.show_id AND se.seat_id = b.seat_id
GROUP BY s.show_id, m.movie_title, s.show_datetime, t.theatre_name, sc.screen_name
ORDER BY occupancy_percent DESC;

-- Q6. Weekday vs weekend revenue
SELECT CASE WHEN DAYOFWEEK(s.show_datetime) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       SUM(CASE WHEN p.payment_status = 'Successful'
                 AND b.booking_status IN ('Confirmed','Completed') THEN p.amount ELSE 0 END) AS revenue
FROM shows s
JOIN bookings b ON s.show_id = b.show_id
JOIN payments p ON b.booking_id = p.booking_id
GROUP BY day_type;

-- Q7. Cancellation count and cancellation rate
SELECT COUNT(*) AS total_bookings,
       SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings,
       ROUND(100.0 * SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_percent
FROM bookings;

-- Q8. Cancellation analysis by movie
SELECT m.movie_title,
       COUNT(b.booking_id) AS total_bookings,
       SUM(CASE WHEN b.booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancellations,
       ROUND(100.0 * SUM(CASE WHEN b.booking_status = 'Cancelled' THEN 1 ELSE 0 END) / NULLIF(COUNT(b.booking_id),0), 2) AS cancellation_percent
FROM movies m
JOIN shows s ON m.movie_id = s.movie_id
JOIN bookings b ON s.show_id = b.show_id
GROUP BY m.movie_id, m.movie_title
ORDER BY cancellation_percent DESC;

-- Q9. Booking trend by date
SELECT DATE(booking_datetime) AS booking_date,
       COUNT(*) AS bookings_made
FROM bookings
GROUP BY DATE(booking_datetime)
ORDER BY booking_date;

-- Q10. Revenue by city
SELECT t.city,
       SUM(CASE WHEN p.payment_status = 'Successful'
                 AND b.booking_status IN ('Confirmed','Completed') THEN p.amount ELSE 0 END) AS revenue
FROM theatres t
JOIN screens sc ON t.theatre_id = sc.theatre_id
JOIN shows s ON sc.screen_id = s.screen_id
JOIN bookings b ON s.show_id = b.show_id
JOIN payments p ON b.booking_id = p.booking_id
GROUP BY t.city
ORDER BY revenue DESC;

-- Q11. Most popular movies by valid tickets booked
SELECT m.movie_title,
       SUM(CASE WHEN b.booking_status IN ('Confirmed','Completed') THEN 1 ELSE 0 END) AS valid_tickets
FROM movies m
JOIN shows s ON m.movie_id = s.movie_id
JOIN bookings b ON s.show_id = b.show_id
GROUP BY m.movie_id, m.movie_title
ORDER BY valid_tickets DESC;

-- Q12. Payment method performance
SELECT payment_method, COUNT(*) AS payment_count,
       SUM(CASE WHEN payment_status = 'Successful' THEN amount ELSE 0 END) AS successful_amount
FROM payments
GROUP BY payment_method
ORDER BY successful_amount DESC;

-- Q13. Shows with low occupancy (less than 40%)
SELECT s.show_id, m.movie_title, s.show_datetime,
       ROUND(100.0 * SUM(CASE WHEN b.booking_status IN ('Confirmed','Completed') THEN 1 ELSE 0 END)
             / (SELECT COUNT(*) FROM seats se WHERE se.screen_id = s.screen_id), 2) AS occupancy_percent
FROM shows s
JOIN movies m ON s.movie_id = m.movie_id
LEFT JOIN bookings b ON s.show_id = b.show_id
GROUP BY s.show_id, m.movie_title, s.show_datetime, s.screen_id
HAVING occupancy_percent < 40
ORDER BY occupancy_percent;

-- Q14. Monthly revenue trend
SELECT DATE_FORMAT(p.payment_datetime, '%Y-%m') AS revenue_month,
       SUM(p.amount) AS revenue
FROM payments p
JOIN bookings b ON p.booking_id = b.booking_id
WHERE p.payment_status = 'Successful'
  AND b.booking_status IN ('Confirmed','Completed')
GROUP BY DATE_FORMAT(p.payment_datetime, '%Y-%m')
ORDER BY revenue_month;

-- Q15. Full booking details using the view
SELECT * FROM view_booking_details ORDER BY show_datetime, booking_id;

-- =====================================================================
-- PART 8: DEMO CALLS / USEFUL CHECKS
-- =====================================================================
-- Run each query separately if you want to inspect one result at a time.
-- SELECT * FROM view_movie_revenue;
-- SELECT * FROM view_movie_cancellations;
-- SHOW TABLES;
-- SHOW INDEX FROM bookings;
-- SHOW TRIGGERS;
-- SHOW PROCEDURE STATUS WHERE Db = 'movie_ticket_booking';
-- SELECT * FROM booking_status_history;
-- DESCRIBE shows;
