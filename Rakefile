require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'
require 'appraisal'
require 'erb'
require_relative 'lib/shoulda/matchers/version'

CURRENT_VERSION = Shoulda::Matchers::VERSION

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.rspec_opts = '--color --format progress'
  t.verbose = false
end

Cucumber::Rake::Task.new do |t|
  t.fork = false
  t.cucumber_opts = ['--format', (ENV['CUCUMBER_FORMAT'] || 'progress')]
end

task :default do
  if ENV['BUNDLE_GEMFILE'] =~ /gemfiles/
    Rake::Task['spec'].invoke
    Rake::Task['cucumber'].invoke
  else
    Rake::Task['appraise'].invoke
  end
end

task :appraise do
  exec 'appraisal install && appraisal rake'
end

GH_PAGES_DIR = '.gh-pages'

namespace :docs do
  file GH_PAGES_DIR do
    sh "git clone git@github.com:thoughtbot/shoulda-matchers.git #{GH_PAGES_DIR} --branch gh-pages"
  end

  task :setup => GH_PAGES_DIR do
    within_gh_pages do
      sh 'git fetch origin'
      sh 'git reset --hard origin/gh-pages'
    end
  end

  desc 'Generate docs for a particular version'
  task :generate, [:version, :is_latest] => :setup do |t, args|
    latest = (args.is_latest == 'true')
    generate_docs(args.version, latest: latest)
  end

  desc 'Generate docs for a particular version and push them to GitHub'
  task :publish, [:version, :is_latest] => :setup do |t, args|
    latest = (args.is_latest == 'true')
    generate_docs(args.version, latest: latest)
    publish_docs(args.version, latest: latest)
  end

  desc "Generate docs for version #{CURRENT_VERSION} and push them to GitHub"
  task :publish_latest => :setup do
    generate_docs(CURRENT_VERSION, latest: true)
    publish_docs(CURRENT_VERSION, latest: true)
  end

  def rewrite_index_to_inject_version(ref, version)
    within_gh_pages do
      filename = "#{ref}/index.html"
      content = File.read(filename)
      content.sub!(%r{<h1>shoulda-matchers.+</h1>}, "<h1>shoulda-matchers (#{version})</h1>")
      File.open(filename, 'w') {|f| f.write(content) }
    end
  end

  def generate_docs(version, options = {})
    ref = determine_ref_from(version)

    sh "rm -rf #{GH_PAGES_DIR}/#{ref}"
    sh "bundle exec yard -o #{GH_PAGES_DIR}/#{ref}"

    rewrite_index_to_inject_version(ref, version)

    within_gh_pages do
      sh "git add #{ref}"
    end

    if options[:latest]
      generate_file_that_redirects_to_latest_version(ref)
    end
  end

  def publish_docs(version, options = {})
    message = build_commit_message(version, options)

    within_gh_pages do
      sh 'git clean -f'
      sh "git commit -m '#{message}'"
      sh 'git push'
    end
  end

  def generate_file_that_redirects_to_latest_version(version)
    erb = ERB.new(File.read('doc_config/gh-pages/index.html.erb'))

    within_gh_pages do
      File.open('index.html', 'w') { |f| f.write(erb.result(binding)) }
      sh 'git add index.html'
    end
  end

  def determine_ref_from(version)
    if version =~ /^\d+\.\d+\.\d+/
      'v' + version
    else
      version
    end
  end

  def build_commit_message(version, options)
    if options[:latest]
      "Regenerated docs for latest version #{version}"
    else
      "Regenerated docs for version #{version}"
    end
  end

  def within_gh_pages(&block)
    Dir.chdir(GH_PAGES_DIR, &block)
  end
end

task release: 'docs:publish_latest'
