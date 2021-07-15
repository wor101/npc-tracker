# frozen_string_literal: true

require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'pry'
require 'bcrypt'

require_relative 'database_persistence'
require_relative 'class_objects'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistence.rb'
  also_reload 'class_objects.rb'
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
      Character.new(character_hash[:id].to_i,
                    character_hash[:player_character],
                    character_hash[:name],
                    character_hash[:picture_link],
                    character_hash[:stat_block_name],
                    character_hash[:stat_block_link],
                    character_hash[:main_location],
                    character_hash[:alignment],
                    character_hash[:ancestory],
                    character_hash[:gender],
                    character_hash[:short_description])
    end
  end

  def load_interaction_objects(array_of_interaction_hashses)
    array_of_interaction_hashses.map do |interaction_hash|
      Interaction.new(interaction_hash[:id],
                      interaction_hash[:attitude],
                      interaction_hash[:date],
                      interaction_hash[:short_description],
                      interaction_hash[:full_description])
    end
  end

  def load_interaction_involved_character_objects(interaction_id)
    load_character_objects(@storage.retrieve_single_interaction_characters(interaction_id))
  end

  def load_user_objects(array_of_user_hashes)
    array_of_user_hashes.map do |user_hash|
      User.new(user_hash[:id],
               user_hash[:username],
               user_hash[:email],
               user_hash[:status])
    end
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
      session[:success] = 'Character succesfully deleted.'
    else
      name = @storage.retrieve_single_character(id)[:name]
      session[:error] = "ERROR: #{name} was not deleted."
    end
  end

  def confirm_interaction_deleted(interaction_id)
    if @storage.retrieve_single_interaction(interaction_id).empty?
      session[:success] = 'Interaction succesfully deleted.'
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
      session[:error] = 'NPC must be assigned a valid name.'
      false
    else
      true
    end
  end

  def validate_interactions_hash(interaction_hash)
    if interaction_hash[:involved_characters].empty?
      session[:error] = 'A character must be selected for the interaction.'
      false
    elsif interaction_hash[:short_description].empty?
      session[:error] = 'Interaction must include a short description.'
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
    { attitude: params['attitude'], date: params['date'],
      short_description: params['short_description'],
      full_description: params['full_description'],
      involved_characters: params['involved_characters'] }
  end

  def signed_in?
    session[:username].nil? ? false : true
  end

  def admin_rights?
    username = session[:username]
    user_status = @storage.retrieve_user_status(username)
    user_status == 'admin'
  end

  def user_rights?
    username = session[:username]
    user_status = @storage.retrieve_user_status(username)
    %w[user admin].include?(user_status)
  end

  def redirect_to_login
    session[:error] = 'You must be signed in to do that.'
    redirect '/login'
  end

  def redirect_no_admin_rights
    session[:error] = 'You must have admin rights to perform that action'
    redirect '/'
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

    return false if user_details.nil?

    bcrypt_password = BCrypt::Password.new(user_details[:password])
    bcrypt_password == password
  end

  def create_pending_user(username, password, email)
    @storage.add_pending_user(username, password, email)
  end
end

# home page
get '/' do
  redirect_to_login unless signed_in?
  erb :home
end

# display login page
get '/login' do
  erb :login, layout: :layout
end

# submit login request
post '/login' do
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
  session[:success] = 'User has logged out'
  redirect '/login'
end

# display new user form
get '/new_user' do
  erb :new_user, layout: :layout
end

# create and add new user to database
post '/new_user' do
  username = params[:username]
  redirect '/new_user' unless valid_username?(username)
  redirect '/new_user' unless valid_password?(params[:password], params[:password_match])

  bcrypt_password = BCrypt::Password.create(params[:password])
  create_pending_user(username, bcrypt_password, params[:email])
  session[:success] = "User #{username} has been created!"

  redirect '/login'
end

# display all users (admin only)
get '/users' do
  if admin_rights?
    @users = load_user_objects(@storage.retrieve_all_user_details_minus_password)

    erb :users, layout: :layout
  else
    redirect_no_admin_rights
  end
end

# approve and update user status to user
post '/users/:id/approve' do
  if admin_rights?
    user_id = params[:id].to_i

    @storage.update_user_status_to_user(user_id)

    session[:success] = 'User approved and granted user status'
    redirect '/users'
  else
    redirect_no_admin_rights
  end
end

# make a current user with 'user' status an admin
post '/users/:id/admin' do
  if admin_rights?
    user_id = params[:id].to_i

    @storage.update_user_status_to_admin(user_id)
    session[:success] = 'User has been made admin'
    redirect '/users'
  else
    redirect_no_admin_rights
  end
end

# reject and remove user from database
post '/users/:id/reject' do
  if admin_rights?
    user_id = params[:id].to_i

    @storage.remove_user_from_database(user_id)

    session[:success] = 'User removed from database'
    redirect '/users'
  else
    redirect_no_admin_rights
  end
end

# list all npcs
get '/npcs' do
  @all_characters = load_character_objects(@storage.retrieve_all_characters)
  @npcs = @all_characters.select { |character| character.player_character == false }
  erb :npcs, layout: :layout
end

# display form to create a new npc
get '/npcs/new' do
  if user_rights?
    erb :npc_new, layout: :layout
  else
    session[:error] = 'You must have user rights to create a new NPC'
    redirect '/npcs'
  end
end

# create a new npc in the database
post '/npcs/new' do
  if user_rights?
    npc_hash = convert_params_to_npc_hash

    redirect '/npcs/new' unless validate_character_hash(npc_hash)
    create_new_character(npc_hash)
  else
    session[:error] = 'You must have user rights to create a new NPC'
  end

  redirect '/npcs'
end

# delete an npc from the database
post '/npcs/:id/delete' do
  npc_id = params[:id]

  if user_rights?
    delete_character(npc_id)

    confirm_character_deleted(npc_id)

    session[:success] = 'NPC successfully deleted.'
    redirect '/npcs'
  else
    session[:error] = 'You must have user rights to delete a NPC'
    redirect "/npcs/#{npc_id}"
  end
end

# display form to update an npc
get '/npcs/:id/update' do
  npc_id = params[:id]

  if user_rights?
    @npc = load_character_objects(@storage.retrieve_single_character(npc_id)).first

    if @npc
      erb :npc_update, layout: :layout
    else
      session[:error] = "NPC id #{npc_id} does not exist"
      redirect '/npcs'
    end
  else
    session[:error] = 'You must have user rights to update an NPC'
    redirect "/npcs/#{npc_id}"
  end
end

# update an existing npc
post '/npcs/:id/update' do
  npc_id = params[:id].to_i

  if user_rights?
    npc_hash = convert_params_to_npc_hash

    redirect "/npcs/#{npc_id}/update" unless validate_character_hash(npc_hash)

    @storage.update_character(npc_hash, npc_id)
    session[:success] = "#{npc_hash[:name]} has been updated!"
  else
    session[:error] = 'You must have user rights to update an NPC'
  end

  redirect "/npcs/#{npc_id}"
end

# display a single npc
get '/npcs/:id' do
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
get '/pcs' do
  @all_characters = load_character_objects(@storage.retrieve_all_characters)
  @pcs = @all_characters.select { |character| character.player_character == true }
  erb :pcs, layout: :layout
end

# display form to create a new pc
get '/pcs/new' do
  if user_rights?
    erb :pc_new, layout: :layout
  else
    session[:error] = 'You must have user rights to create a new PC'
    redirect '/pcs'
  end
end

# create a new pc in the database
post '/pcs/new' do
  if user_rights?
    pc_hash = convert_params_to_pc_hash

    redirect '/pcs/new' unless validate_character_hash(pc_hash)
    create_new_character(pc_hash)
  else
    session[:error] = 'You must have user rights to create a new PC'
  end

  redirect '/pcs'
end

# delete an pc from the database
post '/pcs/:id/delete' do
  pc_id = params[:id]

  if user_rights?
    delete_character(pc_id)

    confirm_character_deleted(pc_id)

    session[:success] = 'PC successfully deleted.'
    redirect '/pcs'
  else
    session[:error] = 'You must have user rights to delete a PC'
  end
  redirect "/pcs/#{pc_id}"
end

# display form to update a pc
get '/pcs/:id/update' do
  pc_id = params[:id]

  if user_rights?
    @pc = load_character_objects(@storage.retrieve_single_character(pc_id)).first

    if @pc
      erb :pc_update, layout: :layout
    else
      session[:error] = "PC id #{pc_id} does not exist"
      redirect '/pcs'
    end
  else
    session[:error] = 'You must have user rights to update a PC'
    redirect "/pcs/#{pc_id}"
  end
end

# update an existing pc
post '/pcs/:id/update' do
  pc_id = params[:id].to_i

  if user_rights?
    pc_hash = convert_params_to_pc_hash

    redirect "/pcs/#{pc_id}/update" unless validate_character_hash(pc_hash)

    @storage.update_character(pc_hash, pc_id)
    session[:success] = "#{pc_hash[:name]} has been updated!"
  else
    session[:error] = 'You must have user rights to update a PC'
  end
  redirect "/pcs/#{pc_id}"
end

# display a single pc
get '/pcs/:id' do
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
get '/interactions' do
  @interactions = load_interaction_objects(@storage.retrieve_all_interactions)
  erb :interactions, layout: :layout
end

# display form to create new interaction
get '/interactions/new' do
  if user_rights?
    @characters = load_character_objects(@storage.retrieve_all_characters)

    erb :interaction_new, layout: :layout
  else
    session[:error] = 'You must have user rights to create a new interaction'
    redirect '/interactions'
  end
end

# create and add new interaction to database
post '/interactions/new' do
  if user_rights?
    interaction_hash = convert_params_to_interaction_hash
    redirect '/interactions/new' unless validate_interactions_hash(interaction_hash)
    create_new_interaction(interaction_hash)
    session[:success] = 'New interaction created'
  else
    session[:error] = 'You must have user permission to create a new interaction'
  end
  redirect '/interactions'
end

# delete an interaction
post '/interactions/:id/delete' do
  interaction_id = params[:id]

  if user_rights?
    delete_interaction(interaction_id)

    confirm_interaction_deleted(interaction_id)

    session[:success] = 'Interaction successfully deleted.'
    redirect '/interactions'
  else
    session[:error] = 'You must have user rights to delete an interaction'
    redirect "/interactions/#{interaction_id}"
  end
end

# display form to update an interaction
get '/interactions/:id/update' do
  interaction_id = params[:id]

  if user_rights?
    @interaction = load_interaction_objects(@storage.retrieve_single_interaction(interaction_id)).first

    if @interaction
      involved_characters = load_interaction_involved_character_objects(interaction_id)
      @involved_character_ids = involved_characters.map(&:id)

      @characters = load_character_objects(@storage.retrieve_all_characters)

      erb :interaction_update, layout: :layout
    else
      session[:error] = "Interaction id #{interaction_id} does not exist"
      redirect '/interactions'
    end
  else
    session[:error] = 'You must have user rights to update an interaction'
    redirect "/interactions/#{interaction_id}"
  end
end

# update an existing interaction
post '/interactions/:id/update' do
  interaction_id = params[:id].to_i

  if user_rights?
    interaction_hash = convert_params_to_interaction_hash
    involved_character_ids = params[:involved_characters]

    redirect "/interactions/#{interaction_id}/update" unless validate_interactions_hash(interaction_hash)

    update_interaction(interaction_hash, interaction_id, involved_character_ids)

    session[:success] = "#{interaction_hash[:short_description]} has been updated!"
  else
    session[:error] = 'You must have user rights to update an interaction'
  end

  redirect "/interactions/#{interaction_id}"
end

# display a single interaction
get '/interactions/:id' do
  interaction_id = params[:id].to_i
  @interaction = load_interaction_objects(@storage.retrieve_single_interaction(interaction_id)).first

  if @interaction
    all_interaction_characters = load_character_objects(@storage.retrieve_single_interaction_characters(interaction_id))
    @interaction_npcs = all_interaction_characters.select { |character| character.player_character == false }
    @interaction_pcs = all_interaction_characters.select { |character| character.player_character == true }

    erb :interaction, layout: :layout
  else
    session[:error] = "Interaction id #{interaction_id} does not exist"
    redirect '/interactions'
  end
end
