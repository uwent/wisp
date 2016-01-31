# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
#
Rails.application.config.assets.precompile += %w( jqgrid/jquery-ui-1.7.1.custom.css )
Rails.application.config.assets.precompile += %w( jqgrid/ui.jqgrid.css )
Rails.application.config.assets.precompile += %w( jqgrid/jquery-1.7.2.min.js )
Rails.application.config.assets.precompile += %w( jqgrid/jquery-ui-1.8.22.custom.min.js )
Rails.application.config.assets.precompile += %w( jqgrid/i18n/grid.locale-en.js )
Rails.application.config.assets.precompile += %w( jqgrid/jquery.jqGrid.min.js )
