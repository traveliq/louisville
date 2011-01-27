# encoding: utf-8
# = Unicode To ASCII - Louisville Library
#
# This module provides some Extensions to handle conversions of Strings
# in a central place.
# The methods defined here get mostly put "into" the String class - so, for
# example, you can just call
# <tt>"Öxleschloß".asciify => "Oexleschloss"</tt>, if you require this
# plugin.
module Louisville::StringExtensions

  # Default replacements for german special characters.
  DEFAULT_PRE_ASCIIFY_REPLACEMENTS = {
    "ß" => "ss",
    "ä" => "ae",
    "Ä" => "Ae",
    "ö" => "oe",
    "Ö" => "Oe",
    "Ü" => "Ue",
    "ü" => "ue"
  }

  ABBREVIATIONS = {
    %w(st skt saint snt) => 'sankt'
  }

  def self.pre_ascii_replacements
    @@pre_ascii_replacements ||= DEFAULT_PRE_ASCIIFY_REPLACEMENTS
  end

  # Call with a Hash of replacements (what you want to replace as keys, the
  # replacement as the value) to define your own replacements.
  # Tip: If you can't put the character to be replaced into code, because
  # your editor is stupid, or if you want to confuse people, you can escape
  # strings like this : "\341\270\251", which is the "C octal escaped"
  # version (which you can get from tools like "Character map".
  #
  # When called with +nil+, it will reset the replacement map to the
  # default one.
  def self.pre_ascii_replacements=(replacements)
    if replacements.nil?
      @@pre_ascii_replacements = DEFAULT_PRE_ASCIIFY_REPLACEMENTS
    elsif !replacements.is_a?(Hash)
      raise "I need a Hash !"
    else
      @@pre_ascii_replacements = replacements
    end
    @@pre_ascii_replacements
  end

  def self.asciify(string, replacements = nil)
    replace = replacements || pre_ascii_replacements
    replace.each do |character, replacement|
      string.gsub!(character, replacement)
    end

    if RUBY_VERSION >= "1.9.0"
      UnicodeUtils.canonical_decomposition(string).split(//u).reject { |e| e.bytesize > 1 }.join
    else
      DiacriticsFu::escape(string)
    end
  end

  def self.downcase(string)
    if RUBY_VERSION >= "1.9.0"
      UnicodeUtils.downcase(string)
    elsif ActiveSupport::VERSION::STRING >= "2.2.0"
      string.mb_chars.downcase.to_s
    else
      string.chars.downcase.to_s
    end
  end

  # Returns a clone of this String in which all replacements in
  # +pre_ascii_replacements+ have been made, and all characters that are not
  # in ASCII either replaced by their ASCII base form (like s is to ş), or
  # if that is not possible, removed.
  # The result should be a string that is closest in meaning and appearance
  # to the original string, but which can be encoded entirely in ASCII.
  # This also means that punctuation is not removed or changed.
  #
  # May return an empty String if the original string was empty (duh.), or
  # all characters were removed. This can happen on characters that LOOK
  # like ASCII chars, but really aren't, like some cyrillic chars.
  #
  # You can define other replacements permanently with the
  # +pre_ascii_replacements+ method, or you can pass in a Hash with
  # replacements just for one call. Call without argument to use the
  # default/predefined replacement map.
  def asciify(replacements = nil)
    Louisville::StringExtensions.asciify(self.clone, replacements)
  end

  # Does all that +asciify+ does, but also downcases the string and removes
  # everything but lowercase characters, numbers, and spaces.
  def flattenize(replacements = nil)
    replace = replacements || Louisville::StringExtensions.pre_ascii_replacements
    Louisville::StringExtensions.downcase(asciify(replace)).gsub(/[^a-z\s\d]/, "").to_s
  end

  # Reverses a commified string. eg.
  #   "Beatles, The".decommafy        #=> "The Beatles"
  def decommafy
    gsub(/(.+), (.+)/) { |s| "#{$2} #{$1}" }.strip.squeeze(' ')
  end

  # Removes bracketed items from a string. eg.
  #   "I (really) smell".debracketize #=> "I smell"
  #   "(( I am in brackets ))" #=> "I am in brackets"
  def debracketize
    if strip[0] == 40 and strip[-1] == 41
      return strip.gsub(/^\(+(.+?)\)+$/) { $1.strip }
    else
      return strip.gsub(/\(+.+?\)+/, '').strip.squeeze(' ')
    end
  end

  # Removes all non alphabetic, numeric, or whitespace characters (except
  # dashes and underscores). eg.
  #   "I am! I (am!) "                #=> "I am I am "
  def plainify
    gsub(/[^0-9a-zA-Z_\- ]/, '').strip.squeeze(' ')
  end

  # Turns spaces, underscores, forward slashes and tildas to hyphens, and
  # reduces double hyphens to single hyphens. eg.
  #   "The_long__way_home/blah!"      # => "The-long-way-home-blah!"
  def dashify
    strip.gsub(/[ \/_~]/, '-').squeeze('-')
  end

  # Turns a string like "Süd Korea, (the) Republik" into
  # "republik-sued-korea". Useful for database name normalising. Returns nil
  # if this string is blank.
  def normalize
    return if blank?
    string = respond_to?(:force_encoding) ? self.force_encoding("UTF-8") : self
    Louisville::StringExtensions.downcase(string.asciify).deabbreviate.decommafy.debracketize.plainify.dashify
  end

  # Turns "St. Gallen" or "St Gallen" or "Skt. Gallen" into "Sankt Gallen"
  def deabbreviate
    str = clone
    ABBREVIATIONS.each do |abbreviations, replacement|
      abbreviations.each do |abbreviation|
        str = str.gsub(/\b#{abbreviation}[\.\b\s-]+/i, "#{replacement} ")
      end
    end
    str
  end
end