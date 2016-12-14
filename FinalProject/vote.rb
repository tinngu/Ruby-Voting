require 'dm-core'
require 'dm-migrations'
require 'dm-sqlite-adapter'
require 'data_mapper'

configure do
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/development.db")
end

class Vote
  include DataMapper::Resource

  property :username, String, key: true
  property :password_hash, String, :length => 100
  property :salt, String
  property :role, String
  property :first_Pick, String
  property :second_Pick, String
  property :third_Pick, String
end

DataMapper.finalize()

get '/voter/:username' do
  begin
    @voter = Vote.get(params[:username])
    halt(401, 'Invalid User Access!') unless (session[:name].casecmp(@voter.username) == 0)
    #CLEAN UP TIME!
    @voter.first_Pick = @voter.first_Pick.gsub(/[^A-Za-z0-9\-\.]/, '')
    @voter.second_Pick = @voter.second_Pick.gsub(/[^A-Za-z0-9\-\.]/, '')
    @voter.third_Pick = @voter.third_Pick.gsub(/[^A-Za-z0-9\-\.]/, '')

    #You use save to persist changes made to a loaded resource and
    # you use update when you want to immediately persist changes
    # without changing resource's state to 'dirty'.
    @voter.save
    erb :showvote
  rescue
    puts '****** TEST FLAG!! ******'
    @voter = Vote.get(params[:username])
    erb :showvote
  end


end

get '/voter/:username/cast' do
  @voter = Vote.get(params[:username])
  halt(401, 'Invalid User Access') unless (session[:name].casecmp(@voter.username) ==0)
  halt(401, 'You have already voted!') unless ([@voter.first_Pick, @voter.second_Pick,@voter.third_Pick].all?{|x| x == nil || x == ''})
  erb :cast
end

put '/voter/:username' do
  voter = Vote.get(params[:username])
  halt(401, 'Invalid User Access') unless (session[:name].casecmp(voter.username) ==0)
  voter.update(params[:voter])
  redirect to("/voter/#{voter.username}")
end