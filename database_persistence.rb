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

  def retrieve_single_interaction_id(interaction_hash)
    sql = <<~SQL
      SELECT DISTINCT id FROM interactions
      WHERE attitude = $1
      AND short_description = $2
      AND full_description = $3
    SQL
    result = query(sql, interaction_hash[:attitude], 
                        interaction_hash[:short_description],
                        interaction_hash[:full_description]
                  )
    result.first["id"].to_i
  end

  def add_new_character(character)
    sql = <<~SQL
      INSERT INTO characters (name,
                              player_character,
                              picture_link, 
                              stat_block_name, 
                              stat_block_link, 
                              main_location, 
                              alignment,
                              ancestory,
                              gender, 
                              short_description)
      VALUES ($1, $2, $3, $4,$5, $6, $7, $8, $9, $10)
    SQL
    query( sql, character[:name],
                character[:player_character],
                character[:picture_link],
                character[:stat_block_name],
                character[:stat_block_link],
                character[:main_location],
                character[:alignment],
                character[:ancestory],
                character[:gender],
                character[:short_description]
          )
  end

  def update_character(character, character_id)
    sql = <<~SQL
      UPDATE characters SET
          name = $1,
          picture_link = $2,
          stat_block_name = $3,
          stat_block_link = $4,
          main_location = $5,
          alignment = $6,
          ancestory = $7,
          gender = $8,
          short_description = $9
        WHERE id = $10
    SQL

    query(sql, character[:name],
               character[:picture_link],
               character[:stat_block_name],
               character[:stat_block_link],
               character[:main_location],
               character[:alignment],
               character[:ancestory],
               character[:gender],
               character[:short_description],
               character_id.to_i
          )
  end

  def delete_character(id)
    sql = "DELETE FROM characters WHERE id = $1"
    query(sql, id)
  end

  def delete_interaction(id)
    sql = "DELETE FROM interactions WHERE id = $1"
    query(sql, id)
  end

  def add_new_interaction(interaction)
    sql = <<~SQL
      INSERT INTO interactions (attitude, date, short_description, full_description) 
        VALUES ($1, $2, $3, $4)
    SQL
    
    query(sql, interaction[:attitude], 
               interaction[:date], 
               interaction[:short_description],
               interaction[:full_description]
          )
  end

  def update_interaction(interaction, interaction_id)  
    # if any charcters removed from interaction, must delete their related entries from cross-reference table
    sql = <<~SQL
      UPDATE interactions SET
        attitude = $1,
        date = $2,
        short_description = $3,
        full_description = $4
      WHERE id = $5
    SQL
    query(sql, interaction[:attitude],
               interaction[:date],
               interaction[:short_description],
               interaction[:full_description],
               interaction_id
          )
  end

  # delete current entries in characters_interactions that contain all character_id && interaction_id
  def remove_interaction_entries_from_characters_interactions(interaction_id)
    sql = <<~SQL
      DELETE FROM characters_interactions WHERE interaction_id = $1
    SQL

    query(sql, interaction_id)
  end
  
  # add entries to characters_interactions with for all new character_id with the interaction_id
  def add_interaction_entries_to_characters_interactions(involved_character_ids, interaction_id)
    sql = <<~SQL
      INSERT INTO characters_interactions(interaction_id, character_id)
      VALUES ($1, $2)
    SQL

    involved_character_ids.each { |character_id| query(sql, interaction_id, character_id)}
  end

  def add_interaction_to_cross_reference_table(interaction_id, involved_character_ids)
    sql = <<~SQL
      INSERT INTO characters_interactions (character_id, interaction_id)
        VALUES ($1, $2)
    SQL

    involved_character_ids.each { |character_id| query(sql, character_id, interaction_id) }
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
