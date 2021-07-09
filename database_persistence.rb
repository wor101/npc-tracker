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

  def retrieve_all_characters
    sql = "SELECT * FROM characters"
    result = query(sql)

    convert_character_pg_to_array_of_hashes(result)
  end

  def retrieve_single_character(id)
    sql = "SELECT * FROM characters WHERE id = $1"
    result = query(sql, id)
    convert_character_pg_to_array_of_hashes(result)
  end

  def retrieve_all_interactions
    sql = "SELECT * FROM interactions"
    result = query(sql)

    convert_interaction_pg_to_array_of_hashes(result)
  end

  def retrieve_single_interaction(id)
    sql = "SELECT * FROM interactions WHERE id = $1"
    result = query(sql, id)
    
    convert_interaction_pg_to_array_of_hashes(result)
  end

  private

  def convert_character_pg_to_array_of_hashes(character_pg)
    character_pg.map do |tuple|
      { id: tuple["id"].to_i, 
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
  end

  def convert_interaction_pg_to_array_of_hashes(interaction_pg)
    interaction_pg.map do |tuple|
      { id: tuple["id"].to_i,
        attitude: tuple["attitude"],
        date: tuple["date"],
        short_description: tuple["short_description"],
        full_description: tuple["full_description"] }
    end
  end
end
