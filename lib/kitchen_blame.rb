#
# (C) Copyright IBM Corporation 2017.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kitchen_blame/version'
require 'date'
require 'json'
require 'pathname'

module KitchenBlame
  # Main class
  class Blame
    LOG_DIR = (Pathname.getwd + Pathname.new('.kitchen/logs')).freeze

    # Return the DateTime object from a regex match with a named capture of 'time'
    def self.extract_time(match)
      time = match[:time]
      time = time.split('.').first
      DateTime.strptime("#{time} #{Time.now.getlocal.zone}", '%Y-%m-%dT%H:%M:%S %Z')
    end

    # Return the DateTime object from a regex match with a named capture of 'time'
    def self.extract_syslog_time(entry)
      time = entry['__REALTIME_TIMESTAMP']
      time = (time.to_f / 1_000_000).to_s
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

    def self.list(dir)
      Pathname.new(dir).each_child.select(&:file?).each do |log_dir_entry|
        next if log_dir_entry.basename.to_s == 'kitchen.log'
        next unless log_dir_entry.extname == '.log'
        puts log_dir_entry.basename('.log')
      end
    end

    # Determine the appropriate log file or raise an error
    def self.resolve_log(log)
      log_path = Pathname.new(log)
      return log_path.to_path if log_path.exist? && log_path.file?
      log_path = LOG_DIR + log_path
      return log_path.to_path if log_path.exist? && log_path.file?
      LOG_DIR.each_child.select(&:file?).each do |log_dir_entry|
        return log_dir_entry.to_path if log_dir_entry.basename.fnmatch("*#{log}*")
      end
      fail "Unable to fully qualify or find test kitchen log #{log}"
    end

    def self.analyze_create(key_path, log)
      log = resolve_log(log)
      server_log_entries = server_log_entries(key_path, log)
      create_duration = image_create(log, server_log_entries)
      startup_finished_entry = server_log_entries.find { |entry| entry['MESSAGE'].include?('Startup finished') }
      boot_start = extract_syslog_time(server_log_entries.first)
      boot_finish = extract_syslog_time(startup_finished_entry)
      boot_duration = measure_duration(boot_start, boot_finish)
      puts "Image create took #{create_duration} seconds"
      puts "Boot took #{boot_duration} seconds"
      puts "Systemd timing: #{startup_finished_entry['MESSAGE']}"
    end

    def self.server_log_entries(key_path, log)
      ip = File.foreach(log).grep(/Attaching floating IP </).first[/\<(?<ip>.*)\>/, 'ip']
      server_log_entries = `ssh -i #{key_path} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@#{ip} 'sudo journalctl -o json --no-pager' 2>/dev/null`.split("\n")
      server_log_entries.map { |entry| JSON.parse(entry) }
    end

    def self.image_create(log, server_log_entries)
      boot_start = extract_syslog_time(server_log_entries.first)
      create_line = File.foreach(log).grep(/Creating/).first
      match_data = /.,\s\[(?<time>.*)\]\s+[^:]+:(?<log>.*)$/.match(create_line)
      create_time = extract_time(match_data)
      measure_duration(create_time, boot_start)
    end

    # rubocop:disable MethodLength
    def self.analyze_recipe(log)
      log = resolve_log(log)
      recipe_lines = IO.readlines(log).grep(/Recipe:/).map do |line|
        match_data = /\[(?<time>.*)\].*Recipe:\s(?<recipe>.*)$/.match(line)
        next unless match_data
        time = extract_time(match_data)
        recipe = match_data[:recipe]
        { recipe: recipe, time: time }
      end
      recipe_lines.compact.each_cons(2) do |pair|
        recipe = pair.first[:recipe]
        duration = measure_pair(pair)
        puts "#{duration} seconds for recipe #{recipe}"
      end
    end
    # rubocop:enable MethodLength

    # rubocop:disable MethodLength
    def self.analyze_duration(log)
      log = resolve_log(log)
      log_lines = IO.readlines(log).map do |line|
        match_data = /.,\s\[(?<time>.*)\]\s+[^:]+:(?<log>.*)$/.match(line)
        next unless match_data
        time = extract_time(match_data)
        log = match_data[:log]
        { log: log, time: time }
      end
      log_lines.compact.each_cons(2) do |pair|
        log = pair.first[:log]
        duration = measure_pair(pair)
        puts "#{duration} seconds for entry #{log}"
      end
    end
    # rubocop:enable MethodLength
  end
end
