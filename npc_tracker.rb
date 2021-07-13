require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "pry"
require 'bcrypt'

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
      Character.new( character_hash[:id].to_i, 
                              character_hash[:player_character],
                              character_hash[:name],
                              character_hash[:picture_link],
                              character_hash[:stat_block_name],
                              character_hash[:stat_block_link],
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

  def create_new_character(character_hash)
    @storage.add_new_character(character_hash)
    session[:success] = "#{character_hash[:name]} has been created."
  end

  def delete_character(character_id)
    @storage.delete_character(character_id)
  end

  def confirm_character_deleted(id)
    if @storage.retrieve_single_character(id).empty?
      session[:success] = "Character succesfully deleted."
    else
      name = @storage.retrieve_single_character(id)[:name]
      session[:error] = "ERROR: #{name} was not deleted."
    end
  end

  def confirm_interaction_deleted(interaction_id)
    if @storage.retrieve_single_interaction(interaction_id).empty?
      session[:success] = "Interaction succesfully deleted."
    else
      @storage.retrieve_single_interaction(interaction_id)[:short_description]
      session[:error] = "ERROR: #{short_description} was not deleted."
    end
  end

  def create_new_interaction(interaction_hash)
    @storage.add_new_interaction(interaction_hash)
    interaction_id = @storage.retrieve_single_interaction_id(interaction_hash)
    @storage.add_interaction_to_cross_reference_table(interaction_id, interaction_hash[:involved_characters])
    session[:success] = "#{interaction_hash[:short_description]} created succesfully."
  end

  def delete_interaction(interaction_id)
    @storage.delete_interaction(interaction_id)
  end

  def update_interaction(interaction_hash, interaction_id, involved_character_ids)
    # updates interaction but not involved parties
    @storage.update_interaction(interaction_hash, interaction_id)
  
    # delete current entries in characters_interactions that contain all character_id && interaction_id
    @storage.remove_interaction_entries_from_characters_interactions(interaction_id)
  
    # add entries to characters_interactions with for all new character_id with the interaction_id
    @storage.add_interaction_entries_to_characters_interactions(involved_character_ids, interaction_id)
  end

  def validate_character_hash(npc_hash)
    if npc_hash[:name].empty? 
      session[:error] = "NPC must be assigned a valid name."
      false
    else
      true
    end
  end

  def validate_interactions_hash(interaction_hash)
    if interaction_hash[:involved_characters].empty? 
      session[:error] = "A character must be selected for the interaction."
      false
    elsif interaction_hash[:short_description].empty?
      session[:error] = "Interaction must include a short description."
      false
    else
      true
    end
  end

  def convert_params_to_npc_hash
    { name: params[:name].strip,
    player_character: false,
    picture_link: params[:picture_link],
    stat_block_name: params[:stat_block_name].strip,
    stat_block_link: params[:stat_block_link],
    main_location: params[:main_location].to_i,
    alignment: params[:alignment],
    ancestory: params[:ancestory].strip,
    gender: params[:gender].strip,
    short_description: params[:short_description].strip }
  end

  def convert_params_to_pc_hash
    { name: params[:name].strip,
    player_character: true,
    picture_link: params[:picture_link],
    stat_block_name: params[:stat_block_name].strip,
    stat_block_link: params[:stat_block_link],
    main_location: params[:main_location].to_i,
    alignment: params[:alignment],
    ancestory: params[:ancestory].strip,
    gender: params[:gender].strip,
    short_description: params[:short_description].strip }
  end

  def convert_params_to_interaction_hash
    { attitude: params["attitude"], date: params["date"], 
      short_description: params["short_description"], 
      full_description: params["full_description"],
      involved_characters: params["involved_characters"]}
  end

  def signed_in?
    session[:username] == nil ? false : true
  end
  
  def admin_rights?
    username = session[:username]
    user_status = @storage.retrieve_user_status(username) 
    user_status == "admin"
  end
  
  def redirect_to_login
    session[:error] = 'You must be signed in to do that.'
    redirect '/login'
  end

  def valid_username?(username)
    existing_usernames = @storage.retrieve_usernames
    if existing_usernames.include?(username) 
      session[:error] = "Username #{username} already exists"
      false
    else
      true
    end
  end
  
  def valid_password?(password1, password2)
    if password1 == password2
      true
    else
      session[:error] = 'Both passwords must match.'
      false
    end
  end

  def valid_credentials?(username, password)
    user_details = @storage.retrieve_user_details(username)

    return false if user_details == nil
  
    bcrypt_password = BCrypt::Password.new(user_details[:password])
    bcrypt_password == password
  end
  
  def create_pending_user(username, password, email)
    @storage.add_pending_user(username, password, email)
  end

end

# home page
get "/" do  
  redirect_to_login unless signed_in?
  erb :home
end

# display login page
get "/login" do

  erb :login, layout: :layout
end

# submit login request
post "/login" do
  if valid_credentials?(params[:username], params[:password])
    session[:username] = params[:username]
    session[:signed_in] = true

    session[:success] = "Welcome #{session[:username]}!"
    redirect '/'
  else
    session[:temp_user] = params[:username]
    session[:error] = 'Invalid Credentials'
    status 422

    erb :login
  end
end

# submit logout request
post '/logout' do
  session[:signed_in] = false
  session[:username] = nil
  session[:success] = "User has logged out"
  redirect '/login'
end

# display new user form
get "/new_user" do

  erb :new_user, layout: :layout
end

# create and add new user to database
post "/new_user" do
  username = params[:username]
  redirect '/new_user' unless valid_username?(username)
  redirect '/new_user' unless valid_password?(params[:password], params[:password_match])

  bcrypt_password = BCrypt::Password.create(params[:password])
  create_pending_user(username, bcrypt_password, params[:email])

  redirect '/login'
end

# list all npcs
get "/npcs" do  
  @all_characters = load_character_objects(@storage.retrieve_all_characters)
  @npcs = @all_characters.select { |character| character.player_character == false }
  erb :npcs, layout: :layout
end

# display form to create a new npc
get "/npcs/new" do

  erb :npc_new, layout: :layout
end

# create a new npc in the database
post "/npcs/new" do
  npc_hash = convert_params_to_npc_hash

  redirect "/npcs/new" unless validate_character_hash(npc_hash)
  create_new_character(npc_hash)

  redirect "/npcs"
end

# delete an npc from the database
post "/npcs/:id/delete" do
  npc_id = params[:id]
  delete_character(npc_id)

  confirm_character_deleted(npc_id)

  session[:success] = "NPC successfully deleted."
  redirect "/npcs"
end

# display form to update an npc
get "/npcs/:id/update" do
  npc_id = params[:id]
  @npc = load_character_objects(@storage.retrieve_single_character(npc_id)).first

  if @npc
    erb :npc_update, layout: :layout
  else
    session[:error] = "NPC id #{npc_id} does not exist"
    redirect '/npcs'
  end
end

# update an existing npc
post "/npcs/:id/update" do
  npc_id = params[:id].to_i
  npc_hash = convert_params_to_npc_hash

  redirect "/npcs/#{npc_id}/update" unless validate_character_hash(npc_hash)

  @storage.update_character(npc_hash, npc_id)
  session[:success] = "#{npc_hash[:name]} has been updated!"
  redirect "/npcs/#{npc_id}"
end

# display a single npc
get "/npcs/:id" do
  npc_id = params[:id].to_i
  @npc = load_character_objects(@storage.retrieve_single_character(npc_id)).first
  
  if @npc
    @npc_interactions = load_interaction_objects(@storage.retrieve_single_character_interactions(npc_id))

    erb :npc, layout: :layout
  else
    session[:error] = "NPC id #{npc_id} does not exist"
    redirect '/npcs'
  end
end

# list all pcs
get "/pcs" do  
  @all_characters = load_character_objects(@storage.retrieve_all_characters)
  @pcs = @all_characters.select { |character| character.player_character == true }
  erb :pcs, layout: :layout
end

# display form to create a new pc
get "/pcs/new" do

  erb :pc_new, layout: :layout
end

# create a new pc in the database
post "/pcs/new" do
  pc_hash = convert_params_to_pc_hash

  redirect "/pcs/new" unless validate_character_hash(pc_hash)
  create_new_character(pc_hash)

  redirect "/pcs"
end

# delete an pc from the database
post "/pcs/:id/delete" do
  pc_id = params[:id]
  delete_character(pc_id)

  confirm_character_deleted(pc_id)

  session[:success] = "PC successfully deleted."
  redirect "/pcs"
end

# display form to update a pc
get "/pcs/:id/update" do
  pc_id = params[:id]
  @pc = load_character_objects(@storage.retrieve_single_character(pc_id)).first

  if @pc
    erb :pc_update, layout: :layout
  else
    session[:error] = "PC id #{pc_id} does not exist"
    redirect '/pcs'
  end
end

# update an existing pc
post "/pcs/:id/update" do
  pc_id = params[:id].to_i
  pc_hash = convert_params_to_pc_hash

  redirect "/pcs/#{pc_id}/update" unless validate_character_hash(pc_hash)

  @storage.update_character(pc_hash, pc_id)
  session[:success] = "#{pc_hash[:name]} has been updated!"
  redirect "/pcs/#{pc_id}"
end

# display a single pc
get "/pcs/:id" do
  pc_id = params[:id]
  @pc = load_character_objects(@storage.retrieve_single_character(pc_id)).first

  if @pc
    @pc_interactions = load_interaction_objects(@storage.retrieve_single_character_interactions(pc_id))

    erb :pc, layout: :layout
  else
    session[:error] = "PC id #{pc_id} does not exist"
    redirect '/pcs'
  end
end

# list all interactions
get "/interactions" do
  @interactions = load_interaction_objects(@storage.retrieve_all_interactions)
  erb :interactions, layout: :layout
end

# display form to create new interaction
get "/interactions/new" do
  @characters = load_character_objects(@storage.retrieve_all_characters)

  erb :interaction_new, layout: :layout
end

# create and add new interaction to database
post "/interactions/new" do
  interaction_hash = convert_params_to_interaction_hash
  redirect "/interactions/new" unless validate_interactions_hash(interaction_hash)
  create_new_interaction(interaction_hash)

  redirect "/interactions"
end

# delete an interaction
post "/interactions/:id/delete" do
  interaction_id = params[:id]
  delete_interaction(interaction_id)

  confirm_interaction_deleted(interaction_id)

  session[:success] = "Interaction successfully deleted."
  redirect "/interactions"
end

# display form to update an interaction
get "/interactions/:id/update" do
  interaction_id = params[:id]
  @interaction = load_interaction_objects(@storage.retrieve_single_interaction(interaction_id)).first

  if @interaction
    involved_characters = load_interaction_involved_character_objects(interaction_id)
    @involved_character_ids = involved_characters.map { |character| character.id }

    @characters = load_character_objects(@storage.retrieve_all_characters)

    erb :interaction_update, layout: :layout
  else
    session[:error] = "Interaction id #{interaction_id} does not exist"
    redirect '/interactions'
  end
end

# update an existing interaction
post "/interactions/:id/update" do
  interaction_id = params[:id].to_i
  interaction_hash = convert_params_to_interaction_hash
  involved_character_ids = params[:involved_characters]

  redirect "/interactions/#{interaction_id}/update" unless validate_interactions_hash(interaction_hash)

  update_interaction(interaction_hash, interaction_id, involved_character_ids)

  session[:success] = "#{interaction_hash[:short_description]} has been updated!"
  redirect "/interactions/#{interaction_id}"
end

# display a single interaction
get "/interactions/:id" do
  interaction_id = params[:id].to_i
  @interaction = load_interaction_objects(@storage.retrieve_single_interaction(interaction_id)).first

  if @interaction
    @interaction_npcs = load_character_objects(@storage.retrieve_single_interaction_characters(interaction_id))

    erb :interaction, layout: :layout
  else
    session[:error] = "Interaction id #{interaction_id} does not exist"
    redirect '/interactions'
  end
end


