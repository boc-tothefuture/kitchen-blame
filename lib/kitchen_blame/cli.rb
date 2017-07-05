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

require 'thor'
require 'kitchen_blame'

module KitchenBlame
  # Processes command line invocation
  class CLI < Thor
    desc 'create KEY LOG', 'Use ssh KEY to analyze create time in a test kitchen LOG'
    def create(key, log)
      KitchenBlame::Blame.analyze_create(key, log)
    end

    desc 'recipe LOG', 'Analyze recipe converge time in a test kitchen LOG'
    def recipe(log)
      KitchenBlame::Blame.analyze_recipe(log)
    end

    desc 'duration LOG', 'Measure duration between all steps in a test kitchen LOG'
    def duration(log)
      KitchenBlame::Blame.analyze_duration(log)
    end

    desc 'version', 'Output kitchen blame version'
    def version
      puts "kitchen blame version: #{KitchenBlame::VERSION}"
    end
  end
end
