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

  def retrieve_single_character_interactions(character_id)
    sql = <<~SQL
      SELECT interactions.* FROM interactions
      JOIN characters_interactions ON characters_interactions.interaction_id = interactions.id
      WHERE characters_interactions.character_id = $1
    SQL
    result = query(sql, character_id)

    convert_interaction_pg_to_array_of_hashes(result)
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

  def retrieve_single_interaction_characters(interaction_id)
    sql = <<~SQL
      SELECT characters.* FROM characters
      JOIN characters_interactions ON characters_interactions.character_id = characters.id
      WHERE characters_interactions.interaction_id = $1
    SQL
    result = query(sql, interaction_id)

    convert_character_pg_to_array_of_hashes(result)
  end

  def add_new_npc(npc)
    sql = <<~SQL
      INSERT INTO characters (name, 
                              picture_link, 
                              stat_block_name, 
                              stat_block_link, 
                              main_location, 
                              alignment,
                              ancestory,
                              gender, 
                              short_description)
      VALUES ($1, $2, $3, $4,$5, $6, $7, $8, $9)
    SQL
    query( sql, npc[:name], 
                npc[:picture_link],
                npc[:stat_block_name],
                npc[:stat_block_link],
                npc[:main_location],
                npc[:alignment],
                npc[:ancestory],
                npc[:gender],
                npc[:short_description] )
  end

  def delete_npc(id)
    sql = "DELETE FROM characters WHERE id = $1"
    query(sql, id)
  end


  private

  def convert_character_pg_to_array_of_hashes(character_pg)
    character_pg.map do |tuple|
      { id: tuple["id"].to_i, 
        player_character: tuple["player_character"] == "t",
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
