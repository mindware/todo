require 'yaml'
require 'json'
require 'pathname'

class Todo 

	def config		
		@CWD 	= Dir.pwd 							# Get the current path
		@pwd    = @CWD
		$DEBUG 	= false								# Debug mode = a little more verbose
		@FILE  	= "TODO.json"						# Name of the file to be written
		@GIT   	= "https://github.com/mindware/"	# Official Github repo
	end

	# We do a loose find for commands, to make it easy for the user.
	# ie: User can type 'a', 'ad' or 'add' as a paremeter to add a task. 
	def initialize(arg) 
		config()
		# From here on, we require 
		return help? if(arg.nil? or arg.length < 1)		

		if("init".start_with? arg[0]) # done
			setup(arg[1])		
		elsif("add".start_with? arg[0]) # add
			add( arg[1..-1].join(" ") ) # exclude first param						
		elsif("check".start_with? arg[0]) # marks a task as done
			check(arg[1])			
		elsif("uncheck".start_with? arg[0]) # marks as uncomplete 
			uncheck(arg[1])			
		elsif("delete".start_with? arg[0]) # deletes a task 
			delete(arg[1])			
		elsif("description".start_with? arg[0]) #"description" 
			description(arg[1])						
		elsif("list".start_with? arg[0]) # lists tasks
			list(arg[1])						
		# elsif("priority".start_with? arg[0]) # priority
		# 	priority(arg[1..-1])
		elsif("find".start_with? arg[0]) # search or find
			search(arg[1..-1].join(" "))
		elsif("status".start_with? arg[0]) 
			status()							
		elsif("remote".start_with? arg[0]) 
			remote(arg[1])
		elsif("push".start_with? arg[0]) 
			push(arg[1])			
		elsif("install".start_with? arg[0])
			install()			
		elsif("help".start_with? arg[0]) 
			help? arg[1]				
		elsif("nuke".start_with? arg[0]) 
			nuke arg[1]
		else
			error "Invalid parameters: #{ARGV.join(", ")}"
			help?
		end
	end

	def error(str)
		puts "Error: #{str}"
	end

	def warning(str)
		puts "Warning: #{str}"
	end
	def debug(str)
		puts "Debug: #{str}"if $DEBUG		
	end

	# Returns the JSON contents of the file.
	def get_json_from_file()
		if(!find_recursive_todo_path()) 
			error "No todo list found. Use the parameter 'init' to create one."	
			exit
		end
		# where we'll store our data
		data = ""
		# open the file to get the contents
		file = File.new(@FILE, "r")
		# read the file and load up the data within it to memory
		file.each do |line|
			# read each line
			data << line
		end
		# close the file, since we're done for now
		file.close() 
		# convert the data to JSON:
		begin 
			data = JSON.parse(data)
		rescue Exception => e
			# When in doubt, print errors.
			error "Invalid JSON in #{@FILE}. This is weird... Here's the error:\n#{e.inspect}"
			exit
		end
		# return the JSON.
		return data		
	end

	def put_json_into_file(data)
		begin
			data = data.to_json 		# turn this into json
			file = File.new(@FILE, "w")			
		rescue Exception => e
			error "Could not put json into file. Here's the error:\n#{e.inspect}"
		end
		print "Saving #{@PWD}/#{@FILE}..."
		file.write(data +"\n")
		puts "Done."
		file.close()				
	end

	def description(str)
	
	end

	def setup(str)
		if(find_recursive_todo_path()) 
			puts "A to do list already exists in #{@PWD}/#{@FILE}\nTry 'help', instead of 'init' to learn more."
			return
		end		
		if(str.to_s.strip == "")
			while(str.to_s.strip == "")
				puts "What will your To Do list be about? Please specify a name for the project: "
				STDOUT.flush  
				str = STDIN.gets.chomp    
				if(str == "exit" or str == "quit")
					exit
				end
			end
		end
		name = str.strip
		data = {
					"✅ #{str}, Things to do:" => 
					{
						"Description" => "This is a description",
						"+Tasks" => 
						{
						 "Pending" => [],
						  "Done" => []
						}
					}
				}
		puts "Creating #{@FILE} for '#{str}' in path:\n#{@PWD}"
		puts "Now spice up your to do list by adding the first task: todo add +General This is a task in MyTasks group example."				
		put_json_into_file(data)		
		puts "The To Do List looks currently like this:"
		puts data
	end

	# Marking a task as completed.
	def check(arg)
		puts "Marking the following task as completed: #{arg}"
	end

	# Marking a task as uncompleted.
	def uncheck(arg)
		puts "Marking the following task as uncompleted: #{arg}"
	end

	def list(arg)
		if(!find_recursive_todo_path()) 
			error "No todo list found. Use the parameter 'init' to create one."			
		end
		data = get_json_from_file()
		data.each do |project, groups|
			puts "\n\t#{project}\n"+
				 "\t#{"=" * (project.to_s.length + 1)}\n\n"
			groups.each do |group, statuses|
				# if this a group name, it starts with +
				if(group.to_s[0] == "+")
					puts "\n\t#{group}:\n"+
					     "\t#{"-" * (group.to_s.length + 1)}\n"										
					statuses.each do |status, tasks|
						puts "\t\t#{status}: "							 
						tasks.each do |task| 
							puts "\t\t\t☐ #{task}"
						end
					end
				else
					# For general information, non-groups, such as description:
					puts "\t#{group}:\n"+
						 "\t#{"-" * (group.to_s.length + 1)}\n"										
					puts "\t#{statuses}\n"
				end
			end
		end
		puts "Done"
	end

	def nuke(str)
		if(!find_recursive_todo_path()) 
			error "There is no To Do List to nuke."
			return
		else
			warning "This will delete your To Do List. There is no turning back. "
			if @PWD != @CWD
				warning "The file to be deleted is in a directory that preceeds your current one."
				puts "File to be deleted is in: #{@PWD}/"				
				puts "Your current directory is: #{@CWD}/"
			end
			# variable that will hold the keyboard input
			input = "" 			
			if(str.to_s != "force")			
				while(input.to_s.strip == "")
					print "Continue with nuke? [Y/n]: "
					STDOUT.flush  
					input = STDIN.gets.chomp    
					if(["y", "yes"].include? input.downcase)
						break
					else
						puts "Nuke canceled."
						exit
					end
				end
			end
			puts "Nuking #{@PWD}/#{@FILE}...."
			File.delete("#{@PWD}/#{@FILE}")
			puts "Done!"
		end
	end

	def add(str)	
		if(!find_recursive_todo_path()) 
			error "There is no To Do List yet. Use the parameter 'init' to set it up."
			return
		end

		if(str.to_s == "" or str[0] != "+" or str.split(" ").length < 2)
			error "Tasks require a +groupname and the description of the task.\n"+
				  "Command: todo add +groupname task-text\n"+
				  "Example: todo add +authentication Note to self remember to code a login form."
			return
		end						

		str = str.split(" ")
		group = str[0]		
		task = str[1..-1].join(" ")

		Dir.chdir(@PWD)
		if(!File.exists? (@FILE)) 
			error "No #{@FILE} found. You must first type: todo init"
			return
		end
		data = "" 
		file = File.new(@FILE, "r")
		file.each do |line|
			data << line
		end
		file.close() 

		begin
			data = JSON.parse(data)
		rescue Exception => e
			error "Invalid JSON in #{@FILE}. This is weird... Did you manually edit it?\nHere's the error:\n#{e.inspect}"
			exit
		end

		# check if this group exists
		name = data.keys[0]
		groups = []
		# iterate through existing groups, referred to as g here.
		data[name].keys.each do |g|
			groups << g if g.to_s.start_with? "+"
		end

		debug "I found these groups: #{groups}"

		if(groups.include? group) 
			# puts "The group #{group} already exists."
			if(data[name][group]["Pending"].include? task)
				error "That task already exists."
				exit
			else
				puts "Added task \"#{task}\", under the \"#{group}\" group."
				data[name][group]["Pending"].push("#{task}")
			end
		else
			puts "Adding new group '#{group}'."	
			puts "Adding task: #{task}."
			# add the task to this group and set up task statuses.			
			data[name][group] = {			 
									 "Pending" => ["#{task}"],
									  "Done" => []
								}			
		end
		put_json_into_file(data)	
	end

	def priority(arg)
		puts "Prioritizing task #{arg}"
	end

	def find(str)
		puts "Finding \"#{str}\"..."
	end

	def help?(file=nil)
		if(file.to_s == "")
			file = "help"					
		end
		filepath = File.expand_path(File.dirname(__FILE__)) +"/help/#{file}.txt"
		if(File.exists?( filepath ))
			file = File.new(filepath, "r")
			file.each do |line|
				print line
			end
			file.close()
		else
			error "Your helpfile folder is missing or damaged. Please reinstall from:\n#{@GIT}"
		end
	end

	def install()
		puts "Installing..."
		if(!File.exists?("todo.rb"))
			error "You must be in the same directory of this script."
			return
		end

		puts "Setting up aliases 't', 'todo' and 'task' in bash, for easy access from terminal."
		command = "alias t='ruby #{@CWD}/todo.rb';\n"+
				  "alias todo='ruby #{@CWD}/todo.rb';\n"+
				  "alias task='ruby #{@CWD}/todo.rb'" 				  
		system("echo \"#{command}\" >> ~/.bash_profile")
		puts "Loading new aliases...\n------"		
		system("source ~/.bash_profile")
		puts "------"
		puts "Done!" 
		puts "Now take it for a spin, type: 't help'"
	end

	# By ascending directories recursively, we try to find an existing @FILE name.
	def find_recursive_todo_path() 
		# Here we do something similar to: git rev-parse --show-toplevel
		debug ("Ascendant recursive search from: #{@CWD}")
		Pathname.new(@CWD.to_s).ascend { |dir| 
			debug "searching... #{dir}"
			if(todo_file_exists?(dir))
			   Dir.chdir(dir) 				
			   @PWD = Dir.pwd			   
			   return true
			end
		}		
		return false
	end

	def todo_file_exists?(dir)
		# Here we essentially do: Pathname.children(with_folders=false)
		# to find if the directory contains a @FILE		
 		dir.children(false).each do |file|
 				debug "Searching for #{@FILE} vs #{file}" 				 			
 			if file.basename.to_s == @FILE.to_s
 				debug "We found a #{@FILE} in #{dir}!"
 				return true
 			end
 		end 
 		return false
	end

end

Todo.new(ARGV)
