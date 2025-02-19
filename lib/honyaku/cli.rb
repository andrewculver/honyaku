require "thor"
require "yaml"
require "honyaku/translator"

module Honyaku
  class CLI < Thor
    desc "translate LOCALE", "Translate your application into the specified locale"
    long_desc <<-LONGDESC
      Translates YAML files from one locale to another using OpenAI.

      Examples:
        # Translate a specific file from English to Japanese
        $ honyaku translate ja --path config/locales/en.yml

        # Translate all files in a directory from English to Spanish
        $ honyaku translate es --path config/locales

        # Translate using GPT-4 for higher accuracy
        $ honyaku translate de --model gpt-4 --path config/locales/en.yml
    LONGDESC
    method_option :from, aliases: "-f", desc: "Source locale (defaults to en)"
    method_option :path, aliases: "-p", desc: "Path to YAML file or directory (defaults to config/locales)"
    method_option :model, 
                 aliases: "-m", 
                 desc: "Specify which AI model to use (defaults to gpt-4, use gpt-3.5-turbo for faster but less accurate translations)"
    method_option :backup, aliases: "-b", type: :boolean, desc: "Create .bak files before modifying"
    method_option :force, type: :boolean, desc: "Retranslate files even if target is newer than source"
    def translate(locale)
      api_key = ENV["HONYAKU_OPENAI_API_KEY"] || ENV["OPENAI_API_KEY"]
      unless api_key
        puts "❌ Please set either HONYAKU_OPENAI_API_KEY or OPENAI_API_KEY environment variable"
        exit 1
      end

      source_locale = options[:from] || "en"
      path = options[:path] || "config/locales"
      model = options[:model] || "gpt-4"

      # Check if the source path exists
      unless File.exist?(path)
        puts "❌ Source path not found: #{path}"
        puts "   Please check that the file or directory exists"
        exit 1
      end

      # Find all .honyakurules files from root to current path
      rules = find_translation_rules(path, locale)
      if rules.any?
        puts "📋 Found #{rules.length} translation rule file(s):"
        rules.each do |rule|
          prefix = rule[:locale_specific] ? "🌐" : "📝"
          puts "   #{prefix} #{rule[:path]}"
        end
      end

      puts "🌏 Translating from #{source_locale} to #{locale}..."
      puts "📂 Processing files in #{path}..."

      translator = Translator.new(model: model, translation_rules: rules)
      
      if File.file?(path)
        process_file(path, translator, source_locale, locale)
      else
        files = Dir.glob("#{path}/**/*.yml")
        if files.empty?
          puts "❌ No YAML files found in: #{path}"
          puts "   Make sure your path contains .yml files"
          exit 1
        end
        files.each do |file|
          process_file(file, translator, source_locale, locale)
        end
      end

      puts "✅ Translation complete!"
    end

    desc "fix PATH", "Fix YAML formatting issues in translated files"
    long_desc <<-LONGDESC
      Fixes common YAML formatting issues in translated files, such as:
      - Adding quotes around values that start with %{variable}
      - Fixing spacing in interpolation variables
      - Preserving YAML references and anchors
      - Maintaining proper indentation

      Examples:
        # Fix a specific file
        $ honyaku fix config/locales/ja/courses.ja.yml

        # Fix all YAML files in a directory
        $ honyaku fix config/locales/ja
    LONGDESC
    method_option :model, aliases: "-m", desc: "Specify which AI model to use (defaults to gpt-3.5-turbo)"
    method_option :backup, aliases: "-b", type: :boolean, desc: "Create .bak files before modifying"
    def fix(path)
      api_key = ENV["HONYAKU_OPENAI_API_KEY"] || ENV["OPENAI_API_KEY"]
      unless api_key
        puts "❌ Please set either HONYAKU_OPENAI_API_KEY or OPENAI_API_KEY environment variable"
        exit 1
      end

      model = options[:model] || "gpt-3.5-turbo"
      
      puts "🔧 Fixing YAML formatting issues..."
      puts "📂 Processing files in #{path}..."

      fixer = Translator.new(model: model)
      
      if File.file?(path)
        fix_file(path, fixer)
      else
        Dir.glob("#{path}/**/*.yml").each do |file|
          fix_file(file, fixer)
        end
      end

      puts "✅ Fixes complete!"
    end

    private

    def find_translation_rules(start_path, target_locale = nil)
      rules = []
      
      # Start from the directory containing the YAML file/directory
      current_path = File.expand_path(start_path)
      
      # First check the current working directory
      if File.exist?('.honyakurules')
        rules << {
          path: File.expand_path('.honyakurules'),
          content: File.read('.honyakurules').strip
        }
      end
      
      # Check for locale-specific rules in current directory
      if target_locale && File.exist?(".honyakurules.#{target_locale}")
        rules << {
          path: File.expand_path(".honyakurules.#{target_locale}"),
          content: File.read(".honyakurules.#{target_locale}").strip,
          locale_specific: true
        }
      end
      
      # Walk up the directory tree from the YAML path
      while current_path != '/' && current_path != Dir.pwd
        # Check for general rules
        rules_file = File.join(current_path, '.honyakurules')
        if File.exist?(rules_file)
          rules << {
            path: rules_file,
            content: File.read(rules_file).strip
          }
        end
        
        # Check for locale-specific rules
        if target_locale
          locale_rules_file = File.join(current_path, ".honyakurules.#{target_locale}")
          if File.exist?(locale_rules_file)
            rules << {
              path: locale_rules_file,
              content: File.read(locale_rules_file).strip,
              locale_specific: true
            }
          end
        end
        
        current_path = File.dirname(current_path)
      end
      
      # Reverse to maintain root-to-local order, but ensure locale-specific rules come after general rules
      rules.reverse.partition { |r| !r[:locale_specific] }.flatten
    end

    def process_file(file_path, translator, source_locale, target_locale)
      # Check if this is a source locale file we should translate
      source_pattern = /#{source_locale}(\/|\.yml)/
      return unless file_path =~ source_pattern

      # Generate the target filename
      target_file = file_path.gsub(source_pattern, "#{target_locale}\\1")

      # Only skip if target exists AND is newer (unless --force is used)
      if File.exist?(target_file) && !options[:force]
        source_time = get_last_modified_time(file_path)
        target_time = get_last_modified_time(target_file)

        if target_time && source_time && target_time > source_time
          puts "⏭️  Skipping #{file_path} - translation is up to date"
          return
        end
      end

      puts "📝 Processing #{file_path}..."
      
      begin
        attempts = 0
        max_attempts = 3
        
        loop do
          attempts += 1
          begin
            translated_content = translator.translate_hash(file_path, source_locale, target_locale)
          rescue => e
            puts "❌ Translation failed: #{e.message}"
            break
          end
          
          # Don't proceed if translation failed
          if !translated_content || translated_content.strip.empty?
            puts "❌ Translation failed - no content generated"
            break
          end

          # Create directory and write file only if we have valid content
          FileUtils.mkdir_p(File.dirname(target_file))
          
          # Backup if requested
          if options[:backup] && File.exist?(target_file)
            backup_path = "#{target_file}.bak"
            FileUtils.cp(target_file, backup_path)
          end
          
          # Write the translated content
          File.write(target_file, translated_content)
          puts "✨ Created #{target_file}"
          
          # Automatically fix any YAML issues
          puts "🔧 Checking for YAML issues..."
          begin
            fixed_content = translator.fix_yaml(target_file)
            if fixed_content != translated_content
              if options[:backup] && !File.exist?("#{target_file}.bak")
                FileUtils.cp(target_file, "#{target_file}.bak")
              end
              
              File.write(target_file, fixed_content)
              puts "✨ Fixed YAML formatting issues"
            end
            break # Success! Exit the loop
          rescue => e
            if e.message.include?("needs retranslation") && attempts < max_attempts
              puts "⚠️  Translation attempt #{attempts} produced invalid YAML, retrying..."
              # Clean up the file before retrying
              File.unlink(target_file) if File.exist?(target_file)
              next
            else
              # Clean up and re-raise
              File.unlink(target_file) if File.exist?(target_file)
              raise e
            end
          end
        end
      rescue => e
        puts "❌ Error processing #{file_path}: #{e.message}"
        # Ensure file is cleaned up if it was created
        File.unlink(target_file) if File.exist?(target_file)
      end
    end

    def fix_file(file_path, fixer)
      puts "🔧 Fixing #{file_path}..."
      
      begin
        # Backup if requested
        if options[:backup]
          backup_path = "#{file_path}.bak"
          FileUtils.cp(file_path, backup_path)
          puts "📑 Created backup at #{backup_path}"
        end

        fixed_content = fixer.fix_yaml(file_path)
        File.write(file_path, fixed_content)
        puts "✨ Fixed #{file_path}"
      rescue => e
        puts "❌ Error fixing #{file_path}: #{e.message}"
      end
    end

    def get_last_modified_time(file_path)
      times = []
      
      # Get git timestamp if available
      if git_time = get_git_modified_time(file_path)
        times << git_time
      end
      
      # Get filesystem timestamp
      if File.exist?(file_path)
        times << File.mtime(file_path)
      end
      
      # Return the newest timestamp (or nil if no timestamps found)
      times.max
    end

    def get_git_modified_time(file_path)
      return nil unless system("git rev-parse --is-inside-work-tree > /dev/null 2>&1")
      
      time_str = `git log -1 --format=%cd --date=iso -- #{file_path} 2>/dev/null`.strip
      return nil if time_str.empty?
      
      Time.parse(time_str)
    rescue
      nil
    end

    desc "status", "Show translation status for all locales"
    def status
      puts "📊 Translation Status:"
      # Status reporting logic will go here
    end

    desc "version", "Show Honyaku version"
    def version
      puts "Honyaku v#{Honyaku::VERSION}"
    end

    def self.exit_on_failure?
      true
    end
  end
end 