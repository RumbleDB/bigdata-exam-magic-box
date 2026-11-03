-- Tiny stand-in for the exam databases (the real dumps are only in the release zip)
CREATE TABLE customers (id integer PRIMARY KEY, name text NOT NULL);
INSERT INTO customers VALUES (1, 'Preston Landry'), (2, 'Jamari Dominguez');
