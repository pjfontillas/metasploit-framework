
module Msf
class Post

module File

	def file_exist?(file)
		if session.type == "meterpreter"
			stat = session.fs.file.stat(file) rescue nil
			return false unless stat
			return stat.file?
		else
			if session.platform =~ /win/
				# XXX
			else
				f = cmd_exec("test -f '#{file}' && echo true")
				return false if f.nil? or f.empty?
				return true
			end
		end
	end

	def file_rm(file)
		if session.type == "meterpreter"
			session.fs.file.rm(file)
		else
			if session.platform =~ /win/
				session.shell_command_token("del \"#{file}\"")
			else
				session.shell_command_token("rm -f '#{file}'")
			end
		end
	end

	#
	# Writes a given string to a file specified
	#
	def file_local_write(file2wrt, data2wrt)
		if not ::File.exists?(file2wrt)
			::FileUtils.touch(file2wrt)
		end

		output = ::File.open(file2wrt, "a")
		data2wrt.each_line do |d|
			output.puts(d)
		end
		output.close
	end

	#
	# Returns a MD5 checksum of a given local file
	#
	def file_local_digestmd5(file2md5)
		if not ::File.exists?(file2md5)
			raise "File #{file2md5} does not exists!"
		else
			require 'digest/md5'
			chksum = nil
			chksum = Digest::MD5.hexdigest(::File.open(file2md5, "rb") { |f| f.read})
			return chksum
		end
	end

	#
	# Returns a MD5 checksum of a given remote file
	#

	def file_remote_digestmd5(file2md5)
		data = read_file(file2md5)
		chksum = nil
		if data
			chksum = Digest::MD5.hexdigest(data)
		end
		return chksum
	end

	#
	# Returns a SHA1 checksum of a given local file
	#
	def file_local_digestsha1(file2sha1)
		if not ::File.exists?(file2sha1)
			raise "File #{file2sha1} does not exists!"
		else
			require 'digest/sha1'
			chksum = nil
			chksum = Digest::SHA1.hexdigest(::File.open(file2sha1, "rb") { |f| f.read})
			return chksum
		end
	end

	#
	# Returns a SHA1 checksum of a given remote file
	#
	def file_remote_digestsha1(file2sha1)
		data = read_file(file2sha1)
		chksum = nil
		if data
			chksum = Digest::SHA1.hexdigest(data)
		end
		return chksum
	end

	#
	# Returns a SHA256 checksum of a given local file
	#
	def file_local_digestsha2(file2sha2)
		if not ::File.exists?(file2sha2)
			raise "File #{file2sha2} does not exists!"
		else
			require 'digest/sha2'
			chksum = nil
			chksum = Digest::SHA256.hexdigest(::File.open(file2sha2, "rb") { |f| f.read})
			return chksum
		end
	end

	#
	# Returns a SHA2 checksum of a given remote file
	#
	def file_remote_digestsha2(file2sha2)
		data = read_file(file2sha2)
		chksum = nil
		if data
			chksum = Digest::SHA256.hexdigest(data)
		end
		return chksum
	end

	#
	# Platform-agnostic file read.  Returns contents of remote file +file_name+
	# as a String.
	#
	def read_file(file_name)
		data = nil
		if session.type == "meterpreter"
			data = read_file_meterpreter(file_name)
		elsif session.type == "shell"
			if session.platform =~ /win/
				data = session.shell_command_token("type \"#{file_name}\"")
			else
				data = session.shell_command_token("cat \'#{file_name}\'")
			end

		end
		data
	end

	#
	# Platform-agnostic file write. Writes given object content to a remote file.
	# Returns Boolean true if successful
	#
	def write_file(file_name, data)
		if session.type == "meterpreter"
			fd = session.fs.file.new(file_name, "wb")
			fd.write(data)
			fd.close
		elsif session.respond_to? :shell_command_token
			if session.platform =~ /win/
				session.shell_command_token("echo #{data} > \"#{file_name}\"")
			else
				session.shell_command_token("echo \'#{data}\' > \'#{file_name}\'")
			end

		end
		return true
	end

	#
	# Platform-agnostic file append. Appends given object content to a remote file.
	# Returns Boolean true if successful
	#
	def append_file(file_name, data)
		if session.type == "meterpreter"
			fd = session.fs.file.new(file_name, "ab")
			fd.write(data)
			fd.close
		elsif session.respond_to? :shell_command_token
			if session.platform =~ /win/
				session.shell_command_token("echo #{data} >> \"#{file_name}\"")
			else
				session.shell_command_token("echo \'#{data}\' >> \'#{file_name}\'")
			end
		end
		return true
	end


protected
	#
	# Meterpreter-specific file read.  Returns contents of remote file
	# +file_name+ as a String or nil if there was an error
	#
	def read_file_meterpreter(file_name)
		begin
			fd = session.fs.file.new(file_name, "rb")
		rescue ::Rex::Post::Meterpreter::RequestError => e
			print_error("Failed to open file: #{file_name}")
			return nil
		end

		data = ''
		begin
			until fd.eof?
				data << fd.read
			end
		ensure
			fd.close
		end
		data
	end

end

end
end
