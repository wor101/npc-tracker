require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "pry"

require_relative "database_persistence"
require_relative "class_objects"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
  also_reload "class_objects.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

helpers do
  def load_npc_objects(array_of_character_hashes)
    array_of_character_hashes.map do |character_hash|
      next if character_hash[:player_character] == "true"
      NonPlayerCharacter.new( character_hash[:id].to_i, 
                              character_hash[:player_character],
                              character_hash[:name],
                              character_hash[:picture_link],
                              character_hash[:stat_block_name],
                              character_hash[:main_location],
                              character_hash[:alignment],
                              character_hash[:ancestory],
                              character_hash[:gender],
                              character_hash[:short_description]
      )
    end
  end

  def load_interaction_objects(array_of_interaction_hashses)
    array_of_interaction_hashses.map do |interaction_hash|

      Interaction.new( interaction_hash[:id],
                       interaction_hash[:attitude],
                       interaction_hash[:date],
                       interaction_hash[:short_description],
                       interaction_hash[:full_description]                       
      )      
    end
  end

  def load_interaction_involved_character_objects(interaction_id)
    load_npc_objects(@storage.retrieve_single_interaction_characters(interaction_id))
  end
end

# home page
get "/" do  
  erb :home
end

# list all npcs
get "/npcs" do
  @npcs = load_npc_objects(@storage.retrieve_all_characters)
  erb :npcs, layout: :layout
end

# display a single npc
get "/npcs/:id" do
  npc_id = params[:id]
  @npc = load_npc_objects(@storage.retrieve_single_character(npc_id)).first
  @npc_interactions = load_interaction_objects(@storage.retrieve_single_character_interactions(npc_id))


  erb :npc, layout: :layout
end

# list all interactions
get "/interactions" do
  @interactions = load_interaction_objects(@storage.retrieve_all_interactions)
  erb :interactions, layout: :layout
end

# display a single interaction
get "/interactions/:id" do
  interaction_id = params[:id].to_i
  @interaction = load_interaction_objects(@storage.retrieve_single_interaction(interaction_id)).first
  # need to implement retrieve_single_interaction_characters(id) in database_persistence
  @interaction_npcs = load_npc_objects(@storage.retrieve_single_interaction_characters(interaction_id))
  erb :interaction, layout: :layout
end


