CarrierWave.configure do |config|
  config.root = Rails.root.join(Rails.env.production? ? 'tmp' : 'public')
  config.cache_dir = 'uploads'
  if Rails.env.production?
    config.fog_credentials = {
      :provider => 'AWS',
      :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
    }
    config.fog_directory = 'public.citizenbudget.com'
    config.fog_host = '//public.citizenbudget.com'
    config.storage = :fog
  else
    config.storage = :file
  end
end