desc 'start npc_tracker'
task :start do 
  sh 'bundle exec ruby npc_tracker.rb'
end

desc 'Run tests'
task :test do
  sh 'bundle exec ruby ./test/npc_tracker_test.rb'  
end

desc 'Run rubocop on npc_tracker'
task :rubocop do
  sh 'rubocop npc_tracker.rb'
end

desc 'Run rubocop on database_persistence'
task :rubocop_db do
  sh 'rubocop database_persistence.rb'
end