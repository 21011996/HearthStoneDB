import javafx.util.Pair;
import org.json.JSONObject;

import java.io.*;
import java.util.*;
import java.util.stream.Collectors;

/**
 * @author Ilya239.
 *         Created on 14.01.2017.
 */
public class Main {

    public static void main(String[] args) throws FileNotFoundException {
        HashMap<String, Integer> csores = getScores();
        JSONObject object = null;
        try (BufferedReader reader = new BufferedReader(new FileReader("./cards.json"))) {
            String allSets = reader.lines().collect(Collectors.joining());
            object = new JSONObject(allSets);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        object.remove("Promo");
        object.remove("Reward");
        HashSet<String> clas = new HashSet<>();
        HashSet<String> mechanics = new HashSet<>();
        ArrayList<Card> cards = new ArrayList<>();
        ArrayList<String> sets = new ArrayList<>();
        ArrayList<Pair<Integer, String>> race = new ArrayList<>();
        HashMap<Integer, String> has_mechanic= new HashMap<>();
        ArrayList<Integer> spells = new ArrayList<>();
        ArrayList<Integer> weapons = new ArrayList<>();
        int i = 1;
        for (String setName : object.keySet()) {
            sets.add(setName);
            System.out.println(setName);
            for (Object card1 : object.getJSONArray(setName)) {
                JSONObject card = (JSONObject) card1;
                String playerClass =  card.getString("playerClass");
                String name = card.getString("name");
                String cardSet = setName;
                String flavor = card.getString("flavor");
                String type = card.getString("type");
                cards.add(new Card(name, i, flavor, "0", playerClass, type));
                clas.add(playerClass);
                if (card.has("mechanics")) {
                    for (Object mech : card.getJSONArray("mechanics")) {
                        mechanics.add(((JSONObject) mech).getString("name"));
                        has_mechanic.put(i, ((JSONObject) mech).getString("name"));
                    }
                }
                if (card.has("race")){
                    race.add(new Pair<>(i,card.getString("race")));
                }

                switch (card.getString("type")) {
                    case "Spell" : spells.add(i);
                    break;
                    case "Weapon" : weapons.add(i);
                    break;
                }
                i++;
            }

        }
        /*
        String firstLine = "INSERT INTO class (class_id, class_name) VALUES";
        ArrayList<String> values = new ArrayList<>();
        ArrayList<String> calsses = new ArrayList<>(clas);
        for (int i = 1; i<= clas.size(); i++) {
            values.add("    ("+i+",\'"+calsses.get(i-1)+"\')");
        }
        printInsertion("Class.sql", firstLine, values);
*/
        /*String firstLine = "INSERT INTO mechanics (mechanic_id, mechanic_name) VALUES";
        ArrayList<String> values = new ArrayList<>();
        ArrayList<String> calsses = new ArrayList<>(mechanics);
        for (int i = 1; i<= mechanics.size(); i++) {
            values.add("    ("+i+",\'"+calsses.get(i-1)+"\')");
        }
        printInsertion("Mechanics.sql", firstLine, values);*/
/*
        String firstLine = "INSERT INTO cards (card_id, card_name, card_set_id, card_description, card_score, class_id) VALUES";
        ArrayList<String> calsses = new ArrayList<>(clas);
        ArrayList<String> values = new ArrayList<>();
        for (i = 1; i<= cards.size(); i++) {
            Card card = cards.get(i-1);
            if (csores.containsKey(card.name)) {
                values.add("    (" + i + ",\'" + card.name.replace("'", "''") + "\'," + card.set + ",\'" + card.flavor.replace("\'", " ") + "\'," + csores.get(card.name) + "," + getId(calsses, card.clas) + ")");
            } else {
                values.add("    (" + i + ",\'" + card.name.replace("'", "''") + "\'," + card.set + ",\'" + card.flavor.replace("\'", " ") + "\'," + 0 + "," + getId(calsses, card.clas) + ")");
            }
        }
        printInsertion("Cards.sql", firstLine, values);
*/
        /*
        String firstLine = "INSERT INTO set (set_id, set_name) VALUES";
        ArrayList<String> values = new ArrayList<>();
        for (i = 1; i<= sets.size(); i++) {
            values.add("    ("+i+",\'"+sets.get(i-1)+"\')");
        }
        printInsertion("Sets.sql", firstLine, values);
        */
        /*
        String firstLine = "INSERT INTO has_mechanic (card_id, mechanic_id) VALUES";
        ArrayList<String> values = new ArrayList<>();
        ArrayList<String> calsses = new ArrayList<>(clas);
        for (Map.Entry entry : has_mechanic.entrySet()) {
            values.add("    ("+entry.getKey()+","+getId(new ArrayList<String>(mechanics), (String)entry.getValue())+")");
        }
        printInsertion("Has_mechanic.sql", firstLine, values);
        */
        /*
        String firstLine = "INSERT INTO minions (card_id, race) VALUES";
        ArrayList<String> values = new ArrayList<>();
        ArrayList<String> calsses = new ArrayList<>(clas);
        for (Pair pair : race) {
            values.add("    ("+pair.getKey()+",\'"+pair.getValue()+"\')");
        }
        printInsertion("Minions.sql", firstLine, values);
        */
/*
        String firstLine = "INSERT INTO spells (card_id) VALUES";
        ArrayList<String> values = new ArrayList<>();
        for (Integer id : spells) {
            values.add("    ("+id+")");
        }
        printInsertion("Spells.sql", firstLine, values);*/
/*
        String firstLine = "INSERT INTO weapons (card_id) VALUES";
        ArrayList<String> values = new ArrayList<>();
        for (Integer id : weapons) {
            values.add("    ("+id+")");
        }
        printInsertion("Weapons.sql", firstLine, values);*/
    }

    private static int getId(ArrayList<String> list, String target) {
        for (int i = 1; i<=list.size(); i++) {
            if (list.get(i-1).equals(target))
                return i;
        }
        return 0;
    }

    private static void printInsertion(String filename, String firstLine, List<String> values) throws FileNotFoundException {
        try (PrintWriter writer = new PrintWriter(new File("./sql/", filename))) {
            writer.println(firstLine);
            writer.print(String.join(",\n", values));
            writer.println(";");
        }
    }

    private static HashMap<String, Integer> getScores() throws FileNotFoundException {
        String object = null;
        try (BufferedReader reader = new BufferedReader(new FileReader("./cardTierList.txt"))) {
            object = reader.lines().collect(Collectors.joining());
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        object = object.replace("</li>","</li>\n").replace("&#039;","'");
        try (PrintWriter writer = new PrintWriter(new File("./tierList.txt"))) {
            writer.println(object);
        }
        String[] lines = object.split("</li>");
        HashMap<String, Integer> answer = new HashMap<>();
        for (String line : lines) {
            if (line.contains("score_")) {
                String[] lul = line.split("<dd class=\"score score_");
                String[] lul2 = lul[1].split("\">");
                int score = Integer.parseInt(lul2[0]);

                String[] kek = line.split(".png\">");
                String[] oppo = kek[1].split("</dt>");
                String[] oppo2 = oppo[0].split("<span");
                answer.put(oppo2[0], score);
                System.out.println(oppo2[0]);
            }
        }
        return answer;
    }
}
