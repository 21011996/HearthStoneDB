/*
Changelog
  Deck quantity is now int and checked in trigger
  ON DELETE STRICT everywhere - harder to shoot yourself
  Most of the TEXT fields are now VARCHAR, because I now know the difference between TEXT and VARCHAR
  Can't take same place at the tournament UNIQUE (tournament_id, place)
*/
CREATE TYPE race_type AS ENUM (
  'Totem',
  'Demon',
  'Mech',
  'Pirate',
  'Murloc',
  'Beast',
  'Dragon'
);

CREATE TYPE outcome_type AS ENUM (
  'Player1Win',
  'Tie',
  'Player2Win'
);

CREATE DOMAIN natural_int AS INTEGER CHECK (VALUE >= 0);

CREATE TABLE IF NOT EXISTS Class (
  Class_id   INTEGER PRIMARY KEY,
  Class_name VARCHAR UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Set (
  Set_id   INTEGER PRIMARY KEY,
  Set_name VARCHAR UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Mechanics (
  Mechanic_id   INTEGER PRIMARY KEY,
  Mechanic_name VARCHAR UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Country (
  Country_id   INTEGER PRIMARY KEY,
  Country_name VARCHAR UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Players (
  Player_id         INTEGER PRIMARY KEY,
  Player_name       VARCHAR UNIQUE NOT NULL,
  Player_country_id INTEGER        NOT NULL REFERENCES Country (Country_id) ON DELETE RESTRICT,
  Player_score      natural_int DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Cards (
  Card_id          INTEGER PRIMARY KEY,
  Card_name        VARCHAR UNIQUE NOT NULL,
  Card_set_id      INTEGER        NOT NULL REFERENCES Set (Set_id) ON DELETE RESTRICT,
  Card_description TEXT           NOT NULL,
  Card_score       natural_int    NOT NULL,
  Class_id         INTEGER        NOT NULL REFERENCES Class (Class_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS Minions (
  Card_id INTEGER PRIMARY KEY REFERENCES Cards ON DELETE RESTRICT,
  race    race_type
);

CREATE TABLE IF NOT EXISTS Spells (
  Card_id INTEGER PRIMARY KEY REFERENCES Cards ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS Weapons (
  Card_id INTEGER PRIMARY KEY REFERENCES Cards ON DELETE RESTRICT
);

CREATE OR REPLACE VIEW Weapon_cards AS
  SELECT
    card_name,
    card_description,
    set_name,
    card_score
  FROM Weapons
    JOIN Cards ON weapons.card_id = cards.card_id
    JOIN Class ON cards.class_id = class.class_id
    JOIN set ON cards.card_set_id = set.set_id;

CREATE VIEW Spell_cards AS
  SELECT
    card_name,
    card_description,
    class_name,
    set_name,
    card_score
  FROM spells
    JOIN Cards ON spells.card_id = cards.card_id
    JOIN Class ON cards.class_id = class.class_id
    JOIN set ON cards.card_set_id = set.set_id;

CREATE VIEW Minion_cards AS
  SELECT
    card_name,
    card_description,
    class_name,
    race,
    set_name,
    card_score
  FROM Minions
    JOIN Cards ON Minions.card_id = cards.card_id
    JOIN Class ON cards.class_id = class.class_id
    JOIN set ON cards.card_set_id = set.set_id;

CREATE TABLE IF NOT EXISTS Decks (
  Deck_id    INTEGER PRIMARY KEY,
  Deck_name  VARCHAR NOT NULL,
  Class_id   INTEGER NOT NULL REFERENCES Class (Class_id) ON DELETE RESTRICT,
  Player_id  INTEGER NOT NULL REFERENCES Players (Player_id) ON DELETE RESTRICT,
  Deck_score natural_int DEFAULT 0,
  UNIQUE (Player_id, Deck_name)
);

CREATE TABLE IF NOT EXISTS Has_mechanic (
  Card_id     INTEGER NOT NULL REFERENCES Cards (Card_id) ON DELETE RESTRICT,
  Mechanic_id INTEGER NOT NULL REFERENCES Mechanics (Mechanic_id) ON DELETE RESTRICT,
  PRIMARY KEY (Card_id, Mechanic_id)
);

CREATE TABLE IF NOT EXISTS In_deck (
  Card_id  INTEGER NOT NULL REFERENCES Cards (Card_id) ON DELETE RESTRICT,
  Deck_id  INTEGER NOT NULL REFERENCES Decks (Deck_id) ON DELETE RESTRICT,
  Quantity INTEGER NOT NULL,
  PRIMARY KEY (Card_id, Deck_id)
);

CREATE TABLE IF NOT EXISTS Tournament (
  Tournament_id         INTEGER PRIMARY KEY,
  Tournament_name       VARCHAR NOT NULL UNIQUE,
  Tournament_format     VARCHAR NOT NULL,
  Tournament_prize_pool natural_int DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Participated (
  Player_id     INTEGER NOT NULL REFERENCES Players (Player_id) ON DELETE RESTRICT,
  Tournament_id INTEGER NOT NULL REFERENCES Tournament (Tournament_id) ON DELETE RESTRICT,
  Place         INTEGER NOT NULL,
  PRIMARY KEY (Player_id, Tournament_id),
  UNIQUE (Tournament_id, Place)
);

CREATE TABLE IF NOT EXISTS Matches (
  Match_id        INTEGER PRIMARY KEY,
  Tournament_id   INTEGER      NOT NULL REFERENCES Tournament (Tournament_id) ON DELETE RESTRICT,
  Player1_deck_id INTEGER      NOT NULL REFERENCES Decks (Deck_id) ON DELETE RESTRICT,
  Player2_deck_id INTEGER      NOT NULL REFERENCES Decks (Deck_id) ON DELETE RESTRICT,
  Outcome         outcome_type NOT NULL
);

CREATE TABLE IF NOT EXISTS Standard_rotation (
  Set_id INTEGER PRIMARY KEY REFERENCES Set
);