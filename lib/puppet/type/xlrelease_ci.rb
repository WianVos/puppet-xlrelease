require 'pathname'

Puppet::Type.newtype(:xlrelease_ci) do
  @doc = 'Manage a XL Deploy Configuration Item'

  feature :restclient, 'Use REST to update XL Deploy repository'

  ensurable do
    defaultvalues
    defaultto :present
  end

  autorequire(:class) do
    'xlrelease'
  end

  autorequire(:xlrelease_ci) do

    # Function to recursively iterate over hashes and arrays
    # to find all values for a given key
    def recursive_values(obj, key)
      values = []

      if obj.is_a? Hash
        obj.each do |k, v|
          if k == key
            values = values << v
          else
            values = values + recursive_values(v, key)
          end
        end
      elsif obj.is_a? Array
        obj.each do |a|
          values = values + recursive_values(a, key)
        end
      end
      values
    end

    # Add parent as required
    required = [Pathname.new(self[:id]).dirname.to_s]

    # Add all @ref attributes as required
    required = required + recursive_values(self[:properties], '@ref')
    required
  end

  newparam(:id, :namevar => true) do
    desc 'The ID/path of the CI'

    validate do |value|
     raise Puppet::Error, "Invalid id: #{value}" unless value =~ /^(Applications|Environments|Infrastructure|Configuration)\/.+$/
    end
  end

  newparam(:type) do
    desc 'Type of the CI'
  end

  newproperty(:properties) do
    desc 'Properties of the CI'

    defaultto({})

    validate do |value|
      raise Puppet::Error, "Invalid properties: #{value}, expected a hash" unless value.is_a? Hash
    end

    # We need to overwrite insync? to verify only the properties that we
    # manage, because XL Deploy also returns all properties of a CI, which
    # could include properties that are not set by puppet
    def insync?(is)
      compare(is, @should.first) and compare(@should.first, is)
    end

    def compare(is, should)
      return false unless is.class == should.class

      if should.is_a? Hash
        should.each do |k, v|
          return false unless is.has_key? k and compare(is[k], should[k])
        end
      elsif should.is_a? Array
        should.each do |a|
          return false unless is.include? a
        end
      else
        return false unless is == should
      end

      true
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end


  newparam(:rest_url, :required_features => ['restclient']) do
    desc 'The rest url for making changes to XL Deploy'
  end

end
