require "openai"
require "yaml"

module Honyaku
  class Translator
    LINES_PER_CHUNK = 250

    def initialize(api_key: nil, model: "gpt-4", translation_rules: [])
      api_key ||= ENV["HONYAKU_OPENAI_API_KEY"] || ENV["OPENAI_API_KEY"]
      @client = OpenAI::Client.new(access_token: api_key)
      @model = model
      @translation_rules = translation_rules
    end

    def translate_hash(file_path, from_locale, to_locale)
      yaml_content = File.read(file_path)
      lines = yaml_content.lines
      
      # If the file is small enough, translate it all at once
      if lines.size <= LINES_PER_CHUNK
        result = translate_chunk(yaml_content, from_locale, to_locale)
        raise "Translation failed" unless result
        return result
      end
      
      # Otherwise, split into chunks and translate each
      chunks = split_into_chunks(lines)
      puts "📦 Splitting file into #{chunks.size} chunks..."
      
      translated_chunks = []
      
      chunks.each_with_index do |chunk, i|
        puts "🔄 Translating chunk #{i + 1} of #{chunks.size}..."
        result = translate_chunk(chunk, from_locale, to_locale)
        
        # If any chunk fails, abort the whole translation
        raise "Translation failed for chunk #{i + 1}" unless result
        translated_chunks << result
      end
      
      translated_chunks.join("\n")
    end

    def fix_yaml(file_path)
      content = File.read(file_path)
      fixed_any = false
      
      loop do
        begin
          YAML.safe_load(content, aliases: true)
          puts "✅ No more YAML errors found"
          return content
        rescue Psych::SyntaxError => e
          # If OpenAI returned invalid YAML structure, signal that we need to retranslate
          if e.message.include?("did not find expected key while parsing a block mapping")
            raise "Translation resulted in invalid YAML structure - needs retranslation"
          end

          lines = content.lines
          line_number = e.line - 1  # YAML errors are 1-based
          problematic_line = lines[line_number]
          
          puts "🔧 Found YAML error on line #{e.line}: #{e.message}"
          puts "   #{problematic_line.strip}"
          
          # Only try to fix common syntax issues
          if e.message.include?("cannot start any token")
            fixed = false

            # Fix case 1: Values starting with %{var} need quotes
            if problematic_line.include?("%{") && problematic_line =~ /^(\s*[^:]+:\s*)(?:(&\w+)\s+)?(%\{.+)$/
              prefix, reference, value = $1, $2, $3
              fixed_line = if reference
                "#{prefix}#{reference} \"#{value}\""
              else
                "#{prefix}\"#{value}\""
              end
              fixed = true
            # Fix case 2: Fix incorrect spacing in %{ var }
            elsif problematic_line.include?("% {")
              fixed_line = problematic_line.gsub("% {", "%{")
              fixed = true
            end

            if fixed
              # Update the line
              lines[line_number] = "#{fixed_line}\n"
              content = lines.join
              fixed_any = true
              next # Continue to the next iteration to find more errors
            end
          end
          
          # If we get here, we couldn't fix this error
          if fixed_any
            puts "❌ Unable to fix remaining YAML errors"
          else
            puts "❌ Unable to fix any YAML errors"
          end
          return content
        end
      end
    end

    private

    def split_into_chunks(lines)
      chunks = []
      current_chunk = []
      current_indent = 0
      line_count = 0

      lines.each do |line|
        # Calculate the indentation level of the current line
        indent = line[/\A */].length
        
        # Start a new chunk if we hit the line limit and we're at the root level
        if line_count >= LINES_PER_CHUNK && indent <= current_indent
          chunks << current_chunk.join
          current_chunk = []
          line_count = 0
        end
        
        current_chunk << line
        line_count += 1
        current_indent = indent
      end
      
      # Add the last chunk if there's anything left
      chunks << current_chunk.join if current_chunk.any?
      
      chunks
    end

    def translate_chunk(content, from_locale, to_locale)
      max_retries = 3
      attempts = 0
      
      begin
        attempts += 1
        response = @client.chat(
          parameters: {
            model: @model,
            messages: [
              {
                role: "system",
                content: build_system_prompt
              },
              {
                role: "user",
                content: "Translate this YAML content from #{from_locale} to #{to_locale}. Keep all structure and special characters exactly the same:\n\n#{content}"
              }
            ],
            temperature: 0.7
          }
        )

        # Clean up any markdown code block markers
        response_text = response.dig("choices", 0, "message", "content")
        response_text.gsub(/^```ya?ml\s*\n/, '').gsub(/\n```\s*$/, '')
      rescue => e
        # Don't retry if it's a billing/credits issue
        if e.message.include?("insufficient_quota") || e.message.include?("billing")
          puts "❌ OpenAI API error: #{e.message}"
          raise e
        end

        if attempts < max_retries
          puts "⚠️  OpenAI API error, retrying (attempt #{attempts}/#{max_retries}): #{e.message}"
          sleep(attempts) # Exponential backoff
          retry
        else
          puts "❌ OpenAI API error after #{max_retries} attempts: #{e.message}"
          raise e
        end
      end
    end

    def fix_line(line, error)
      response = @client.chat(
        parameters: {
          model: @model,
          messages: [
            {
              role: "system",
              content: "You are a YAML expert. Fix the provided line to be valid YAML. Common issues include:
              - Values starting with % need to be quoted
              - Proper escaping of special characters
              Return only the fixed line, no explanation needed."
            },
            {
              role: "user",
              content: "Fix this YAML line that generated this error: #{error}\n\nLine: #{line}"
            }
          ],
          temperature: 0.3
        }
      )

      response.dig("choices", 0, "message", "content").strip
    rescue => e
      puts "⚠️  Error getting fix suggestion: #{e.message}"
      line
    end

    def build_system_prompt
      base_prompt = <<~PROMPT
        You are a professional translator. You will be translating YAML files.
        
        CRITICAL REQUIREMENTS:
        1. Only translate text values after the colon (:)
        2. Never modify, translate, or remove:
           - YAML keys (text before the colon)
           - Interpolation variables (like %{name})
           - YAML references and anchors
           - Comments
           - Empty lines
        3. Keep all special characters exactly as they appear
        4. Maintain the exact same line count
        5. Never add or remove lines
        6. Never change the structure of the file
      PROMPT

      if @translation_rules.any?
        general_rules, locale_rules = @translation_rules.partition { |r| !r[:locale_specific] }
        
        if general_rules.any?
          base_prompt += "\n\nGeneral translation rules:\n" + 
                        general_rules.map { |rule| rule[:content] }.join("\n\n")
        end
        
        if locale_rules.any?
          base_prompt += "\n\nTarget language specific rules:\n" + 
                        locale_rules.map { |rule| rule[:content] }.join("\n\n")
        end
      end

      base_prompt
    end
  end
end 
