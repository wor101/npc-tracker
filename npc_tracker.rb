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
  def load_character_objects(array_of_character_hashes)
    array_of_character_hashes.map do |character_hash|
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
    load_character_objects(@storage.retrieve_single_interaction_characters(interaction_id))
  end

  def create_new_npc(npc_hash)
    @storage.add_new_npc(npc_hash)
  end

  def delete_npc(npc_id)
    @storage.delete_npc(npc_id)
  end
end

# home page
get "/" do  
  erb :home
end

# list all npcs
get "/npcs" do  
  @all_characters = load_character_objects(@storage.retrieve_all_characters)
  @npcs = @all_characters.select { |character| character.player_character == false }
  erb :npcs, layout: :layout
end

# forms to create a new npc
get "/npcs/new" do

  erb :npc_new, layout: :layout
end

# submit and create a new pc
post "/npcs/new" do
  npc_hash = { name: params[:name],
    picture_link: params[:picture_link],
    stat_block_name: params[:stat_block_name],
    stat_block_link: params[:stat_block_link],
    main_location: params[:main_location],
    alignment: params[:alignment],
    ancestory: params[:ancestory],
    short_description: params[:short_description] }

  create_new_npc(npc_hash)

  redirect "/npcs"
end

# delete an npc from the database
post "/npcs/:id/delete" do
  npc_id = params[:id]
  delete_npc(npc_id)

  #need to implement session messages
  redirect "/npcs"
end

# display a single npc
get "/npcs/:id" do
  npc_id = params[:id]
  @npc = load_character_objects(@storage.retrieve_single_character(npc_id)).first
  @npc_interactions = load_interaction_objects(@storage.retrieve_single_character_interactions(npc_id))

  erb :npc, layout: :layout
end

# list all pcs
get "/pcs" do  
  @all_characters = load_character_objects(@storage.retrieve_all_characters)
  @pcs = @all_characters.select { |character| character.player_character == true }
  erb :pcs, layout: :layout
end

# display a single pc
get "/pcs/:id" do
  pc_id = params[:id]
  @pc = load_character_objects(@storage.retrieve_single_character(pc_id)).first
  @pc_interactions = load_interaction_objects(@storage.retrieve_single_character_interactions(pc_id))

  erb :pc, layout: :layout
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
  @interaction_npcs = load_character_objects(@storage.retrieve_single_interaction_characters(interaction_id))
  erb :interaction, layout: :layout
end


