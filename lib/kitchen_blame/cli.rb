require 'thor'
require 'kitchen_blame'

module KitchenBlame
  class CLI < Thor
    desc 'create LOG', 'Analyze create time in a test kitchen LOG'
    def create(log)
      KitchenBlame::Blame.analyze_create(log)
    end

    desc 'recipe LOG', 'Analyze recipe converge time in a test kitchen LOG'
    def recipe(log)
      KitchenBlame::Blame.analyze_recipe(log)
    end

    desc 'duration LOG', 'Measure duration between all steps in a test kitchen LOG'
    def duration(log)
      KitchenBlame::Blame.analyze_duration(log)
    end
  end
end
