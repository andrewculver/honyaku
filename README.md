# Honyaku (翻訳)

A Ruby gem for quickly, reliably, and accurately translating your Rails application using OpenAI.

Honyaku was built using [Cursor Composer](https://docs.cursor.com/composer) with [claude-3.5-sonnet](https://www.anthropic.com/news/claude-35-sonnet), prompted by [Andrew Culver](https://x.com/andrewculver) at [ClickFunnels](https://www.clickfunnels.com).

## Features

- Uses GPT-4 for high-quality translations (GPT-3.5-turbo optional for faster processing)
- Preserves YAML structure, references, and interpolation variables
- Supports translation rules via `.honyakurules` files
- Handles large files through automatic chunking
- Automatically fixes YAML formatting issues caused by the GPT
- Supports backup creation before modifications

# Example Output

```
$ honyaku translate ja --path config/locales/en/affiliates             
📋 Found 2 translation rule file(s):
   📝 /Users/andrewculver/Sites/admin/.honyakurules
   🌐 /Users/andrewculver/Sites/admin/.honyakurules.ja
🌏 Translating from en to ja...
📂 Processing files in config/locales/en/affiliates...
📝 Processing config/locales/en/affiliates/active_referrals_report.en.yml...
📦 Splitting file into 3 chunks...
🔄 Translating chunk 1 of 3...
🔄 Translating chunk 2 of 3...
🔄 Translating chunk 3 of 3...
✨ Created config/locales/ja/affiliates/active_referrals_report.ja.yml
🔧 Checking for YAML issues...
✅ No more YAML errors found
📝 Processing config/locales/en/affiliates/add_tag_actions.en.yml...
✨ Created config/locales/ja/affiliates/add_tag_actions.ja.yml
🔧 Checking for YAML issues...
🔧 Found YAML error on line 5: (<unknown>): found character that cannot start any token while scanning for the next token at line 5 column 13
   zero: %{count}アフィリエイトにコミッションプランアクションを追加する
🔧 Found YAML error on line 6: (<unknown>): found character that cannot start any token while scanning for the next token at line 6 column 12
   one: %{count}アフィリエイトにコミッションプランアクションを追加する
🔧 Found YAML error on line 7: (<unknown>): found character that cannot start any token while scanning for the next token at line 7 column 14
   other: %{count}アフィリエイトにコミッションプランアクションを追加する
✅ No more YAML errors found
✨ Fixed YAML formatting issues
⏭️  Skipping config/locales/en/affiliates/applied_tags.en.yml - translation is up to date
⏭️  Skipping config/locales/en/affiliates/approve_actions.en.yml - translation is up to date
...
```

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
export OPENAI_API_KEY=your-api-key
```

Or if you've already got that configured for another purpose and you want to specify a different key for Honyaku, you can set this and we'll use it instead:
```bash
export HONYAKU_OPENAI_API_KEY=your-api-key
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
