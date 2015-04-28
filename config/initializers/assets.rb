# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( viewer.js viewer.css )
# pdfjs
Rails.application.config.assets.precompile += %w( *.png *.svg *.gif pdfjs/pdf.worker.js pdfjs/locale/*.properties )
# email
Rails.application.config.assets.precompile += %w( email.css )

# disable image_optim for assets
Rails.application.config.assets.image_optim = false