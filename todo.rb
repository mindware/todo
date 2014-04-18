# Developed by Andrés Colón Pérez
# http://github.com/mindware/
require 'yaml'
require 'json'
require 'pathname'

class Todo 

	def config		
		@CWD 	= Dir.pwd 							# Get the current path
		@PWD    = Pathname.new(@CWD).to_s 			# Get the filepath
		$DEBUG 	= false								# Debug mode = a little more verbose
		@FILE  	= ".TODO.json"						# Name of the hidden file that contains data.
		@TXT 	= "TODO.txt"						# Name of file we render text to (overwrites).
		@GIT   	= "https://github.com/mindware/"	# Official Github repo
		@NOT_DONE_STATUS = "Pending"
		@DONE_STATUS 	 = "Done"
		# @disclaimer = 	"# Auto-generated file. Manual edits are overwritten. \n"+
		# 				"# Get it here: http://github.com/mindware/todo\n\n"		
		@disclaimer = 	"---\nAuto-generated using: github.com/mindware/todo\n"
		@default_group = "+Tasks"			# The task group to use when no group is specified.
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
		# elsif("description".start_with? arg[0]) #"description" 
		# 	description(arg[1])						
		elsif("list".start_with? arg[0]) # lists tasks
			list(arg[1..-1])						
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

	def save_json_into_file(data)
		begin
			data = data.to_json 		# turn this into json
			file = File.new(@FILE, "w")			
			debug "Saving '#{@PWD}/#{@FILE}' ..."
			file.write(data +"\n")
			debug " Done."			
			file.close()
			puts "Saved your brand new list."				
		rescue Exception => e
			error "Could not save #{@FILE} in #{@PWD} - Here's the error:\n#{e.inspect}"
		end			
	end

	def save_txt_into_file()
		begin 
			debug "Saving text file in #{@TXT} in folder: #{@PWD}"
			file = File.new("#{@PWD}/#{@TXT}", "w")		
			data = render_txt
			data << @disclaimer
			file.write(data)
			file.close()
		rescue Exception => e
			error "An error ocurred while rendering the todo.txt file:\n#{e.inspect}"
		end			
	end

	# def description(str)
	
	# end

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
					"#{str}" => 
					{
						# "Description" => "This is a description",
						# "#{@ffault_group}" => 
						# {
						#  "Pending" => [],
						#   "Done" => []
						# }
					}
				}
		debug "Creating #{@FILE} for '#{str}' in path:\n#{@PWD}"
		# debug "Now spice up your to do list by adding the first task: todo add +General This is a task in MyTasks group example."				
		puts "Your brand new To Do list is ready! Congratulations!"
		help? "tips"
		save_json_into_file(data)		
		save_txt_into_file()
		puts "The To Do List looks currently like this:"
		list()
	end

	# Marking a task as completed.
	def check(arg)
		puts "Marking the following task as completed: #{arg}"
	end

	# Marking a task as uncompleted.
	def uncheck(arg)
		puts "Marking the following task as uncompleted: #{arg}"
	end

	# Renders the JSON file to screen, in a user friendly format.
	def render_txt(arg=nil) 
		if(!find_recursive_todo_path()) 
			error "No todo list found. Use the parameter 'init' to create one."			
		end
		# var that will hold all the output of this method
		output = ""		
		# when filters are required
		filter_status		= nil
		filter_group		= nil
		filter_task			= nil
		if(!arg.nil?)		
			if(arg.length > 2)
				error "Too many options. Try 'todo help list' for more information on available parameters."
				return
			else
				if(["unchecked", "u", "p", "pending"].include? arg[0].to_s)		
					filter_status = @NOT_DONE_STATUS				
					output << "Filtering for #{@NOT_DONE_STATUS.downcase} tasks.\n"					
				elsif(["checked", "c", "d", "done", "complete", "completed"].include? arg[0].to_s)
					filter_status = @DONE_STATUS		
					output << "Filtering for #{@DONE_STATUS.downcase} tasks.\n"
				elsif(arg[0].to_s[0] == "+")  
					# You cannot filter by group and then status. It's status, then group. 
					# We error out gracefully if someone does it:
					if(arg.length == 2)	
						error "You must first filter tasks status (checked or unchecked), and then by group.\n"+
						"Example: 'todo list checked +mygroup', which is the same as: 't l c +mygroup'"
						exit
					end
					# if the first character of the argument is a +, we're
					# filtering by group.
					filter_group = arg[0].to_s
					output << "Applying filter for group '#{filter_group}'.\n"	
				elsif(arg[0].to_s.strip.length > 0)
					filter_task = arg[0].to_s.strip
					output << "Applying filter for tasks that contain '#{filter_task}'.\n"
				end						
				if(arg.length == 2)
					if(arg[1].to_s[0] == "+")
						filter_group = arg[1].to_s
					end
				end
			end
		end

		data = get_json_from_file()
		data.each do |project, groups|
			# if(project == "#Stats")
			# 	next
			# end

			output << "\n\t✅ Project: #{project}\n"+
				 	  "\t#{"=" * ("✅ Project: #{project}".length)}\n\n"
			groups.each do |group, statuses|
				# if this a group name, it starts with +
				if(group.to_s[0] == "+")
					if(!filter_group.nil? and filter_group != group.to_s)
						# Continue if this is not a group we want to see.
						next
					end
					output << "\n\t#{group}:\n"+
					     "\t#{"-" * (group.to_s.length + 1)}\n"										
					# this variable tells us if we haven't found
					# any tasks in a single group. We instantiate
					# to nil, and set it to false if something found.
					# Only if it remains nil, will it be set to false
					# if nothing found, otherwise, at least something
					# was found and it remains unused.
					no_entries = nil
					statuses.each do |status, tasks|
						if(tasks.length > 0)
							# we found at least one task in one of the statuses
							if((!filter_status.nil?) and (filter_status != status))
								# continue if we're filtering
								next
							end							
							no_entries = false				 
							count = 0
							task_output = ""							
							for task in tasks
								# if we're doing a word filter on the tasks
								if(!filter_task.nil? and !task.include? filter_task) 
									debug("Omitted a task due to filter.")
									next
								end
								count = count + 1								
								task_output << "\t\t#{count}. "
								task_output << "#{(status == "#{@DONE_STATUS}" ? "✓" : "☐")} #{task}\n"
							end
							# Only if tasks were found, do we print the group status.
							if(count > 0)						
								output << "\t#{status}: \n"
								output << task_output
							end
						else
							no_entries = true if no_entries.nil?
						end
					end
					if no_entries == true
						output << "\tNothing here yet, add a task with:\n\ttask add <your text here> \n"
					end
				else
					# For general information, non-groups, such as description:
					output << "\n\t#{group}:\n\n"+
						 "\t#{"-" * (group.to_s.length + 1)}\n\n"
					output << "\t#{statuses}\n\n"
				end
			end
		end
		output << "\n"
	end

	# Simply outputs to screen the result of render_txt()
	def list(arg=nil)
		puts render_txt(arg)
	end

	def nuke(str)
		if(!find_recursive_todo_path()) 
			error "There is no To Do List to nuke."
			return
		else
			warning "This will delete the To Do List. There is no turning back. "
			if @PWD != @CWD
				warning "The file to be deleted is in a directory that preceeds your current one."
				puts "File to be deleted is in: #{@PWD}/"				
				puts "Your current directory is: #{@CWD}/"
			end
			# variable that will hold the keyboard input
			input = "" 			
			if(str.to_s != "force" or str.to_s != "it")			
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

			begin
				File.delete("#{@PWD}/#{@FILE}")
				puts "Removed: #{@PWD}/#{@FILE}"				
				File.delete("#{@PWD}/#{@TXT}")
				puts "Removed: #{@PWD}/#{@TXT}"											
				puts "Done!"
			rescue Exception => e
				debug "An error ocurred while deleting the todo files. Error:\n#{e.inspect}"
			end
		end
	end

	def add(str)	
		if(!find_recursive_todo_path()) 
			error "There is no To Do List yet. Use the parameter 'init' to set it up."
			return
		end

		if(str.to_s == "" or str[0] != "+" or str.split(" ").length < 2)
			str = "#{@default_group} #{str}"
			# error "Tasks require a +groupname and the description of the task.\n"+
			# 	  "Command: todo add +groupname task-text\n"+
			# 	  "Example: todo add +authentication Note to self remember to code a login form."
			# return
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
			if(data[name][group]["#{@NOT_DONE_STATUS}"].include? task)
				error "That task already exists."
				exit
			else
				puts "Added task \"#{task}\", under the \"#{group}\" group."
				data[name][group]["#{@NOT_DONE_STATUS}"].push("#{task}")
			end
		else
			puts "Adding new group '#{group}'."	
			puts "Adding task: #{task}."
			# add the task to this group and set up task statuses.			
			data[name][group] = {			 
									 "#{@NOT_DONE_STATUS}" => ["#{task}"],
									  "#{@DONE_STATUS}" => []
								}			
		end
		save_json_into_file(data)	# saves json data
		save_txt_into_file()		# renders text file from json.
		list()
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
		# list all available help files
		if(file == "topics" or file == "topic")		
			puts "The following topics are available:\n"
			Dir.glob("#{@PWD}/help/*.txt") do |file|
				  # do work on files ending in .rb in the desired directory
				  print "#{Pathname.new(file).basename.to_s.gsub(".txt", "")}\t"
			end
			puts "\n\nTry any of the topics above for more information. Usage: todo help <topic>"
		else
			# list a specific file
			filepath = File.expand_path(File.dirname(__FILE__)) +"/help/#{file}.txt"
			if(File.exists?( filepath ))
				file = File.new(filepath, "r")
				file.each do |line|
					print line
				end
				file.close()
			else
				error "Help on that topic could not be found. Try 'todo help topics' to see available topics."
			end
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
