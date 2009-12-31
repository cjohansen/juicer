#!/usr/bin/env ruby -w

# Datafy code lifted from http://segment7.net/projects/ruby/datafy/

require 'base64'
require 'cgi'

module Datafy
  def Datafy::make_data_uri(content, content_type)
    outuri = 'data:' + content_type
    unless content_type =~ /^text/i # base64 encode if not text
      outuri += ';base64'
      content = Base64.encode64(content).gsub("\n", '')
    else
      content = CGI::escape(content)
    end
    outuri += ",#{content}"
  end
  
end