# frozen_string_literal: true

require 'sinatra'
require 'active_record'
require 'digest/sha2'

set :environment, :production

set :sessions,
    expire_after: 7200,
    secret: ENV['SESSION_SECRET']

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

# Represents a record in the 'bbsdata' table.
class BBSdata < ActiveRecord::Base
  self.table_name = 'bbsdata'
end

class Account < ActiveRecord::Base
  self.table_name = 'account'
end

get '/' do
  redirect '/login'
end

get '/login' do
  erb :login
end

post '/auth' do
  user = params[:uname]
  pass = params[:pass]

  r = checkLogin(user, pass)

  if r == 1
    session[:username] = user
    redirect '/contents'
  end

  redirect '/loginfailure'
end

def checkLogin(trial_username, trial_password)
  r = 0

  begin
  a = Account.find(trial_username)
  db_username = a.id
  db_salt = a.salt
  db_hashed = a.hashed
  trial_hashed = Digest::SHA256.hexdigest(trial_password + db_salt)

  if trial_hashed == db_hashed
    r = 1
  end

  rescue => e
    r = 2
  end

  return(r)
end

get '/logout' do
  session.clear
  erb :logout
end

get '/loginfailure' do
  session.clear
  erb :loginfailure
end

get '/contents' do
  @u = session[:username]

  if @u == nil
    redirect '/badrequest'
  end

  a = BBSdata.all
  if a.count == 0
  @t = "<tr><td>No entries in this BBS.</td></tr>"
  else
  @t = ""
  a.each do |b|
  @t = @t + "<tr>"
  @t += "<td>#{b.id}</td>"
  @t += "<td>#{b.userid}</td>"
  @t += "<td>#{Time.at(b.writedate)}</td>"
  @t += "</tr>"
  @t += "<td><td colspan=\"3\">#{b.entry}</tb></td>\n"
  end
  end

  erb :contents
end
