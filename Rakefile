desc 'start npc_tracker'
task :start do 
  sh 'bundle exec ruby npc_tracker.rb'
end

desc 'Run tests'
task :test do
  sh 'bundle exec ruby ./test/npc_tracker_test.rb'  
end

desc 'Run rubocop'
task :rubocop do
  sh 'rubocop npc_tracker.rb'
end