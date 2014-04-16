require 'yaml'
require 'pathname'

class Todo 

	def config		
		@CWD 	= Dir.pwd 							# Get the current path
		@pwd    = @CWD
		$DEBUG 	= false								# Debug mode = a little more verbose
		@FILE  	= "TODO.yml"						# Name of the file to be written
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
		elsif("check".start_with? arg[0]) # done
			check(arg[1])			
		elsif("uncheck".start_with? arg[0]) #"remove" 
			uncheck(arg[1])			
		elsif("delete".start_with? arg[0]) #"remove" 
			delete(arg[1])			
		elsif("list".start_with? arg[0]) #"remove" 
			list(arg[1])						
		# elsif("priority".start_with? arg[0]) # priority
		# 	priority(arg[1..-1])
		elsif("find".start_with? arg[0]) # search or find
			search(arg[1..-1].join(" "))
		elsif("status".start_with? arg[0]) #"remove" 
			status()									
		elsif("remote".start_with? arg[0]) #"remove" 
			remote(arg[1])
		elsif("push".start_with? arg[0]) #"remove" 
			push(arg[1])			
		elsif("install".start_with? arg[0]) #"remove" 
			install()			
		elsif("help".start_with? arg[0]) #"remove" 
			help? arg[1]				
		elsif("nuke".start_with? arg[0]) #"remove" 
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
					"✅ #{str}, Things to do:\n#{ "#" * (str.length + 17)}" => 
					{
						"General" => 
						{"Done:\n#{ "#" * "Done:".length}" => {}, "Pending:\n#{ "#" * "Pending:".length}" => {}, 
						 "Completed:\n#{ "#" * "Completed:".length}\n" => {}}
					}
				}
		data = YAML.dump(data) # turn this into yaml
		file = File.new(@FILE, "w")
		puts "Creating TODO.yml for '#{str}' in path:\n#{@PWD}"
		puts "Now spice up your to do list by adding the first task: todo add +General This is a task in MyTasks group example."				
		# remove those ugly YAML question marks and dashes, while keeping the doc valid.
		data = data.gsub(/^\?/, " " ).gsub(/^\:/, " ").gsub("- |-", ("    ")).gsub("|-", "  ").gsub("- |", "  ").gsub("   ? ", "     ") #.gsub("   : ","     ").gsub("    |\n", "     \n")
		file.write(data)
		file.close()
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
		file = File.new(@FILE, "r")
		file.each do |line|
			puts line
		end
		file.close() 
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
				puts "Current directory is: #{@CWD}/"
			end
			warning "You will be deleting the list located in: #{@PWD}/"
			# variable that will hold the keyboard input
			input = "" 			
			if(str.to_s != "force")			
				while(input.to_s.strip == "")
					print "Continue with nuke? [y/n]: "
					STDOUT.flush  
					input = STDIN.gets.chomp    
					if("yes".start_with? input.downcase)
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
		task = str[1]

		Dir.chdir(@PWD)
		if(!File.exists? (@FILE)) 
			error "No TODO.yml found. You must first type: todo init"
			return
		end

		data = YAML.load_file(@FILE)

		# check if this group exists
		if(data.include? group) 
			puts "Congrats the group #{group} exists."
		else
			puts "Group #{group} doesn't exist, creating it:"						
			puts data.class
			puts group 
			puts task
			added = { group => task }
			puts added
			key = data.keys[0]
			data = data[key][group] = task
			puts data.inspect
			exit
			data.push()
			puts group[task].class
			puts data
		end

		puts "Adding the task: #{task}"
		file = File.new(@FILE, "w")		
		file.write(YAML.dump(data))
		file.close()
		puts data		
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
		# to find if the directory contains a TODO.yml		
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
