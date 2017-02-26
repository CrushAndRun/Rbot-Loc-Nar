require 'rubygems'
require 'mechanize'

class EtymPlugin < Plugin
  def lookup(m, params)
    agent = Mechanize.new
    page = agent.get('http://www.etymonline.com')
    
    search_result = page.form_with(:action => 'http://www.etymonline.com/index.php') do |form|
      form['search'] = params[:term]
    end.click_button
 
    terms = Array.new
    results = search_result.root.xpath('//dl/dd[@class = "highlight"]').each do 
      |term|
      terms.push term.text.gsub(/<\/?[^>]*>/, "")
    end
    charlimit = 200
    result = "#{Bold}#{params[:term]}:#{Bold} #{terms[0]}"
      
    m.reply result
  end
end

plugin = EtymPlugin.new
plugin.map 'lookup :term', :action => :lookup, :thread => true
