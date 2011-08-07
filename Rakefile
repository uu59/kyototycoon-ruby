require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

def do_rspec(opts=["-c"])
  system(*['rspec', opts, 'spec/'].flatten)
end

desc "run rspec"
task :rspec do
  do_rspec
end
namespace :rspec do
  desc "run rspec with coverage"
  task :cov do
    ENV["COV"]="1"
    do_rspec
  end

  desc "run rspec with all of installed versions of ruby"
  task :rvm do
    system("rvm exec 'ruby -e \"puts %Q!=!*48\";ruby -v;rspec -c spec/'")
  end
end

namespace :gem do
  desc "build gem"
  task :build do
    system("gem build kyototycoon.gemspec")
  end

  desc "versioning"
  task :version do
    ver = ENV["VER"]
    if ver.nil?
      puts "version is not specified."
      puts "Usage: VER=x.x.x rake ..."
      exit
    end
    date = Time.now.strftime("%Y-%m-%d")

    # Prefer GNU sed to BSD sed
    sed = [`which gsed`, `which sed`].map{|s| s.strip}.join(" ").strip.split(" ").first
    system("echo lib/kyototycoon.rb  | xargs #{sed} -E -i \"s/VERSION = '[0-9.]+'/VERSION = '#{ver}'/g\"")
    system("echo kyototycoon.gemspec | xargs #{sed} -E -i 's/s.version\s*=\s*\".*\"/s.version = \"#{ver}\"/g'")
    system("echo Gemfile.lock        | xargs #{sed} -E -i 's/kyototycoon \(.*?\)/kyototycoon (#{ver})/g'")
    system("echo kyototycoon.gemspec | xargs #{sed} -E -i 's/s.date = .*$/s.date = %q{#{date}}/g'")
    system("git add -u")
    puts "= NOTICE ="
    puts "ver #{ver}, edit Changes.md for what changed and commit, git tag #{ver}"
  end
end

task :default => ["rspec"]
