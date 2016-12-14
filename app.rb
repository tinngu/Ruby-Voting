require 'rubygems'
require 'sinatra'
require 'csv'
require 'bcrypt'
require 'dm-validations'
require 'rubygems'
require 'zip'
require 'uri'
require './vote'

configure do
  enable :sessions
end

get '/' do
  erb :home
end

get '/login' do
  erb :login
end

get '/logout' do
  session.clear
  redirect to ('/')
end

get '/admin' do
  halt(401, 'Not Authorized') unless session[:role] == 'Admin'
  erb :admin
end

get '/student' do
  halt(401, 'Not Authorized') unless (session[:role] == 'Admin' || session[:role] == 'Student')
  erb :student
end

get '/dataView' do
  halt(401, 'Not Authorized') unless session[:role] == 'Admin'
  @votingData = Vote.all #Stores all data into variable
  @csv = CSV.generate do |csv| #Generates CSV format
    @votingData.each {|x|
      csv << ["#{x.username.to_s}","#{x.first_Pick.to_s}","#{x.second_Pick.to_s}","#{x.third_Pick.to_s}"]
    }
  end
  @dataArray = CSV.parse(@csv) #Convert CSV to an array
  erb :dataView
end

post '/login' do
  user = Vote.get(params[:username])
  if user.nil?
    redirect '/login'
  else
    if BCrypt::Engine.hash_secret(params[:password],user[:salt]) == user[:password_hash]
      if user[:role].casecmp('Admin') == 0
        session[:role] = 'Admin'
        session[:name] = user[:username]
        redirect to('/admin')
      end
      if user[:role].casecmp('Student') == 0
        session[:role] = 'Student'
        session[:name] = user[:username]
        redirect to('student')
      end
    else
      redirect '/login'
    end
  end
end

post '/uploadUsers' do
  halt(401, 'Not Authorized') unless session[:role] == 'Admin'

  begin
    File.open(params['file_source'][:filename], 'wb') do |f|
      f.write(params['file_source'][:tempfile].read)
    end

    file_name = params['file_source'][:filename].to_s

    original = File.open(file_name, 'r') { |file| file.readlines }
    blankless = original.reject{ |line| line.match(/^$/) }

    File.open(file_name, 'w') do |file|
      blankless.each { |line| file.puts line }
    end

    userList = CSV.read(file_name)
    userList.each do |x|
      password = x[1].to_s
      salt = BCrypt::Engine.generate_salt.to_s
      password_hash = BCrypt::Engine.hash_secret(password,salt).to_s
      Vote.create(:username => x[0], :password_hash => password_hash, :salt => salt, :role => x[2])
    end
    File.delete(params['file_source'][:filename].to_s)
  rescue
    puts 'Error: Invalid file upload'
  end

  redirect '/admin'
end

#Used for extracting zip files
def extract_zip(file, destination)
  FileUtils.mkdir_p(destination)

  Zip::File.open(file) do |zip_file|
    zip_file.each { |f|
      f_path=File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path) unless File.exist?(f_path)
    }
  end
end

post '/uploadWebsites' do
  halt(401, 'Not Authorized') unless session[:role] == 'Admin'
  begin
    File.open(params['file_source'][:filename], 'wb') do |f|
      f.write(params['file_source'][:tempfile].read)
    end
    file_name = params['file_source'][:filename].to_s
    file_name = URI.encode(file_name)
    destination = './public/files/'
    extract_zip(file_name, destination)
    File.delete(file_name)
    redirect '/displayWebsites'

  rescue Exception => error
    puts error.message
    puts error.backtrace.inspect
    redirect '/admin'
  end

end

post '/exportCSV' do
  halt(401, 'Not Authorized') unless session[:role] == 'Admin'
  begin
    @votingData = Vote.all #Stores all data into variable
    @csv = CSV.generate do |csv| #Generates CSV format
      @votingData.each {|x|
        csv << ["#{x.username.to_s}","#{x.first_Pick.to_s}","#{x.second_Pick.to_s}","#{x.third_Pick.to_s}"]
      }
    end
    @dataArray = CSV.parse(@csv) #Convert CSV to an array

    File.open('VotingData.csv','wb'){ |x| #Export CSV using the above array
      x << @dataArray.map(&:to_csv).join
    }

    send_file('VotingData.csv', :filename => 'VotingData.csv', :type => 'application/csv')
    File.delete('VotingData.csv')

    puts '****** CSV file was successfully exported ******'
  rescue
    puts '****** CSV was unsuccessful in export ******'

  end

  redirect '/admin'
end

get '/displayWebsites' do
  begin
    halt(401, 'Not Authorized') unless (session[:role] == 'Admin' || session[:role] == 'Student')

    # Source: http://stackoverflow.com/a/15511438
    @website_list = Dir.entries('./public/files/').select {|f| !File.directory? f}

    # Randomly shuffle list of websites
    @website_list = @website_list.shuffle

    erb :displayWebsites
  rescue Exception => error
    puts error.message
    puts error.backtrace.inspect
    redirect '/'
  end

end