# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_likestream_session',
  :secret      => 'c1bd119d3e076fa053b14630b98238207f4c554167d8c293fb516fbede55e5ff43fe5ac50468f28076eafe2be2221f53f1dafdaab5f2a9ce6c36c63fc870ad76'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
