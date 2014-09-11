module Spree::Chimpy
  module Interface
    class List
      delegate :log, to: Spree::Chimpy

      def initialize(list_name, segment_name, double_opt_in, list_id)
        @api           = Spree::Chimpy.api
        @list_id       = list_id
        @segment_name  = segment_name
        @double_opt_in = double_opt_in
        @list_name     = list_name
      end

      def api_call
        @api.lists
      end

      def subscribe(email, merge_vars = {}, options = {})
        log "Subscribing #{email} to #{@list_name}"

        api_call.subscribe(list_id, { email: email }, merge_vars, 'html', @double_opt_in, true)

        segment([email]) if options[:customer]
      end

      def unsubscribe(email)
        log "Unsubscribing #{email} from #{@list_name}"

        begin
          api_call.unsubscribe(list_id, { email: email })
        rescue Mailchimp::EmailNotExistsError
        end
      end

      def info(email_or_id)
        log "Checking member info for #{email_or_id} from #{@list_name}"

        #maximum of 50 emails allowed to be passed in
        response = api_call.member_info(list_id, [{email: email_or_id}])
        record = response['data'].first.symbolize_keys if response['data'] != []

        record.nil? ? response : record
      end

      def merge_vars
        log "Finding merge vars for #{@list_name}"

        api_call.merge_vars([list_id])['data'].first['merge_vars'].map {|record| record['tag']}
      end

      def add_merge_var(tag, description)
        log "Adding merge var #{tag} to #{@list_name}"

        api_call.merge_var_add(list_id, tag, description)
      end

      def find_list_id(name)
        @api.lists.list["data"].detect { |r| r["name"] == name }["id"]
      end

      def list_id
        @list_id ||= find_list_id(@list_name)
      end

      def segment(emails = [])
        log "Adding #{emails} to segment #{@segment_name}"

        api_call.static_segment_members_add(list_id, segment_id.to_i, emails)
      end

      def create_segment
        log "Creating segment #{@segment_name}"

        @segment_id = api_call.static_segment_add(list_id, @segment_name)
      end

      def find_segment_id
        segments = api_call.static_segments(list_id)
        segment  = segments.detect {|segment| segment['name'].downcase == @segment_name.downcase }

        segment['id'] if segment
      end

      def segment_id
        @segment_id ||= find_segment_id
      end
    end
  end
end
