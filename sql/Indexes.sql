CREATE INDEX card_name_index ON cards USING btree (card_name); -- hash
CREATE INDEX card_set_index ON cards USING btree (card_set_id); -- hash

CREATE INDEX minions_race_index ON minions USING btree (race); -- hash

CREATE INDEX deck_name_index ON decks USING btree (deck_name); -- hash
CREATE INDEX deck_class_id_index ON decks USING btree (class_id); -- hash

CREATE INDEX participated_index ON participated USING btree (tournament_id);

CREATE INDEX has_mechanic_card_id_index ON has_mechanic USING btree (card_id);

CREATE INDEX heroes_class_index ON class USING btree (class_name); -- hash

CREATE INDEX in_deck_card_id_index ON in_deck USING btree (card_id);

CREATE INDEX players_score_index ON players USING btree (player_score);
CREATE INDEX players_country_index ON players USING btree (player_country);