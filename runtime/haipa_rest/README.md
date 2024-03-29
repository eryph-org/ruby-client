# Intro

haipa_rest is a library which supports the Haipa clients generated with Autorest tool. It contains core logic and helper classes for error handling and authentication. 
Usually it is not supposed to be used as a standalone gem but only as a dependency for generated client gems.

This project has been forked from the Microsoft Azure ruby client (https://github.com/Azure/azure-sdk-for-ruby)

# Supported Ruby Versions

* Ruby 2.0
* Ruby 2.1
* Ruby 2.2

Note: x64 Ruby for Windows is known to have some compatibility issues.

# Installation

install the appropriate gem:

```
gem install haipa_rest
```

and reference it in your code:

```Ruby
require 'haipa_rest'
```

# Running tests

haipa_rest has only unit tests which doesn't require any preparation, just run 'rspec' command from the gem directory.

# Contribution

To start working on the gem the only additional dev dependecy is required - rspec. After you've added a new feature and all specs pass - you're good to go with PR. But before starting any bug/feature - please make sure you've thoroughly discussed it with repository maintainers. This gem already powers a few SDKs and backward compatibility should taken in account.

# Adding gem to you generated SDK

Reference it in the gemfile and also add this line to your client's gemspec file:

```ruby
spec.add_runtime_dependency 'haipa_rest', '~> 0.11.1'
```
Don't forget to correct the version.


