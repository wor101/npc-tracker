ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'

require_relative '../npc_tracker'

class NPCTrackerTest < MiniTest::Test
  include Rack::Test::Methods
  
  def app 
    Sinatra::Application
  end
  
  def setup
    db = PG.connect(dbname: "npc_tracker_test")
    restart_table_sequences(db)
    load_table_data(db)
  end
  
  def teardown
    # connect to test database
    db = PG.connect(dbname: "npc_tracker_test")
    delete_table_data(db)
    restart_table_sequences(db)
  end

  def restart_table_sequences(db)
    db.exec("ALTER SEQUENCE characters_id_seq RESTART WITH 1;")
    db.exec("ALTER SEQUENCE interactions_id_seq RESTART WITH 1;")
    db.exec("ALTER SEQUENCE characters_interactions_id_seq RESTART WITH 1;")
    db.exec("ALTER SEQUENCE users_id_seq RESTART WITH 1;")
  end

  def load_table_data(db)
    characters_data = File.open('./test/characters_data.sql', 'rb') { |file| file.read }
    db.exec(characters_data)
  
    interactions_data = File.open('./test/interactions_data.sql', 'rb') { |file| file.read }
    db.exec(interactions_data)

    characters_interactions_data = File.open('./test/characters_interactions_data.sql', 'rb') { |file| file.read }
    db.exec(characters_interactions_data)

    users_data = File.open('./test/users_data.sql', 'rb') { |file| file.read }
    db.exec(users_data)
  end

  def delete_table_data(db)
    db.exec("DELETE FROM characters;")
    db.exec("DELETE FROM interactions;")
    db.exec("DELETE FROM characters_interactions;")
    db.exec("DELETE FROM users;")
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def user_session
    { "rack.session" => { username: "normal_user"} }
  end

  def npc_jani_ahokas_hash
    { name: 'Jani Ahokas',
    player_character: false,
    picture_link: 'No link',
    stat_block_name: 'commoner',
    stat_block_link: 'no stat block link',
    main_location: 9,
    alignment: 'Chaotic Good',
    ancestory: 'human',
    gender: 'male',
    short_description: 'Janis father Taisto Ahokas was recently killed by an owlbear.' }
  end

  def npc_allmina_hash
    { name: 'Allmina',
    player_character: false,
    picture_link: 'Still No link',
    stat_block_name: 'thief',
    stat_block_link: 'fake block',
    main_location: 9,
    alignment: 'Chaotic Good',
    ancestory: 'halfling',
    gender: 'female',
    short_description: 'Leader of the black cats. Server at the East Gate Inn.' }
  end

  def pc_theondondandolis_hash
    { name: 'Theondondandolis',
    player_character: true,
    picture_link: 'No link',
    stat_block_name: 'bard',
    stat_block_link: 'no stat block link',
    main_location: 0,
    alignment: 'Neutral Good',
    ancestory: 'human',
    gender: 'male',
    short_description: 'The greatest bard to ever live!' }
  end

  def pc_celestria_hash
    { name: 'Celestria da Crusha',
    player_character: true,
    picture_link: 'Still No link',
    stat_block_name: 'barbarian rager',
    stat_block_link: 'fake block',
    main_location: 9,
    alignment: 'Chaotic Good',
    ancestory: 'half-orc',
    gender: 'female',
    short_description: 'Not too smart but good at crushing stuff' }
  end

  def interaction_heartless_heroics_hash
    { attitude: 'hostile', 
      date: '1900-01-01 12:00:00', 
      short_description: 'Heartless Heroics', 
      full_description: 'The party returned to Jani the foot of his dead father and still demanded payment of the 35gp. They further refused to let him accompany them on their future adventures.',
      involved_characters: [18, 19, 20] }
  end

  def interaction_deadly_rivalry_hash
    { attitude: 'hostile', 
      date: '1900-01-01 12:00:00', 
      short_description: 'Deadly Rivalry', 
      full_description: 'The Shadow Spiders, led by Voitto Markku, have taken out a contract on Almina, the leader of the Black Cats. Alimna has reached out to Tuula Tenhunen for help.',
      involved_characters: [1, 10, 12] }
  end

  def test_home
    get '/', {}, admin_session
    assert_equal(200, last_response.status)
  end

  def test_npcs
    get '/npcs'
    assert_equal(200, last_response.status)

    assert_includes(last_response.body, 'Almina Mastonen')
    assert_includes(last_response.body, 'Zado')
  end

  def test_npc_1
    get '/npcs/1'
    assert_equal(200, last_response.status)

    assert_includes(last_response.body, 'Name: Almina Mastonen')
    assert_includes(last_response.body, 'Illicit Rivalry')
    assert_includes(last_response.body, 'Voitto Markku')
  end

  def test_npc_does_not_exist
    get '/npcs/99'
    assert_equal("NPC id 99 does not exist", session[:error])
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
  end

  def test_new_npc
    post '/npcs/new', npc_jani_ahokas_hash, user_session
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Jani Ahokas')

    get '/npcs/21'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Jani Ahokas')
    assert_includes(last_response.body, 'recently killed by an owlbear.')
  end

  def test_update_npc
    post 'npcs/1/update', npc_allmina_hash, user_session
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Allmina')
    assert_includes(last_response.body, 'Leader of the black cats. Server at the East Gate Inn.')
  end

  def test_update_npc_without_permission
    post 'npcs/1/update', npc_allmina_hash
    assert_equal(302, last_response.status)
    
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have user rights to update an NPC')
  end

  def test_delete_npc
    post '/npcs/1/delete', {}, user_session
    assert_equal(302, last_response.status)
    assert_equal(session[:success], 'NPC successfully deleted.')
    
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'NPC successfully deleted.')
    refute_includes(last_response.body, 'Almina Mastonen')
  end

  def test_delete_npc_without_permission
    post '/npcs/1/delete'
    assert_equal(302, last_response.status)
    assert_equal(session[:error], 'You must have user rights to delete an NPC')
    
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have user rights to delete an NPC')
  end

  def test_pcs
    get '/pcs'
    assert_equal(200, last_response.status)

    assert_includes(last_response.body, 'Celestria Loman')
    assert_includes(last_response.body, 'Durrakos')
  end

  def test_new_pc
    post '/pcs/new', pc_theondondandolis_hash, user_session
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Theondondandolis')

    get '/pcs/21'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Theondondandolis')
    assert_includes(last_response.body, 'The greatest bard to ever live!')
  end

  def test_new_pc_without_permission
    post '/pcs/new'
    assert_equal(302, last_response.status)
    assert_equal(session[:error], 'You must have user rights to create a new PC')

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have user rights to create a new PC')
  end

  def test_update_pc 
    post 'pcs/1/update', pc_celestria_hash, user_session
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Celestria da Crusha')
    assert_includes(last_response.body, 'Not too smart but good at crushing stuff')
  end

  def test_update_pc_without_permission
    post 'pcs/1/update', pc_celestria_hash
    assert_equal(302, last_response.status)
    assert_equal(session[:error], 'You must have user rights to update a PC')

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have user rights to update a PC')
  end

  def test_delete_pc
    post '/pcs/16/delete', {}, user_session
    assert_equal(302, last_response.status)
    assert_equal('PC successfully deleted.', session[:success])

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'PC successfully deleted.')
    refute_includes(last_response.body, 'Celestria Loman')
  end

  def test_delete_npc_without_permission
    post '/pcs/16/delete', {}
    assert_equal(302, last_response.status)
    assert_equal(session[:error], 'You must have user rights to delete a PC')

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have user rights to delete a PC')
  end

  def test_pcs_18
    get '/pcs/18'
    assert_equal(200, last_response.status)

    assert_includes(last_response.body, 'Name: Durrakos')
  end

  def test_pc_does_not_exist
    get '/pcs/99'
    assert_equal("PC id 99 does not exist", session[:error])
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
  end

  def test_interactions
    get '/interactions'
    assert_equal(200, last_response.status)

    assert_includes(last_response.body, 'Illicit Rivalry')
    assert_includes(last_response.body, 'Stuck Between Political Rivals')
  end

  def test_interaction_1
    get '/interactions/1'
    assert_equal(200, last_response.status)

    assert_includes(last_response.body, 'Illicit Rivalry')
    assert_includes(last_response.body, 'Almina Mastonen')
    assert_includes(last_response.body, 'Voitto Markku')
  end 

  def test_interaction_does_not_exist
    get '/interactions/99'
    assert_equal("Interaction id 99 does not exist", session[:error])
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
  end

  def test_new_interaction
    post '/interactions/new', interaction_heartless_heroics_hash, user_session
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Heartless Heroics')
    
    get '/interactions/5'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Durrakos')
    assert_includes(last_response.body, 'Harold Charger')
    assert_includes(last_response.body, 'Orsik Ironfist')
    assert_includes(last_response.body, 'The party returned to Jani the foot of his dead father')

    get '/pcs/20'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Orsik Ironfist')
    assert_includes(last_response.body, 'Heartless Heroics')
  end

  def test_new_interaction_without_permission
    post '/interactions/new', interaction_heartless_heroics_hash
    assert_equal(302, last_response.status)
    assert_equal(session[:error], 'You must have user permission to create a new interaction')

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have user permission to create a new interaction')
    refute_includes(last_response.body, 'Heartless Heroics')
  end

  def test_update_interaction
    post 'interactions/1/update', interaction_deadly_rivalry_hash, user_session
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Deadly Rivalry')
    assert_includes(last_response.body, 'The Shadow Spiders, led by Voitto Markku, have taken out a contract on Almina')
    assert_includes(last_response.body, 'Tuula Tenhunen')
    assert_includes(last_response.body, 'Almina Mastonen')
    assert_includes(last_response.body, 'Voitto Markku')
  end

  def test_update_interaction_without_permission
    post 'interactions/1/update', interaction_deadly_rivalry_hash
    assert_equal(302, last_response.status)
    assert_equal(session[:error], 'You must have user rights to update an interaction')

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have user rights to update an interaction')
  end

  def test_delete_interaction
    post '/interactions/4/delete', {}, user_session
    assert_equal(302, last_response.status)
    assert_equal('Interaction successfully deleted.', session[:success])

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Interaction successfully deleted.')
    refute_includes(last_response.body, 'Stuck Between Political Rivals')
  end

  def test_delete_interaction_without_permission
    post '/interactions/4/delete'
    assert_equal(302, last_response.status)
    assert_equal(session[:error], 'You must have user rights to delete an interaction')

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have user rights to delete an interaction')
    assert_includes(last_response.body, 'Stuck Between Political Rivals')
  end

  def test_login
    get '/login'
    assert_equal(200, last_response.status)
  end

  def test_new_user_form
    get '/new_user'
    assert_equal(200, last_response.status)
  end

  def new_user_hash
    { username: "new_user", email: "new_user@email.com", password: "password", password_match: "password"}
  end

  def test_submit_new_user
    post '/new_user', new_user_hash
    assert_equal(302, last_response.status)
    assert_equal(session[:success], 'User new_user has been created!')

    post '/login', {username: "new_user", password: "password"}
    assert_equal(302, last_response.status)
    assert_equal(session[:success], 'Welcome new_user!')
  end

  def test_logout
    post '/logout', {}, user_session
    assert_equal(302, last_response.status)
    assert_equal(session[:success], 'User has logged out')
    assert_nil(session[:username])
    assert_equal(session[:signed_in], false)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Login')
  end

  def test_users
    get '/users', {}, admin_session
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Current User: admin')
  end

  def test_users_without_permission
    get '/users', {}, user_session
    assert_equal(302, last_response.status)
    assert_equal(session[:error], 'You must have admin rights to perform that action')

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'You must have admin rights to perform that action')
  end
  
  def test_approve_pending_user
    post '/users/3/approve', {}, admin_session
    assert_equal(session[:success], 'User approved and granted user status')
    assert_equal(302, last_response.status)

    get last_response["Location"], {}, admin_session
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '3: pending_user - pending_user@email.com [user]')
  end

  def test_approve_pending_user_without_permission
    post '/users/3/approve'
    assert_equal(session[:error], 'You must have admin rights to perform that action')
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(302, last_response.status)

    get '/users', {}, admin_session
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '3: pending_user - pending_user@email.com [pending]')
  end

  def test_make_admin
    post '/users/2/admin', {}, admin_session
    assert_equal(session[:success], 'User has been made admin')
    assert_equal(302, last_response.status)

    get last_response["Location"], {}, admin_session
    assert_equal(200, last_response.status) 
    assert_includes(last_response.body, '2: normal_user - normal_user@email.com [admin]')   
  end

  def test_make_admin_without_permission
    post '/users/2/admin'
    assert_equal(session[:error], 'You must have admin rights to perform that action')
    assert_equal(302, last_response.status)

    get '/users', {}, admin_session
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '2: normal_user - normal_user@email.com [user]')
  end

  def test_reject_user
    post '/users/2/reject', {}, admin_session
    assert_equal(session[:success], 'User removed from database')

    get '/users', {}, admin_session
    assert_equal(200, last_response.status)
    refute_includes(last_response.body, '2: normal_user - normal_user@email.com [user]')
  end

  def test_reject_user_without_permission
    post '/users/2/reject'
    assert_equal(session[:error], 'You must have admin rights to perform that action')

    get '/users', {}, admin_session
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '2: normal_user - normal_user@email.com [user]')
  end
end