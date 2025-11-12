#!/usr/bin/env ruby
require 'cgi'

puts CGI.escapeHTML("<h1>An example of XSS</h1>")
