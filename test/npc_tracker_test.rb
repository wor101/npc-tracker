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

end