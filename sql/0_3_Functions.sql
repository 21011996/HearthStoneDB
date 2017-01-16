CREATE OR REPLACE FUNCTION add_card_into_deck()
  RETURNS TRIGGER AS $$
DECLARE
  _player_id     INTEGER;
  _class_id      INTEGER;
  _card_class_id INTEGER;
  _card_score    INTEGER;
  _add_score     INTEGER;
BEGIN
  SELECT
    player_id,
    class_id
  FROM decks
  WHERE deck_id = NEW.deck_id
  INTO _player_id, _class_id;

  SELECT card_score
  FROM cards
  WHERE card_id = NEW.card_id
  INTO _card_score;

  IF (TG_OP = 'INSERT')
  THEN
    SELECT class_id
    FROM cards
    WHERE card_id = NEW.card_id
    INTO _card_class_id;
    IF (NEW.quantity > 2 OR NEW.quantity < 1)
      THEN
      RAISE EXCEPTION E'Illegal quentity of card % - %', NEW.card_id, NEW.quantity;
    END IF;
    IF (_card_class_id <> _class_id AND _card_class_id <> 3)
    THEN
      RAISE EXCEPTION E'Illegal class card for this deck:%,%', _class_id, NEW.card_id;
    END IF;

    IF (get_cards_in_deck(NEW.deck_id) + NEW.quantity > 30)
    THEN
      RAISE EXCEPTION E'Illegal number of cards in this deck:%', NEW.deck_id;
    END IF;

    _add_score = NEW.quantity * _card_score;
  END IF;

  IF (TG_OP = 'UPDATE')
  THEN
    IF (NEW.quantity > 2 OR NEW.quantity < 1)
      THEN
      RAISE EXCEPTION E'Illegal quentity of card % - %', NEW.card_id, NEW.quantity;
    END IF;
    IF (get_cards_in_deck(NEW.deck_id) + (NEW.quantity - OLD.quantity) > 30)
    THEN
      RAISE EXCEPTION E'Illegal number of cards in this deck:%', NEW.deck_id;
    END IF;
    _add_score = (NEW.quantity - OLD.quantity) * _card_score;
  END IF;

  UPDATE decks
  SET deck_score = deck_score + _add_score
  WHERE deck_id = NEW.deck_id;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_cards_in_deck(_deck_id INTEGER)
  RETURNS INTEGER AS $$
DECLARE
  _count    INTEGER;
  _card_id  INTEGER;
  _quantity INTEGER;
BEGIN
  _count = 0;
  FOR _card_id, _quantity IN (SELECT
                                card_id,
                                quantity
                              FROM in_deck
                              WHERE deck_id = _deck_id) LOOP
    _count = _count + _quantity;
  END LOOP;
  RETURN _count;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS card_in_deck
ON in_deck;
CREATE TRIGGER card_in_deck
BEFORE INSERT OR UPDATE
  ON in_deck
FOR EACH ROW
EXECUTE PROCEDURE add_card_into_deck();

CREATE OR REPLACE FUNCTION add_match_into_matches()
  RETURNS TRIGGER AS $$
DECLARE
  _player_id_1         INTEGER;
  _player_1_deck_score INTEGER;
  _player_1_score_diff INTEGER;

  _player_id_2         INTEGER;
  _player_2_deck_score INTEGER;
  _player_2_score_diff INTEGER;

  _prize_pool_factor   INTEGER;

  _deck_diff_1         INTEGER;
  _deck_diff_2         INTEGER;
BEGIN
  IF (get_cards_in_deck(NEW.player1_deck_id) <> 30 OR get_cards_in_deck(NEW.player2_deck_id) <> 30)
  THEN
    RAISE EXCEPTION E'Submitted unfinished decks:%,%', NEW.player1_deck_id, NEW.player2_deck_id;
  END IF;
  SELECT
    player_id,
    deck_score
  FROM decks
  WHERE deck_id = NEW.Player1_deck_id
  INTO _player_id_1, _player_1_deck_score;
  SELECT
    player_id,
    deck_score
  FROM decks
  WHERE deck_id = NEW.Player2_deck_id
  INTO _player_id_2, _player_2_deck_score;

  IF (_player_id_1 = _player_id_2)
  THEN
    RAISE EXCEPTION E'Player can\'t play with himself:%', _player_id_1;
  END IF;
  SELECT tournament_prize_pool
  FROM tournament
  WHERE tournament_id = NEW.tournament_id
  INTO _prize_pool_factor;

  _deck_diff_1 = (_prize_pool_factor * 1.0 / 200.0) * (_player_1_deck_score * 1.0 / _player_2_deck_score * 1.0);
  _deck_diff_2 = (_prize_pool_factor * 1.0 / 200.0) * (_player_2_deck_score * 1.0 / _player_1_deck_score * 1.0);
  IF (NEW.outcome = 'Player1Win')
  THEN
    _player_1_score_diff = _deck_diff_1;
    _player_2_score_diff = -_deck_diff_2;
  ELSEIF (NEW.outcome = 'Tie')
    THEN
      _player_1_score_diff = 0;
      _player_2_score_diff = 0;
  ELSEIF (NEW.outcome = 'Player2Win')
    THEN
      _player_1_score_diff = -_deck_diff_1;
      _player_2_score_diff = _deck_diff_2;
  END IF;

  UPDATE players
  SET player_score = player_score + _player_1_score_diff
  WHERE player_id = _player_id_1;
  UPDATE players
  SET player_score = player_score + _player_2_score_diff
  WHERE player_id = _player_id_2;
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS match_add
ON matches;
CREATE TRIGGER match_add
BEFORE INSERT
  ON matches
FOR EACH ROW
EXECUTE PROCEDURE add_match_into_matches();

--get all deck names from player
CREATE OR REPLACE FUNCTION get_all_players_decks(_player_name TEXT)
  RETURNS TABLE(deck_id INTEGER, deck_name TEXT, deck_score natural_int) AS $$
SELECT
  deck_id,
  deck_name,
  deck_score
FROM decks
  NATURAL JOIN players
WHERE player_name = _player_name;
$$ LANGUAGE 'sql';

--get all mechanics from deck
CREATE OR REPLACE FUNCTION get_all_mechanics_in_deck(_deck_id INTEGER)
  RETURNS TABLE(mechanics TEXT) AS $$
SELECT DISTINCT mechanic_name
FROM decks
  JOIN in_deck ON decks.deck_id = in_deck.deck_id
  JOIN cards ON in_deck.card_id = cards.card_id
  JOIN has_mechanic ON cards.card_id = has_mechanic.card_id
  JOIN mechanics ON has_mechanic.mechanic_id = mechanics.mechanic_id
WHERE decks.deck_id = _deck_id;
$$ LANGUAGE 'sql';

--get all sets from deck
CREATE OR REPLACE FUNCTION get_all_sets_in_deck(_deck_id INTEGER)
  RETURNS TABLE(set_name TEXT) AS $$
SELECT DISTINCT set_name
FROM decks
  JOIN in_deck ON decks.deck_id = in_deck.deck_id
  JOIN cards ON in_deck.card_id = cards.card_id
  JOIN set ON cards.card_set_id = set.set_id
WHERE decks.deck_id = _deck_id;
$$ LANGUAGE 'sql';


-- Player name to player_id
CREATE OR REPLACE FUNCTION get_player_id(_player_name TEXT)
  RETURNS INTEGER AS $$
DECLARE
  id INTEGER;
BEGIN
  SELECT player_id
  FROM players
  WHERE player_name = _player_name
  INTO id;
  RETURN id;
END;
$$ LANGUAGE 'plpgsql';

-- Player name to player_id
CREATE OR REPLACE FUNCTION get_deck_wins(_deck_id INTEGER)
  RETURNS INTEGER AS $$
DECLARE
  _n_wins   INTEGER;
  _match_id INTEGER;
  _outcome  outcome_type;
BEGIN
  _n_wins = 0;
  FOR _match_id, _outcome IN (SELECT
                                match_id,
                                outcome
                              FROM matches
                              WHERE player1_deck_id = _deck_id) LOOP
    IF (_outcome = 'Player1Win')
    THEN
      _n_wins = _n_wins + 1;
    END IF;
  END LOOP;
  FOR _match_id, _outcome IN (SELECT
                                match_id,
                                outcome
                              FROM matches
                              WHERE player2_deck_id = _deck_id) LOOP
    IF (_outcome = 'Player2Win')
    THEN
      _n_wins = _n_wins + 1;
    END IF;
  END LOOP;
  RETURN _n_wins;
END;
$$ LANGUAGE 'plpgsql';

-- Player name to player_id
CREATE OR REPLACE FUNCTION get_deck_loses(_deck_id INTEGER)
  RETURNS INTEGER AS $$
DECLARE
  _n_loses  INTEGER;
  _match_id INTEGER;
  _outcome  outcome_type;
BEGIN
  _n_loses = 0;
  FOR _match_id, _outcome IN (SELECT
                                match_id,
                                outcome
                              FROM matches
                              WHERE player1_deck_id = _deck_id) LOOP
    IF (_outcome = 'Player2Win')
    THEN
      _n_loses = _n_loses + 1;
    END IF;
  END LOOP;
  FOR _match_id, _outcome IN (SELECT
                                match_id,
                                outcome
                              FROM matches
                              WHERE player2_deck_id = _deck_id) LOOP
    IF (_outcome = 'Player1Win')
    THEN
      _n_loses = _n_loses + 1;
    END IF;
  END LOOP;
  RETURN _n_loses;
END;
$$ LANGUAGE 'plpgsql';


--get all cards in deck
CREATE OR REPLACE FUNCTION get_all_deck_cards(_player_name TEXT, _deck_name TEXT)
  RETURNS TABLE(quantity INTEGER, card_id INTEGER, card_name TEXT, description TEXT, set TEXT) AS $$
SELECT
  in_deck.quantity,
  cards.card_id,
  cards.card_name,
  cards.card_description,
  set.set_name
FROM cards
  JOIN in_deck ON cards.card_id = in_deck.card_id
  JOIN decks ON in_deck.deck_id = decks.deck_id
  JOIN set ON cards.card_set_id = set.set_id
WHERE decks.player_id = get_player_id(_player_name) AND decks.deck_name = _deck_name;
$$ LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION get_rankings_list()
  RETURNS TABLE(player_id INTEGER, player_name TEXT, player_score natural_int) AS $$
SELECT
  players.player_id,
  players.player_name,
  players.player_score
FROM players
ORDER BY players.player_score DESC;
$$ LANGUAGE 'sql';


CREATE TYPE achievement_type AS (
  tournament_name TEXT,
  place           INTEGER,
  prize_pool      INTEGER
);
-- Player name to achievements
CREATE OR REPLACE FUNCTION get_player_achievements(_player_name TEXT)
  RETURNS SETOF achievement_type AS $$
DECLARE
  _result          achievement_type;
  _player_id       INTEGER;
  _tournament_id   INTEGER;
  _tournament_name TEXT;
  _place           INTEGER;
  _prize_pool      INTEGER;
BEGIN
  _player_id = get_player_id(_player_name);
  FOR _tournament_id, _place IN (SELECT
                                   tournament_id,
                                   place
                                 FROM participated
                                 WHERE player_id = _player_id) LOOP
    _tournament_name = (SELECT tournament_name
                        FROM tournament
                        WHERE tournament_id = _tournament_id);
    _prize_pool = (SELECT tournament_prize_pool
                   FROM tournament
                   WHERE _tournament_id = tournament_id);
    _result.tournament_name = _tournament_name;
    _result.place = _place;
    _result.prize_pool = _prize_pool;
    RETURN NEXT _result;
  END LOOP;
END;
$$ LANGUAGE 'plpgsql';
