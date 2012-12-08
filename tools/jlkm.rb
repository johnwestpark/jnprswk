#!/usr/bin/env ruby
#*
#* Author         : Jeremy Schulman
#* Program        : jlkm
#* Date           : 2012-DEC-07
#* Description    :
#*
#*    This program is used to automate the function of generating
#*    and/or retrieving license keys for the QFX and EX devices
#*    The manual process is to use the Juniper Support website.
#*    This program "automates the website". 
#*
#*    See the 'README' file for usage and examples
#*
#* Copyright (c) 2012  Juniper Networks. All Rights Reserved.
#*
#* YOU MUST ACCEPT THE TERMS OF THIS DISCLAIMER TO USE THIS SOFTWARE, 
#* IN ADDITION TO ANY OTHER LICENSES AND TERMS REQUIRED BY JUNIPER NETWORKS.
#* 
#* JUNIPER IS WILLING TO MAKE THE INCLUDED SCRIPTING SOFTWARE AVAILABLE TO YOU
#* ONLY UPON THE CONDITION THAT YOU ACCEPT ALL OF THE TERMS CONTAINED IN THIS
#* DISCLAIMER. PLEASE READ THE TERMS AND CONDITIONS OF THIS DISCLAIMER
#* CAREFULLY.
#*
#* THE SOFTWARE CONTAINED IN THIS FILE IS PROVIDED "AS IS." JUNIPER MAKES NO
#* WARRANTIES OF ANY KIND WHATSOEVER WITH RESPECT TO SOFTWARE. ALL EXPRESS OR
#* IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING ANY WARRANTY
#* OF NON-INFRINGEMENT OR WARRANTY OF MERCHANTABILITY OR FITNESS FOR A
#* PARTICULAR PURPOSE, ARE HEREBY DISCLAIMED AND EXCLUDED TO THE EXTENT
#* ALLOWED BY APPLICABLE LAW.
#*
#* IN NO EVENT WILL JUNIPER BE LIABLE FOR ANY DIRECT OR INDIRECT DAMAGES, 
#* INCLUDING BUT NOT LIMITED TO LOST REVENUE, PROFIT OR DATA, OR
#* FOR DIRECT, SPECIAL, INDIRECT, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE DAMAGES
#* HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY ARISING OUT OF THE 
#* USE OF OR INABILITY TO USE THE SOFTWARE, EVEN IF JUNIPER HAS BEEN ADVISED OF 
#* THE POSSIBILITY OF SUCH DAMAGES.
#*
require 'rubygems'
require 'optparse'
require 'highline/import'
require 'jnprswk'

puts <<EOB

   --- Juniper Networks Webkit ---
       License Key Management
              v0.0.1
        (nonprod, no-JTAC)
        
EOB
  
# -------------------------------------------------------------------
# Parse Command Line Args
# -------------------------------------------------------------------

class JnprSWKappLkm
  
  def initialize
    @options = {}    
    # default options
    @options[:outputformat] = 'console'
    @options[:action] = :retrieve
    
    OptionParser.new do |opts|
      opts.on( '-u', '--user [USER-NAME]', 'User-Name') do |username|
        @options[:username] = username
      end
      opts.on( '-s', '--sn [SERIAL-NUMBER]', 'Device Serial-Number') do |sn|
        @options[:sn] = sn
      end
      opts.on( '-r', '--rtu [RTU-NUMBER]', 'Right-To-Use Number') do |rtu|
        @options[:rtu] = rtu
      end
      opts.on( nil, '--QFX', 'Generate license for QFX Device') do
        @options[:device] = :QFX
      end
      opts.on( nil, '--EX', 'Generate license for EX Device') do
        @options[:device] = :EX
      end
      opts.on( '-f', '--file [FILE-NAME]', 'File containing SN,RTU' ) do |filename|
        @options[:filename] = filename    
      end
      opts.on( '-F', '--ofile', 'License key output saved in file' ) do |format|
        @options[:outputformat] = 'file'
      end
      opts.on( '-R', '--retrieve', 'Retrieve License Key' ) do
        @options[:action] = :retrieve
      end
      opts.on( '-K', '--keygen', 'Generate License Key' ) do
        @options[:action] = :keygen
      end  
      end.parse!
      
      unless login
        puts "! ERROR: Unable to login, please try again."
        exit 1  
      end
      
      run
    end

    # -------------------------------------------------------------------
    # Login to Junipe Support Site, License Key Management
    # -------------------------------------------------------------------
    
    def login      
      puts "Logging into Juniper Support ... "
      if @options[:username]
        puts "username: #{@options[:username]}"
      else
        @options[:username] = ask("username: ") unless @options[:username]
      end
      @options[:password] = ask("password: ") { |q| q.echo = false }
      
      @lkm = JuniperSupportWebkit::LKM.new{ |auth|
        auth.username = @options[:username]
        auth.password = @options[:password] 
      }.login            
    end    
    
    def run
      if @options[:filename]
        process_file
      else
        process_opts
      end
    end
    
    def output_license( license )
      case @options[:outputformat]
      when 'file'
        fname = "#{license.sn}.license"
        puts "Writing file #{fname}"
        File.open( fname, 'w' ){ |f| f.write( license ) }          
      else
        puts license
      end  
    end    
    
    def process_file              
      puts "Loading SN/RTU data from file: #{@options[:filename]} ..."
      begin    
        lkm_data = JuniperSupportWebkit::LKM::DataFile.new( @options[:filename] ) if @options[:filename]
      rescue => err
        puts err  
        exit 1
      end
      
      case @options[:action]
      when :retrieve
        lkm_data.each do |item|      
          sn = item[:sn]
          puts "Retrieving license for: #{sn} ... "    
          if license = @lkm.get_license_by_sn( sn )
            output_license( license )
          else
            puts "! ERROR: No license available for: #{sn}"
          end
        end
      when :keygen
        unless @options[:device]
          puts "You must specific a device type, see 'help'"
          return
        end            
        lkm_data.each do |item|      
          opt_hash = { :device => @options[:device] }.merge( item )
          license_activate( opt_hash )
        end        
      end
    end
  
    def license_activate( opt_hash )
      puts "Generate License Key for SN: #{opt_hash[:sn]} using RTU: #{opt_hash[:rtu]}"
      
#      exit 1 unless ask( "Proceed [y/N]? ") =~ /y|Y|yes/
      
      # first, determine if the serial-number is already activated ...
      puts "First checking SN for existing license ... "
      if license = @lkm.get_license_by_sn( opt_hash[:sn] )
        puts "A license is already bound to serial-nubmer: #{license.sn}"
      else
        puts "Activating RTU on SN ... "
        license = @lkm.activate_rtu( opt_hash )
      end
      output_license( license )      
    end
    
    def process_opts
      
      @options[:sn] = ask("serial-number: ") unless @options[:sn]
            
      if @options[:rtu] and @options[:sn]        
        unless @options[:device]
          puts "You must specific a device type, see 'help'"
          exit 1
        end        
        license_activate( @options )                
      else      
        puts "Retrieving license for: #{@options[:sn]} ... "
        
        unless license = @lkm.get_license_by_sn( @options[:sn] )
          puts "! ERROR: No license available for: #{@options[:sn]}"
          exit 1
        end
        
        output_license( license )    
      end
    end
end

JnprSWKappLkm.new





