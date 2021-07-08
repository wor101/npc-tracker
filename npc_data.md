***npc data***
INSERT INTO characters (name, main_location, alignment, gender, ancestory, stat_block_name, short_description) VALUES
('Almina Mastonen', 6, 'Chaotic Neutral', 'female', 'halfling', 'spy', 'Runs a crew of burglars calling themselves the Black Cats. She works at the East Gate inn.'),
('Bernhard ''Badger'' Ilmatoivia', 15, 'Lawful Neutral', 'male', 'human', 'knight', 'Maintains a good reputation as a man of character. This ex-adventurer runs Badger''s and is rumoured to be fabulously wealthy.'),
('Henni Eronen', 8, 'Chaotic Good', 'female', 'human', 'scout', 'Runs Eronen''s Safe Travels. A former adventurer, Henni is extremely knowledgeable about the town’s surrounds.'),
('Kerttuli Ilmarinen', 14, 'Neutral Evil', 'female', 'human', 'Braalite priest', 'Works at the Crooked House by day and venerates Braal by night in the house''s deepest, mould-ridden cellar.'),
('Nalhra Rekunen', 5, 'True Neutral', 'female', 'half-elf', 'commoner', 'Frequently seeks precious gems to work into pieces of art, but is renowned for not offering good prices. Nalthra is a renowned jeweller.'),
('Nurlon Rekunen', 4, 'Lawful Good', 'male', 'half-elf', 'veteran', 'Runs the Dancing Bear which caters to adventurers and travellers. He is a former adventurer and Nalthra’s twin.'),
('Orkus Darzak', 11, 'Chaotic Evil', 'male', 'dwarf', 'priest', 'Worships Braal by animating the dead of Dulwich. Driven insane while adventuring in Gloamhold, Orkus lurks in the tunnels and catacombs beneath the cemetery.'),
('Ossi Karppanen', 3, 'Lawful Neutral', 'male', 'human', 'commoner', 'Leads the lumber guild, and seeks to instate a ruling council of merchants. He is one of Dulwich''s richest citizens, and consequently has much power and influence.'),
('Saini Alanen', 9, 'Neutral Good', 'female', 'human', 'wizard', 'Oversees a small, independent library where she conducts research on the local area and assists in political matters.'),
('Tuula Tenhunen', 1, 'Lawful Neutral', 'female', 'half-orc', 'knight', 'Leads the town guard and is fiercely loyal to Wido Gall. She has the nick-name the “Iron Maiden” due to the mask she always wears.'),
('Valto Ilakka', 16, 'Neutral Evil', 'male', 'human', 'assassin', 'Runs the Three Bells, and is a mass murderer who preys on patrons that won''t be missed.'),
('Voitto Markku', 7, 'Lawful Evil', 'male', 'human', 'spy', 'Leads the Shadow Spiders. He is an odious, dangerous fellow.'),
('Vuokko Laiten', 2, 'Lawful Neutral', 'female', 'human', 'priest', 'Serves as Conn''s high priestess in Dulwich, She is young for the role, and some see her as unsuitable. Both Wido Gall and the merchants vie for her favour.'),
('Wido Gall', 1, 'Lawful Neutral', 'male', 'human', 'mage', 'Rules  Dulwich.  He seeks to extend his influence to the nearby village of Longbridge, at the expense of his rivals.'),
('Zado', 11, 'Chaotic Neutral', 'male', 'human', 'unknown', 'Plies his trade in the marketplace as a street performer or, perhaps, street performers. However, this enigmatic performer''s real trade is in secrets and information.');

***interaction data***
INSERT INTO interactions (attitude, short_description, full_description) VALUES
('hostile', 'Illicit Rivalry', 'Almina''s gang the Black Cats is being pressured by the Shadow Spiders, led by Voitto Markku, to give them a portion of their ill gotten gains. She wishes to see the Shadowspiders undone.'),
('friendly', 'Loyal Servant', 'Tuula leads the town guard and is fiercly loyal to the ruler of Dulwhich Wido Gall.'),
('hostile', 'Political Rivalry', 'Ossi seeks to instate a ruling council of merchants in Dulwhich and remove Wido Gall from power.'),
('indifferent', 'Stuck Between Political Rivals', 'Both the merchants led by Ossi and the ruler Wido Gall seek Vuokko''s endorsment as high priestess of Conn in order to consolidate power.');

***npc_interactions data***
INSERT INTO characters_interactions (character_id, interaction_id) VALUES
(1, 1),
(12, 1),
(10, 2),
(14, 2),
(8, 3),
(14, 3),
(13, 4),
(8, 4),
(14, 4);