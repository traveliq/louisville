# encoding: utf-8
if RUBY_VERSION >= "1.9.0"
  require "unicode_utils/canonical_decomposition"
  require "unicode_utils/downcase"
else
  require 'diacritics_fu'
end
require 'active_support'
require 'active_support/version'
if ActiveSupport::VERSION::STRING >= "3.0.0"
  require 'active_support/core_ext'
end

# See Louisville::StringExtensions for the actual functionality
module Louisville
end

require 'louisville/string_extensions'
class String #:nodoc
  include Louisville::StringExtensions
end