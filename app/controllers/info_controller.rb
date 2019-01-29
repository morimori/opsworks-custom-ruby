class InfoController < ApplicationController
  def show
    render json: JSON.pretty_generate({
      commit: `git log --oneline -1`&.strip,
      ruby: {
        path: RbConfig.ruby,
        version: RUBY_VERSION,
      },
      rails: {
        version: Rails.version
      },
      rubygems: {
        version: Gem::RubyGemsVersion,
        gems: Hash[Gem.loaded_specs.map{|_, spec| [spec.name, spec.version.to_s]}.sort],
      }
    }), layout: false
  end
end
