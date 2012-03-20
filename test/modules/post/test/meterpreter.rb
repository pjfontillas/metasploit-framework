
require 'msf/core'
require 'rex'

$:.push "test/lib" unless $:.include? "test/lib"
#require 'module_test'
load 'test/lib/module_test.rb'

class Metasploit4 < Msf::Post

	include Msf::ModuleTest::PostTest

	def initialize(info={})
		super( update_info( info,
				'Name'          => 'Testing meterpreter stuff',
				'Description'   => %q{
					This module will test meterpreter API methods.

					ASSUMPTIONS:
						- the server has write permissions to its current
						working directory.
				},
				'License'       => MSF_LICENSE,
				'Author'        => [ 'egypt'],
				'Version'       => '$Revision$',
				'Platform'      => [ 'windows', 'linux', 'java' ],
				'SessionTypes'  => [ 'meterpreter' ]
			))

	end

	def test_sys_config
		vprint_status("Starting system config tests")

		it "should return a user id" do
			uid = session.sys.config.getuid
			true
		end

		it "should return a sysinfo Hash" do
			sysinfo = session.sys.config.sysinfo
			true
		end
	end

	def test_net_config
		vprint_status("Starting networking tests")

		it "should return network interfaces" do
			ifaces = session.net.config.get_interfaces
			res = !!(ifaces and ifaces.length > 0)

			res
		end
		it "should have an interface that matches session_host" do
			ifaces = session.net.config.get_interfaces
			res = !!(ifaces and ifaces.length > 0)

			res &&= !! ifaces.find { |iface|
				iface.ip == session.session_host
			}

			res
		end

		it "should return network routes" do
			routes = session.net.config.get_routes

			routes and routes.length > 0
		end

	end

	def test_fs
		vprint_status("Starting filesystem tests")

		it "should return the proper directory separator" do
			sysinfo = session.sys.config.sysinfo
			if sysinfo["OS"] =~ /windows/i
				sep = session.fs.file.separator
				res = (sep == "\\")
			else
				sep = session.fs.file.separator
				res = (sep == "/")
			end

			res
		end

		it "should return the current working directory" do
			wd = session.fs.dir.pwd
			vprint_status("CWD: #{wd}")

			true
		end

		it "should list files in the current directory" do
			session.fs.dir.entries
		end

		it "should stat a directory" do
			session.fs.file.stat(session.fs.dir.pwd).directory?
		end

		it "should create and remove a dir" do
			res = create_directory("meterpreter-test")
			if (res)
				session.fs.dir.rmdir("meterpreter-test")
				res &&= !session.fs.dir.entries.include?("meterpreter-test")
				vprint_status("Directory removed successfully")
			end

			res
		end

		it "should change directories" do
			# if the previous test failed to clean up don't count it against
			# this one. Assume if we can't make it, it already exists
			res = create_directory("meterpreter-test") rescue true

			old_wd = session.fs.dir.pwd
			vprint_status("Old CWD: #{old_wd}")

			if res
				session.fs.dir.chdir("meterpreter-test")
				new_wd = session.fs.dir.pwd
				vprint_status("New CWD: #{new_wd}")
				res &&= (new_wd =~ /meterpreter-test$/)

				if res
					session.fs.dir.chdir("..")
					wd = session.fs.dir.pwd
					vprint_status("Back to old CWD: #{wd}")
				end
			end
			session.fs.dir.rmdir("meterpreter-test")
			res &&= !session.fs.dir.entries.include?("meterpreter-test")
			vprint_status("Directory removed successfully")

			res
		end

		it "should create and remove files" do
			res = true
			fd = session.fs.file.new("meterpreter-test", "wb")
			fd.write("test")
			fd.close

			vprint_status("Wrote to meterpreter-test, checking contents")
			fd = session.fs.file.new("meterpreter-test", "rb")
			contents = fd.read
			vprint_status("Wrote #{contents}")
			res &&= (contents == "test")
			fd.close

			session.fs.file.rm("meterpreter-test")
			res &&= !session.fs.dir.entries.include?("meterpreter-test")

			res
		end

		it "should upload a file" do
			res = true
			remote = "HACKING.remote.txt"
			local  = "HACKING"
			vprint_status("uploading")
			session.fs.file.upload_file(remote, local)
			vprint_status("done")
			res &&= session.fs.dir.entries.include?(remote)
			vprint_status("remote file exists? #{res.inspect}")

			if res
				session.fs.file.download(remote, remote)
				res &&= ::File.file? remote
				downloaded_contents = ::File.read(remote)
				original_contents = ::File.read(local)
				res &&= !!(downloaded_contents == original_contents)
				::File.unlink remote
			end

			session.fs.file.rm(remote)
			res
		end

	end

	def test_sniffer
		begin
			session.core.use "sniffer"
		rescue
			# Not all meterpreters have a sniffer extension, don't count it
			# against them.
			return
		end

		it "should list interfaces" do
			session.sniffer.interfaces.kind_of? Array
		end

		# XXX: how do we test this more thoroughly in a generic way?
	end

protected

	def create_directory(name)
		res = true

		session.fs.dir.mkdir(name)
		entries = session.fs.dir.entries
		res &&= entries.include?(name)
		res &&= session.fs.file.stat(name).directory?
		if res
			vprint_status("Directory created successfully")
		end

		res
	end

end
