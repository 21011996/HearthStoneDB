--decks containing cards from all sets in standard rotation
SELECT deck_name
FROM
  decks
EXCEPT
SELECT decks_q.deck_name
FROM
  (SELECT
     deck_name,
     set_name_q.set_name
   FROM decks
     CROSS JOIN
     (SELECT set_name
      FROM set
        NATURAL JOIN standard_rotation) AS set_name_q
   EXCEPT SELECT
            deck_name,
            set_name
          FROM set
            NATURAL JOIN standard_rotation
            JOIN cards ON set.set_id = cards.card_set_id
            JOIN in_deck ON cards.card_id = in_deck.card_id
            JOIN decks ON in_deck.deck_id = decks.deck_id) AS decks_q;

--Cards that are in all decks
SELECT
  card_name,
  card_description,
  card_score
FROM cards
WHERE card_id IN
      (SELECT card_id
       FROM
         in_deck
         JOIN decks ON in_deck.deck_id = decks.deck_id
       EXCEPT
       SELECT cards_q.card_id
       FROM
         (SELECT
            cards_q.card_id,
            deck_name_q.deck_name
          FROM
            (SELECT card_id
             FROM in_deck
               JOIN decks ON in_deck.deck_id = decks.deck_id) AS cards_q
            CROSS JOIN
            (SELECT deck_name
             FROM decks) AS deck_name_q
          EXCEPT SELECT
                   card_id,
                   deck_name
                 FROM in_deck
                   JOIN decks ON in_deck.deck_id = decks.deck_id) AS cards_q);

--Sets stat
SELECT DISTINCT
  set_name,
  count(set_id) AS counter
FROM decks
  JOIN in_deck ON decks.deck_id = in_deck.deck_id
  JOIN cards ON in_deck.card_id = cards.card_id
  JOIN set ON cards.card_set_id = set.set_id
GROUP BY set_name
ORDER BY counter DESC;
