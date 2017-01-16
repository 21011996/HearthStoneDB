CREATE INDEX mechanics_name_index
  ON mechanics USING BTREE (mechanic_name);

CREATE INDEX card_name_index
  ON cards USING BTREE (card_name);

CREATE INDEX minions_race_index
  ON minions USING BTREE (race);

CREATE INDEX deck_name_index
  ON decks USING BTREE (deck_name);

CREATE INDEX has_mechanic_cardid_mechanic_index
  ON has_mechanic USING BTREE (card_id, mechanic_id);

CREATE INDEX has_mechanic_mechanic_cardid_index
  ON has_mechanic USING BTREE (mechanic_id, card_id);

CREATE INDEX in_deck_cardid_deckid_index
  ON in_deck USING BTREE (card_id, deck_id);

CREATE INDEX in_deck_deckid_cardid_index
  ON in_deck USING BTREE (deck_id, card_id);

CREATE INDEX heroes_class_index
  ON class USING BTREE (class_name);

CREATE INDEX country_index
  ON country USING BTREE (country_name);