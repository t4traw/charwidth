require "charwidth/version"

module Charwidth
  autoload :String, "charwidth/string"
  autoload :Characters, "charwidth/characters"
  autoload :CLI, "charwidth/cli"

  module ClassMethods
    # Normalize Unicode fullwidth / halfwidth (zenkaku / hankaku) characters
    # options: {
    #   only: [:ascii, :white_parenthesis, :cjk_punctuation, :katakana, :space],
    #   except: [:ascii, :white_parenthesis, :cjk_punctuation, :katakana, :space]
    # }
    def normalize(string, options = {})
      normalize!(string.dup, options)
    end

    # Normalize Unicode fullwidth / halfwidth (zenkaku / hankaku) characters (destructive)
    def normalize!(string, options = {})
      unify_voiced_katakana!(string)
      normalize_charwidth!(string, options)
    end

    private
    TYPES = [
      :ascii, :white_parenthesis, :cjk_punctuation, :katakana, :hangul,
      :latin_1_punctuation_and_symbols, :mathematical_symbols, :space
    ].freeze
    def normalize_charwidth!(src, options = {})
      types = TYPES.dup

      # Check options
      unless (unexpected_options = options.keys - [:only, :except]).empty?
        raise "Unexpected normalize option(s): #{unexpected_options}"
      end

      if options[:only]
        unless (unexpected_types = options[:only] - TYPES).empty?
          raise "Unexpected normalize type(s): #{unexpected_types.inspect}"
        end
        types = types & options[:only]
      end

      if options[:expect]
        unless (unexpected_types = options[:expected] - TYPES).empty?
          raise "Unexpected normalize type(s): #{t.inspect}"
        end
        types = types - options[:expect]
      end

      before, after = "", ""
      types.each do |type|
        case type
        when :ascii
          before << Characters::FULLWIDTH_ASCII_VARIANTS
          after << Characters::ASCII_PUNCTUATION_AND_SYMBOLS
        when :white_parenthesis
          before << Characters::FULLWIDTH_BRACKETS
          after << Characters::WHITE_PARENTHESIS
        when :cjk_punctuation
          before << Characters::HALFWIDTH_CJK_PUCTUATION
          after << Characters::CJK_SYMBOLS_AND_PUNCTUATION
        when :katakana
          before << Characters::HALFWIDTH_KATAKANA_VARIANTS
          after << Characters::KATAKANA
        when :hangul
          before << Characters::HALFWIDTH_HANGUL_VARIANTS
          after << Characters::HANGUL
        when :latin_1_punctuation_and_symbols
          before << Characters::FULLWIDTH_SYMBOL_VARIANTS
          after << Characters::LATIN_1_PUNCTUATION_AND_SYMBOLS
        when :mathematical_symbols
          before << Characters::HALFWIDTH_SYMBOL_VARIANTS
          after << Characters::MATHEMATICAL_SYMBOLS
        when :space
          before << Characters::SPACE
          after << Characters::IDEOGRAPHIC_SPACE
        end
      end

      after.sub!('\\', '\\\\\\\\') # escape for tr
      src.tr!(before, after) || src
    end

    # Unify halfwidth (semi) voiced katakana to one fullwidth voiced katakana
    def unify_voiced_katakana!(src)
      halfwidth =
        Characters::HALFWIDTH_VOICED_KATAKANA +
        Characters::HALFWIDTH_SEMI_VOICED_KATAKANA
      fullwidth =
        Characters::VOICED_KATAKANA +
        Characters::SEMI_VOICED_KATAKANA
      halfwidth.zip(fullwidth).inject(src) do |str, (h, f)|
        str.gsub!(h, f) || str
      end
    end
  end

  extend ClassMethods
end
