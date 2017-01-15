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
    IF (_card_class_id <> _class_id AND _card_class_id <> 3)
    THEN
      RAISE EXCEPTION E'Illegal class card for this deck:%,%', _class_id, NEW.card_id;
    END IF;

    _add_score = NEW.quantity * _card_score;
  END IF;

  IF (TG_OP = 'UPDATE')
  THEN
    _add_score = (NEW.quantity - OLD.quantity) * _card_score;
  END IF;

  UPDATE decks
  SET deck_score = deck_score + _add_score
  WHERE deck_id = NEW.deck_id;

  RETURN NEW;
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

  SELECT tournament_prize_pool
  FROM tournament
  WHERE tournament_id = NEW.tournament_id
  INTO _prize_pool_factor;

  _deck_diff_1 = (_prize_pool_factor / 200) * (_player_1_deck_score / _player_2_deck_score);
  _deck_diff_2 = (_prize_pool_factor / 200) * (_player_2_deck_score / _player_1_deck_score);
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
AFTER INSERT
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

--get all cards in deck
CREATE OR REPLACE FUNCTION get_all_deck_cards(_player_name TEXT, _deck_name TEXT)
  RETURNS TABLE(quantity qnt_int, card_id INTEGER, card_name TEXT, description TEXT, set TEXT) AS $$
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


CREATE TYPE achivment_type AS (
  tournament_name TEXT,
  place           INTEGER,
  prize_pool      INTEGER
);
-- Player name to achievements
CREATE OR REPLACE FUNCTION get_player_achivments(_player_name TEXT)
  RETURNS SETOF achivment_type AS $$
DECLARE
  _result          achivment_type;
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
