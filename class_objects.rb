class Character
  attr_reader :id, :player_character, :name,
                :picture_link, :stat_block_name, :stat_block_link,
                :main_location, :alignment, :ancestory,
                :gender, :short_description
  
  def initialize( id, 
                  player_character, 
                  name, 
                  picture_link, 
                  stat_block_name,
                  stat_block_link, 
                  main_location, 
                  alignment, 
                  ancestory, 
                  gender, 
                  short_description )
      @id = id
      @player_character = player_character
      @name = name
      @picture_link = picture_link
      @stat_block_name = stat_block_name
      @stat_block_link = stat_block_link
      @main_location = main_location
      @alignment = alignment
      @ancestory = ancestory
      @gender = gender
      @short_description = short_description
  end
end

class Interaction
  attr_reader :id, :attitude, :date, :short_description, :full_description

  def initialize( id,
                  attitude,
                  date,
                  short_description,
                  full_description )
    @id = id
    @attitude = attitude
    @date = date
    @short_description = short_description
    @full_description = full_description
  end
end

class User
  attr_reader :id, :username, :email, :status

  def initialize(id, username, email, status)
    @id = id
    @username = username
    @email = email
    @status = status
  end
end
