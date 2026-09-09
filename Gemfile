source 'https://rubygems.org'
gemspec

ruby ">= 3"

# Faraday 2.14.x (version that OpenProject core has) calls JSON.parse(body, opts)
# with a positional Hash. json 3.0 made those options keyword-only, which
# breaks this gem's tests. Pin json 2.x for bundling during testing
gem "json", "~> 2.21"
