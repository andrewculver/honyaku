# Honyaku (翻訳)

A Ruby gem for translating Rails application locale files using OpenAI's GPT models. Honyaku maintains YAML structure and interpolation variables while providing accurate translations.

Honyaku was built with [Cursor Composer](https://docs.cursor.com/composer) with [claude-3.5-sonnet](https://www.anthropic.com/news/claude-35-sonnet), prompted by [Andrew Culver](https://github.com/andrewculver) at [ClickFunnels](https://www.clickfunnels.com).

## Features

- Uses GPT-4 for high-quality translations (GPT-3.5-turbo optional for faster processing)
- Preserves YAML structure, references, and interpolation variables
- Supports translation rules via `.honyakurules` files
- Handles large files through automatic chunking
- Automatically fixes common YAML formatting issues
- Supports backup creation before modifications

## Installation

Add to your Gemfile:
```ruby
gem 'honyaku'
```

Or install directly:
```bash
gem install honyaku
```

## Configuration

Set your OpenAI API key:
```bash
export HONYAKU_OPENAI_API_KEY=your-api-key
# or
export OPENAI_API_KEY=your-api-key
```

## Usage

### Basic Translation

```bash
# Translate a file
honyaku translate ja --path config/locales/en.yml

# Translate a directory
honyaku translate es --path config/locales

# Create backups before modifying
honyaku translate ja --backup --path config/locales/en.yml

# Use GPT-3.5-turbo for faster processing
honyaku translate fr --model gpt-3.5-turbo --path config/locales/en.yml
```

### Translation Rules

Honyaku supports two types of rule files:
- `.honyakurules` - General rules for all translations
- `.honyakurules.{locale}` - Language-specific rules (e.g., `.honyakurules.ja`)

Example `.honyakurules`:
```yaml
Don't translate the term "ClickFunnels", that's our brand name.
```

Example `.honyakurules.ja`:
```yaml
When translating to Japanese, do not insert a space between particles like `%{site_name} に`... that should be `%{site_name}に`
```

Rules can be used for:
- Preserving brand names
- Enforcing locale-specific formatting
- Maintaining consistent terminology

### YAML Fixing

Fix formatting issues in translated files:
```bash
# Fix a single file
honyaku fix config/locales/ja/application.ja.yml

# Fix all files in a directory
honyaku fix config/locales/ja --backup
```

## Technical Details

### Large File Handling

Files over 250 lines are automatically split into chunks for translation. Each chunk maintains proper YAML structure to ensure accurate translations.

### Error Recovery

When invalid YAML is detected:
1. Automatic formatting fixes are attempted
2. Translation is retried if necessary
3. Original file is preserved if fixes fail

### Model Selection

- Default: GPT-4 (higher quality, slower)
- Alternative: GPT-3.5-turbo (faster, less accurate)

## Development

After checking out the repo:
1. Run `bin/setup` to install dependencies
2. Run `rake test` to run the tests
3. Run `bin/console` for an interactive prompt

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andrewculver/honyaku.

## License

Released under the MIT License. See [LICENSE](LICENSE.txt) for details.
