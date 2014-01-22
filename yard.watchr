watch('README.md') { system('bundle exec yard doc') }
watch('yard_config/.*') { system('bundle exec yard doc') }
watch('lib/.*\.rb') { system('bundle exec yard doc') }

# vi: ft=ruby
