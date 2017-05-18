require "kitchen_blame/version"
require 'date'
require 'json'

module KitchenBlame
  class Blame

    # Return the DateTime object from a regex match with a named capture of 'time'
    def self.extract_time(match)
      time = match[:time]
      time = time.split('.').first
      DateTime.strptime("#{time} #{Time.now.getlocal.zone}", '%Y-%m-%dT%H:%M:%S %Z')
    end

    # Return the DateTime object from a regex match with a named capture of 'time'
    def self.extract_syslog_time(entry)
      time = entry['__REALTIME_TIMESTAMP']
      time = (time.to_f / 1000000 ).to_s
      DateTime.strptime(time, '%s')
    end

    # Return the duration for two Datetime objects
    def self.measure_duration(start, finish)
      ((finish - start) * 24 * 60 * 60).to_i
    end

    # Return the duration for two objects that both have time fields in a hash
    def self.measure_pair(pair)
      ((pair.last[:time] - pair.first[:time]) * 24 * 60 * 60).to_i
    end

    def self.analyze_create(log)
      create_line = File.foreach(log).grep(/Creating/).first
      match_data = /.,\s\[(?<time>.*)\]\s+[^:]+:(?<log>.*)$/.match(create_line)
      create_time = extract_time(match_data)
      ip = File.foreach(log).grep(/Attaching floating IP </).first[/\<(?<ip>.*)\>/,'ip']
      server_log_entries = `ssh -i ~/.kitchen/vagrant_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@#{ip} 'sudo journalctl -o json --no-pager' 2>/dev/null`.split("\n")
      server_log_entries = server_log_entries.map {|entry| JSON.parse(entry) }
      boot_start = extract_syslog_time(server_log_entries.first)
      create_duration =  measure_duration(create_time,boot_start)

      startup_finished_entry = server_log_entries.find { |entry| entry['MESSAGE'].include?('Startup finished') }
      boot_finish = extract_syslog_time(startup_finished_entry)
      boot_duration =  measure_duration(boot_start,boot_finish)
      puts "Create took #{create_duration} seconds"
      puts "Boot took #{boot_duration} seconds"
      puts "Systemd timing: #{startup_finished_entry['MESSAGE']}"

    end

    def self.analyze_recipe(log)
      IO.readlines(log).grep(/Recipe:/).map do |line|
        match_data = /\[(?<time>.*)\].*Recipe:\s(?<recipe>.*)$/.match(line)
        time = extract_time(match_data)
        recipe = match_data[:recipe]
        { recipe: recipe, time: time }
      end.each_cons(2) do |pair|
        recipe = pair.first[:recipe]
        duration = measure_pair(pair)
        puts "#{duration} seconds for recipe #{recipe}"
      end
    end


    def self.analyze_duration(log)
      IO.readlines(log).map do |line|
        match_data = /.,\s\[(?<time>.*)\]\s+[^:]+:(?<log>.*)$/.match(line)
        time = extract_time(match_data)
        log = match_data[:log]
        { log: log, time: time }
      end.each_cons(2) do |pair|
        log = pair.first[:log]
        duration = measure_pair(pair)
        puts "#{duration} seconds for entry #{log}"
      end
    end
  end
end
