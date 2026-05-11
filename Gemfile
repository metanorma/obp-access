source "https://rubygems.org"

gemspec

gem "sts", path: "../sts-ruby" if Dir.exist?("../sts-ruby")

group :development do
  gem "rake"
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
end

group :test do
  gem "rspec"
end
