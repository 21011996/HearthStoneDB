SELECT *
FROM get_player_achievements('Pavel');

SELECT *
FROM get_deck_wins(1)
  CROSS JOIN get_deck_loses(1);