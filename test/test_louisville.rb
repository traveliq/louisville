# encoding: utf-8
require 'helper'
class TestLouisville < Test::Unit::TestCase
  def test_basic_asciify
    assert_equal "Oexleschloss", (result = "Öxleschloß".asciify)
    assert(result.is_a?(String))
    assert_equal "oe-Oe-ue-Ue-ae-Ae-ss", (result = "ö-Ö-ü-Ü-ä-Ä-ß".asciify)
    assert(result.is_a?(String))
    assert_equal "IEa", (result = "ÌË\307\237".asciify)
    assert(result.is_a?(String))
  end

  def test_basic_flattenize
    assert_equal "oexleschloss", (result = "Öxleschloß".flattenize)
    assert(result.is_a?(String))
    assert_equal "call 911", (result = ",ċ.-Ąl{l +9}-´`1#\{1".flattenize)
    assert(result.is_a?(String))
  end

  def test_basic_decommafy
    assert_equal(
      "The Beatles",
      "Beatles, The".decommafy
    )
  end

  def test_basic_debracketize
    assert_equal(
      "My shoes",
      "  My (big) shoes".debracketize
    )
  end

  def test_basic_plainify
    assert_equal(
      "3 sheets Theyre to the wind",
      "3 sheets! & They're to the wind!".plainify
    )
  end

  def test_basic_dasherize
    assert_equal(
      "one-two-three-four-five-six",
      "one two/three~~four_five six ".dashify
    )
  end

  def test_basic_normalize
    assert_equal(
      "the-shoes",
      "ShÖ%^s (crap), The".normalize
    )
  end

  def test_replacement_change
    test_basic_asciify
    test_basic_flattenize
    Louisville::StringExtensions.pre_ascii_replacements = {"ó" => "bonjour"}
    assert_equal({"ó" => "bonjour"}, Louisville::StringExtensions.pre_ascii_replacements)
    assert_equal "bonjour-a-A-o-O-u-U", "ó-ä-Ä-ö-Ö-ü-Ü".asciify

    #U+02A9 LATIN SMALL LETTER FENG DIGRAPH => "\312\251"
    Louisville::StringExtensions.pre_ascii_replacements["\312\251"] = "fn"
    assert_equal "bonjour-a-A-o-O-u-U-fn", "ó-ä-Ä-ö-Ö-ü-Ü-\312\251".asciify
    # change back for the next tests
    Louisville::StringExtensions.pre_ascii_replacements = nil
    test_basic_asciify
    test_basic_flattenize
  end

  def test_temporary_replacement
    assert_equal "Oxleschlo", "Öxleschloß".asciify({})
    assert_equal "o-O-u-U-a-A-?", "ö-Ö-ü-Ü-ä-Ä-ß".asciify({'ß' => '?'})
    assert_equal "IEa", "ÌË\307\237".asciify({"hello" => "goodbye"})
    assert_equal "hasenscharten", "Öxleschloß".flattenize({'Öxle' => 'Hasen',
                                                          'schlo' => 'Scharte',
                                                          'ß' => 'n'})
    assert_equal "calll 91l1", ",ċ.-Ąl{l +9}-´`1#\{1".flattenize({'{' => 'l'})
    # make sure it works afterwards like before
    test_basic_asciify
    test_basic_flattenize
  end

  def test_general_workings
    assert_nothing_raised do
      assert_equal("", "".asciify)
      assert_equal("", "".flattenize)
    end
    assert_raise RuntimeError do
      Louisville::StringExtensions.pre_ascii_replacements = Time.now
    end
    Louisville::StringExtensions.pre_ascii_replacements = nil
    assert_instance_of Hash, Louisville::StringExtensions.pre_ascii_replacements
  end

  def test_deabbreviate
    [ 'Saint-Tropez',
      'St. tropez',
      'st tropez',
      'St-Tropez',
      'Skt. Tropez',
      'Skt-Tropez',
      'Sankt-Tropez',
      'Sankt Tropez',
      'sanKt-troPéz',
      'snt-tropez',
      'st tropez'
    ].each do |source|
      assert_equal("sankt-tropez", source.normalize, "'#{source}' was not converted !")
    end
  end
end
