# 🏇 Reins

A Rack-based web framework with extra awesome! Reins is an exercise to understand Rails better by rebuilding it from scratch.

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/reins`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

## Usage

```sh
mkdir $APP_NAME
cd $APP_NAME
git init
mkdir config
mkdir app
touch Gemfile
echo "source 'https://rubygems.org'" > Gemfile
echo "gem \"reins\"" >> Gemfile
bundle install

rackup -p 3001

bundle exec rerun -- rackup -p 3001
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tacoda/reins.

## Resources

Useful resources to make the framework more robust:

- [Rack Spec](https://github.com/rack/rack/blob/main/SPEC.rdoc)
- [Rails on Rack](https://guides.rubyonrails.org/rails_on_rack.html)
- [ActiveModel: Make Any Ruby Object Feel Like ActiveRecord](https://yehudakatz.com/2010/01/10/activemodel-make-any-ruby-object-feel-like-activerecord/)

## TODO

- Find examples in Rails and add them to this repository for extra functionality