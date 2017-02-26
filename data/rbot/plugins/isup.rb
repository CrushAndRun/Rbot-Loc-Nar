# Title: isup.me plugin for rbot
#
# Author: Rob Bruce <rb.cubed@gmail.com>
#
# Copyright: (C) 2011 Rob Bruce
#
# License: GPL v2
#
# Uses isup.me to check if a website is up or down

require 'rubygems'
require 'mechanize'

class IsupPlugin < Plugin

  def help(plugin, topic)
    "isup <site> => Check status of a website"
  end

  def isup(m, params)
    site = params[:site]
    agent = Mechanize.new
    page = agent.get('http://www.isup.me/' + site)

    page.root.xpath("//*[@id='container']").each do
      |li|
      if li.text =~ /It's just you. (.*)/
        m.reply "It's up! http://" + site
      else
        m.reply "It's down!"
      end
    end
  end
end

plugin = IsupPlugin.new
plugin.map 'isup [:site]', :action => :isup, :thread => true
