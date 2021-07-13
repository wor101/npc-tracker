CREATE TABLE characters (
  id serial PRIMARY KEY,
  player_character boolean DEFAULT false,
  name varchar(150) NOT NULL,
  picture_link text,
  stat_block_name varchar(150),
  stat_block_link text,
  main_location int,
  alignment varchar(50) CHECK (alignment IN ('Lawful Good', 'Lawful Neutral', 'Lawful Evil', 'Neutral Good', 'True Neutral', 'Neutral Evil', 'Chaotic Good', 'Chaotic Neutral', 'Chaotic Evil')),
  ancestory varchar(150),
  gender varchar(150),
  short_description text
);

CREATE TABLE characters_interactions (
  id serial PRIMARY KEY,
  character_id integer NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  interaction_id integer NOT NULL REFERENCES interactions(id) ON DELETE CASCADE
);

CREATE TABLE interactions (
  id serial PRIMARY KEY,
  attitude varchar(25) CHECK (attitude IN ('friendly', 'indifferent', 'hostile')),
  date timestamp DEFAULT CURRENT_TIMESTAMP,
  short_description varchar(250) NOT NULL,
  full_description text
);