module ApiAuth

  module RequestDrivers # :nodoc:

    class ActionControllerRequest # :nodoc:

      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        @headers = fetch_headers
        true
      end

      def set_auth_header(header)
        @request.env["Authorization"] = header
        @headers = fetch_headers
        @request
      end

      def calculated_md5
        if @request.body
          body = @request.raw_post
          if body.nil?
            body = @request.body.string if @request.body.respond_to? :string
            body = @request.body.read if @request.body.respond_to? :read
            unless body
              if (defined?(PhusionPassenger::Utils::TeeInput) and
                  @request.body.is_a?(PhusionPassenger::Utils::TeeInput) and
                  @request.body.instance_variable_get(:@tmp).respond_to?(:string)
              )
                body =  @request.body.instance_variable_get(:@tmp).string.force_encoding("utf-8")
              elsif (defined?(PhusionPassenger::Utils::TeeInput) and
                  @request.body.is_a?(PhusionPassenger::Utils::TeeInput) and
                  @request.body.instance_variable_get(:@tmp).is_a? PhusionPassenger::Utils::TmpIO
              )
                body =  @request.body.instance_variable_get(:@tmp).read.force_encoding("utf-8")
              else
                body = ''
              end
            end
          end
        else
          body = ''
        end
        Digest::MD5.base64digest(body)
      end

      def populate_content_md5
        if @request.put? || @request.post?
          @request.env["Content-MD5"] = calculated_md5
        end
      end

      def md5_mismatch?
        if @request.put? || @request.post?
          calculated_md5 != content_md5
        else
          false
        end
      end

      def fetch_headers
        capitalize_keys @request.env
      end

      def content_type
        value = find_header(%w(CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE))
        value.nil? ? "" : value
      end

      def content_md5
        value = find_header(%w(CONTENT-MD5 CONTENT_MD5 HTTP_CONTENT_MD5))
        value.nil? ? "" : value
      end

      def request_uri
        @request.request_uri
      end

      def set_date
        @request.env['DATE'] = Time.now.utc.httpdate
      end

      def timestamp
        value = find_header(%w(DATE HTTP_DATE))
        value.nil? ? "" : value
      end

      def authorization_header
        find_header %w(Authorization AUTHORIZATION HTTP_AUTHORIZATION)
      end

    private

      def find_header(keys)
        keys.map {|key| @headers[key] }.compact.first
      end

    end

  end

end
