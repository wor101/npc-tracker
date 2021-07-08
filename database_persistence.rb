require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "npc_tracker")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def test_method
    "Test successful!"
  end

  def load_all_characters
    sql = "SELECT * FROM characters"
    result = query(sql)

    result.map do |tuple|
      { id: tuple["id"], 
        player_character: tuple["player_character"] == true,
        name: tuple["name"],
        picture_link: tuple["picture_link"],
        stat_block_name: tuple["stat_block_name"],
        stat_block_link: tuple["stat_block_link"],
        main_location: tuple["main_location"].to_i,
        alignment: tuple["alignment"],
        ancestory: tuple["ancestory"],
        gender: tuple["gender"],
        short_description: tuple["short_description"] }
    end

#     CREATE TABLE characters (
#   id serial PRIMARY KEY,
#   player_character boolean DEFAULT false,
#   name varchar(150) NOT NULL,
#   picture_link text,
#   stat_block_name varchar(150),
#   stat_block_link text,
#   main_location int,
#   alignment varchar(50) CHECK (alignment IN ('Lawful Good', 'Lawful Neutral', 'Lawful Evil', 'Neutral Good', 'True Neutral', 'Neutral Evil', 'Chaotic Good', 'Chaotic Neutral', 'Chaotic Evil')),
#   ancestory varchar(150),
#   gender varchar(150),
#   short_description text
# );

  end

end