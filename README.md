# Honyaku (翻訳) - AI-Powered Rails Translations

Tired of manual translations or unreliable translation services? Honyaku leverages OpenAI's powerful GPT models to translate your Rails application's locale files with exceptional accuracy while preserving your YAML structure perfectly.

Named after the Japanese word for "translation" (翻訳), Honyaku is designed to make the internationalization process as smooth as possible for Rails developers.

## ✨ Key Features

- 🤖 **AI-Powered Translations**: Harness OpenAI's GPT models for high-quality, context-aware translations
- 🎯 **YAML-Aware**: Maintains your file structure, references, and interpolation variables perfectly
- 📝 **Custom Rules**: Define translation rules for brand consistency and locale-specific requirements
- 🛠️ **Self-Healing**: Automatically detects and fixes common YAML formatting issues
- 📦 **Bulk Processing**: Translate entire locale directories with a single command
- 💪 **Production-Ready**: Handles large files through smart chunking and error recovery

## 🚀 Quick Start

1. Add to your Gemfile:
```ruby
gem 'honyaku'
```

2. Set your OpenAI API key:
```bash
export HONYAKU_OPENAI_API_KEY=your-api-key
```

3. Start translating:
```bash
# Translate a single file
honyaku translate ja --path config/locales/en.yml

# Translate an entire directory
honyaku translate es --path config/locales
```

## 🎮 Command Reference

### Translation

```bash
# Basic translation (defaults to translating from English)
honyaku translate ja --path config/locales/en.yml

# Specify source locale
honyaku translate fr --from es --path config/locales/es.yml

# Use GPT-4 for higher accuracy
honyaku translate de --model gpt-4 --path config/locales/en.yml

# Create backups before modifying
honyaku translate ja --backup --path config/locales/en.yml
```

### YAML Fixing

```bash
# Fix formatting issues in a single file
honyaku fix config/locales/ja/application.ja.yml

# Fix all YAML files in a directory
honyaku fix config/locales/ja --backup
```

## 📋 Translation Rules

Honyaku supports `.honyakurules` files for customizing translation behavior. These files can exist at any level of your directory structure, and rules are applied hierarchically.

Example `.honyakurules`:
```yaml
Don't translate the term "ClickFunnels", that's our brand name.
---
When translating to Japanese, do not insert a space between particles like `%{site_name} に`... that should be `%{site_name}に`
```

Rules are perfect for:
- Preserving brand names and trademarks
- Enforcing locale-specific formatting
- Maintaining consistent terminology
- Specifying translation preferences

## 🛡️ Safety Features

Honyaku includes several safety mechanisms:
- Automatic backup creation with `--backup`
- Smart chunking for large files
- Automatic retry on invalid translations
- YAML structure preservation
- Interpolation variable protection

## 🔧 Advanced Usage

### Handling Large Files

Honyaku automatically chunks large files to ensure reliable translation:

```bash
# Honyaku will automatically split files into ~250 line chunks
honyaku translate ja --path config/locales/en/massive_file.yml
```

### Error Recovery

If a translation produces invalid YAML, Honyaku will:
1. Automatically detect the issue
2. Attempt to fix common formatting problems
3. Retry the translation if necessary
4. Preserve your original file if unable to fix

## 🤝 Contributing

We welcome contributions! Whether it's bug reports, feature requests, or code:

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## 📜 License

Released under the MIT License. See [LICENSE](LICENSE.txt) for details.

## 💎 About

Honyaku is maintained by [Andrew Culver](https://github.com/andrewculver). It was created to solve the real-world challenge of maintaining high-quality translations in Rails applications.

---

<p align="center">
Made with ❤️ for the Rails community
</p>
