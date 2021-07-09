ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../npc_tracker'

class NPCTrackerTest < MiniTest::Test
  include Rack::Test::Methods
  
  def app 
    Sinatra::Application
  end
  
  def setup
  # FileUtils.mkdir_p(data_path)
  # FileUtils.cp('./data/skills.yaml', data_path) #have to use origin data path from root for rake test to work
  # FileUtils.cp('./data/classes.yaml', data_path) #have to use origin data path from root for rake test to work
  end
  
  def teardown
  # FileUtils.rm_rf(data_path)
  end

  def test_home
    get '/'
    assert_equal(200, last_response.status)
  end

  def test_npcs
    get '/npcs'
    assert_equal(200, last_response.status)
  end

  def test_npc_1
    get '/npcs/1'
    assert_equal(200, last_response.status)
  end

  def test_pcs
    get '/pcs'
    assert_equal(200, last_response.status)
  end

  def test_pc_16 
    get '/pcs/16'
    assert_equal(200, last_response.status)
  end

  def test_interactions
    get '/interactions'
    assert_equal(200, last_response.status)
  end

  def test_interaction_1
    get '/interactions/1'
    assert_equal(200, last_response.status)
  end


  # def create_document(name, content = "")
  #   File.open(File.join(data_path, name), "w") do |file|
  #     file.write(content)
  #   end
  # end
  
  # def create_session_trader
  #   env "rack.session", {trader: {"name"=>"Jungo", "trader_class"=>"soldier", "skills"=>{}}}
  # end
  
  # def create_session_crew
  #   env "rack.session", {crew: { "Jungo" => {"name"=>"Jungo", "trader_class"=>"soldier", "skills"=>{}}}}
  # end
  
  # def session
  #   last_request.env["rack.session"]
  # end
  
  # def test_index
  #   get '/'
  #   assert_equal(200, last_response.status)
  # end

  # def test_skills
  #   get '/skills'
  #   assert_equal(200, last_response.status)
  #   assert_includes(last_response.body, 'Sure Shot')
  # end
  
  # def test_skills_category
  #   get '/skills/machine'
  #   assert_equal(200, last_response.status)
  #   assert_includes(last_response.body, 'Body Protocol')
  #   assert_includes(last_response.body, 'Take any two actions and then lose 1 Health')
  # end
  
  # def test_invalid_skills_category
  #   get '/skills/invalid_category'
  #   assert_equal(302, last_response.status)
  #   assert_equal("invalid_category is not a valid skill category.", session[:message])
  # end
  
  # def test_skill_page
  #   get '/skills/machine/overdrive'
  #   assert_equal(200, last_response.status)
  #   assert_includes(last_response.body, "Take any two actions and then lose 1 Health")
  # end
  
  # def test_invalid_skill_page
  #   get '/skills/stealth/backstab'
  #   assert_equal(302, last_response.status)
  #   assert_equal("backstab is not a valid skill name.", session[:message])
  # end
  
  # def test_classes_page
  #   get '/classes'
  #   assert_equal(200, last_response.status)
  #   assert_includes(last_response.body, "Soldier")
  #   assert_includes(last_response.body, "Augmented")
  #   assert_includes(last_response.body, "Crewman")
  # end
  
  # def test_class_page
  #   get '/classes/support'
  #   assert_equal(200, last_response.status)
  #   assert_includes(last_response.body, "The Support is always ready to rumble")
  #   assert_includes(last_response.body, "Onslaught [MR 3]")
  # end
  
  # def test_empty_crew_page
  #   get '/crew'
  #   assert_equal(200, last_response.status)
  #   assert_includes(last_response.body, "Create Crew")
  # end
  
  # def test_add_trader_page
  #   get '/crew/new_trader'
  #   assert_equal(200, last_response.status)
  #   assert_includes(last_response.body, "Create Trader")
  # end
  
  # def test_add_trader_creation
  #   post '/crew/new_trader', t_class: 'soldier', trader_name: 'Jacob'
  #   assert_equal(302, last_response.status)
    
  #   get '/crew/new_trader/select_skills'
  #   assert_equal(200, last_response.status)
  #   assert_includes(last_response.body, 'Jacob')
  # end
  
  # def test_select_skills
  #   create_session_trader
  #   post '/crew/new_trader/select_skills', { skill_name: 'marksman', skill_level: 3 }
  #   assert_equal(302, last_response.status)
    
  #   get last_response["Location"]
  #   assert_equal(200, last_response.status)
  #   assert_equal({"name"=>"Jungo", "trader_class"=>"soldier", "skills"=>{"marksman"=>"3"}}, session[:trader])
  # end

  # def test_save_trader
  #   create_session_trader
  #   post '/crew/new_trader/save_trader'
  #   assert_equal(session[:crew]['Jungo'], {"name"=>"Jungo", "trader_class"=>"soldier", "skills"=>{}} )
  #   assert_equal(302, last_response.status)
  #   assert_equal(session[:trader], nil)
    
  #   post '/crew/new_trader/select_skills', { skill_name: 'marksman', skill_level: 3 }
  #   assert_equal(302, last_response.status)
  #   post '/crew/new_trader/save_trader'
  #   assert_equal(302, last_response.status)
    
    
  #   get last_response["Location"]
  #   assert_equal(200, last_response.status)
  #   assert_equal(session[:crew]['Jungo'], {"name"=>"Jungo", "trader_class"=>"soldier", "skills"=>{"marksman"=>"3"}} )
  # end
  
  # def test_delete_trader
  #   create_session_crew
    
  #   get '/crew'
  #   assert_equal(session[:crew], { "Jungo" => {"name"=>"Jungo", "trader_class"=>"soldier", "skills"=>{}}} )
  #   assert_includes(last_response.body, "Jungo")

  #   post '/crew/delete_trader', {delete_name: 'Jungo'}
  #   assert_equal(302, last_response.status)
  #   assert_empty(session[:crew])
    
  #   get last_response["Location"]
  #   assert_equal(200, last_response.status)
  #   refute_includes(last_response.body, "Jungo")
  # end
  
  # def test_save_crew
  #   create_session_crew
  #   post '/crew/save_crew'
  #   assert(data_path + '/crew.yml')
  # end

  # def test_params
  #   env "rack.session", {sess1: 'Goodbye!' }  # sets a session variable for test!
  #   post '/test_params', {param1: 'Hello World!'}# sets a param variable for test!
  #   assert_includes(last_response.body, 'Goodbye!')
  #   assert_equal(session[:sess1], 'Goodbye!')
  # end
  

end