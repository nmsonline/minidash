require 'httparty'

lines = ['central','circle','hammersmithcity','metropolitan','northern','victoria']

SCHEDULER.every '300s', :first_in => 10 do |job|
	statuses = Array.new

	result = HTTParty.get("http://api.tubeupdates.com/?method=get.status&lines=#{lines.join(',')}&format=json")
	raw_stats = JSON.parse(result.parsed_response)['response']['lines'].select { |s| lines.include? s['id']}
	
	# the API can return dups so we need to sort them and pick the top one
	stats = []
	# group them by line
	grouped = raw_stats.group_by { |i| i['id'] }
	# sort each group and pick the most recent update
	grouped.values.each do |line|
		line_updates = []
		begin
			line_updates = line.sort { |i| DateTime.parse(i['status_starts']) }
			stats << line_updates.first unless line_updates.empty?
		rescue 
			# nop
		end
	end
	
	stats.each do |line|
		if line['status'] == 'good service'
			result = 1
		elsif line['status'] == 'minor delays'
			result = 2
		else
			result = 0
		end
		
		if result == 1
			arrow = "icon-ok-sign"
			color = "green"
		elsif result == 2
			arrow = "icon-warning-sign"
			color = "yellow"
		else
			arrow = "icon-warning-sign"
			color = "red"
		end

		statuses.push({label: line['id'], value: result, arrow: arrow, color: color })
	end

	send_event('tfl_status', {items: statuses})
end