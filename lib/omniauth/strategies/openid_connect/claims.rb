module OmniAuth
  module Strategies
    class OpenIDConnect
      module Claims
        class InvalidClaims < Error; end

        def self.prepended(base)
          base.class_exec do
            # Additional, specific claims to be requested on top of those requested via scopes.
            # For instance:
            #
            # {
            #   userinfo: {
            #     "given_name": {"essential": true},
            #     "nickname": null,
            #     "email": {"essential": true},
            #     "email_verified": {"essential": true},
            #     "picture": null,
            #     "http://example.info/claims/groups": null
            #   },
            #   id_token: {
            #     "auth_time": {"essential": true},
            #     "acr": {"values": ["phr", "phrh"] }
            #   }
            # }
            option :claims, {}
          end
        end

        def validate_access_token!(access_token)
          super

          verify_id_token_claims!(access_token)
        end

        def authorize_options
          super.merge(
            claims: claims_auth_param
          )
        end

        def claims_auth_param
          return nil unless claims?

          Hash(claims).to_json
        end

        def claims
          @claims ||= begin
            input = options.claims.is_a?(String) ? JSON.parse(options.claims) : options.claims

            Hash(input).with_indifferent_access
          end
        end

        def claims?
          claims.present? && claims.values.any?(&:present?)
        end

        ##
        # Indicates whether claims have to be verified in either id_token or userinfo the response.
        # `acr_values` claims are by definition voluntary and therefore don't need to be verified.
        def verify_claims?
          claims? && claims.keys.any? { |context| essential_claims(context).present? }
        end

        def essential_claims(context)
          Hash(claims[context])
            .select { |claim, request| Hash(request)["essential"].to_s == "true" }
        end

        ##
        # Verifies claims returned in the ID token. Claims from the userinfo endpoint are not verified for now.
        #
        def verify_id_token_claims!(access_token)
          return unless claims?

          id_token = decode_id_token(access_token.id_token)

          essential_claims(:id_token).each do |claim, request|
            fail_missing_claim!(claim) unless id_token.respond_to?(claim)

            validate_essential_claim_value!(claim, request, id_token.public_send(claim))
          end
        end

        def fail_missing_claim!(name)
          raise InvalidClaims, "Expected #{name} claim, but it was missing"
        end

        def validate_essential_claim_value!(claim, request, actual)
          requested_values = requested_values(request)
          return if requested_values.nil?

          return if requested_values.include?(actual)

          expected = requested_values.map { |v| "'#{v}'" }.join(", ")
          raise InvalidClaims, "Expected one of #{claim} values [#{expected}], got #{actual.inspect}"
        end

        def requested_values(request)
          return [request["value"]] if request.key?("value")
          return request["values"] if request.key?("values")

          nil
        end
      end
    end
  end
end
