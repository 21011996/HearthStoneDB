CREATE INDEX card_name_index
  ON cards USING BTREE (card_name); -- hash
CREATE INDEX card_set_index
  ON cards USING BTREE (card_set_id); -- hash

CREATE INDEX minions_race_index
  ON minions USING BTREE (race); -- hash

CREATE INDEX deck_name_index
  ON decks USING BTREE (deck_name); -- hash
CREATE INDEX deck_class_id_index
  ON decks USING BTREE (class_id); -- hash

CREATE INDEX participated_index
  ON participated USING BTREE (tournament_id);

CREATE INDEX has_mechanic_card_id_index
  ON has_mechanic USING BTREE (card_id);

CREATE INDEX heroes_class_index
  ON class USING BTREE (class_name); -- hash

CREATE INDEX in_deck_card_id_index
  ON in_deck USING BTREE (card_id);

CREATE INDEX players_country_index
  ON players USING BTREE (player_country); -- hash