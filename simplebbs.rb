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
      if b.userid == @u
        @t += "<td><form action=\"/delete\" method=\"post\">"
        @t += "<input type=\"hidden\" name=\"id\" value=\"#{b.id}\">"
        @t += "<input type=\"hidden\" name=\"_method\" value=\"delete\">"
        @t += "<input type=\"submit\" value=\"Delete\">"
        @t += "</form></td>"
      else
        @t += "<td></td>"
      end
      @t += "</tr>"
      @t += "<td><td colspan=\"3\">#{b.entry}</tb></td>\n"
    end
  end

  erb :contents
end

# pp. 179

post '/new' do
  maxid = 0
  a = BBSdata.all
  a.each do |b|
    if b.id > maxid
      maxid = b.id
    end
  end

  s = BBSdata.new
  s.id = maxid + 1
  s.userid = session[:username]
  s.entry = params[:entry]
  s.writedate = Time.now.to_i
  s.save

  redirect '/contents'
end

delete '/delete' do
  s = BBSdata.find(params[:id])
  s.destroy

  redirect '/contents'
end
