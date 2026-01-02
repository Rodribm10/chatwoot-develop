module Captain
  module Tools
    module Parsers
      class StatusSuitesParser
        def self.parse(response_body)
          # Assuming response_body is already a Hash or needs parsing
          data = response_body.is_a?(String) ? JSON.parse(response_body) : response_body rescue {}
          
          # Example normalization logic based on prompt
          {
            tool_key: 'status_suites',
            free: normalize_items(data['free'] || []),
            occupied: normalize_items(data['occupied'] || []),
            cleaning: normalize_items(data['cleaning'] || [])
          }
        end

        def self.normalize_items(items)
          items.map do |item|
            {
              suite: item['suite'] || item['id'],
              category: item['category'] || item['categoria'] || 'Standard'
            }
          end
        end
      end
    end
  end
end
