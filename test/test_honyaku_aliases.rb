require 'minitest/autorun'
require 'honyaku'
require 'tempfile'
require 'yaml'
require 'json'
require 'pry'
require 'pry-nav'

class HonyakuAliasTest < Minitest::Test

  # Verifies YAML file containing aliases does not throw an error
  def test_translates_yaml_with_aliases
    yaml_content = <<~YAML
      common: &common
        greeting: Hello
        farewell: Goodbye
      
      english:
        <<: *common
        extra: Additional text
      
      spanish:
        <<: *common
        extra: Texto adicional
    YAML

    temp_file = Tempfile.new(['test', '.yml'])
    temp_file.write(yaml_content)
    temp_file.close

    translator = Honyaku::Translator.new(
      api_key: 'fake_key',
      model: 'gpt-4o-mini'
    )

    translator.fix_yaml(temp_file.path)
  ensure
    temp_file.unlink
  end
end
