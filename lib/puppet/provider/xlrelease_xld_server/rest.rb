require_relative '../xlr_rest_provider.rb'

Puppet::Type.type(:xlrelease_xld_server).provide :rest, :parent => Puppet::Provider::XLReleaseRestProvider do

  has_feature :restclient

  def create
    ci_json = to_j(resource[:id],resource[:type],resource[:properties])
    rest_post "deployit/servers", ci_json

  end

  def destroy
    rest_delete "deployit/servers/#{resource[:id]}"
  end

  def exists?
    resource_exists?(resource[:id])
  end

  def properties
    ci_json = rest_get "repository/tree/#{resource[:id]}"
    ci_hash = to_hash(ci_json)

    # Add unmanaged k/v pairs that XL Deploy returns to our properties.
    # Otherwise these will be reset when updating any other property.
    ci_hash.each do |k, v|
      resource[:properties][k] = v unless resource[:properties].include? k

      # Temporarily replace password properties as well, until we can
      # encode passwords ourselves
      resource[:properties][k] = v if (k == 'password' or k == 'passphrase') and v.start_with?('{b64}')
    end
    ci_hash
  end

  def properties=(value)
    ci_json = to_j(resource[:id],resource[:type],resource[:properties])
    rest_put "deployit/servers/#{resource[:id]}", ci_json
  end

  def resource_exists?(id)
    # check if a certain resource exists in the xl release repository
    ci_exists?(id)
  end
end
