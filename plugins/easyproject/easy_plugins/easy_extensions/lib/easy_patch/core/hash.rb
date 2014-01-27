class Hash

  # Returns value at the given position (nested hashes)
  # Example:
  #    {'a'=>'a','b'=>{'c'=>{'d'=>'aaa'}}}.value_at('b', 'c')
  # => {"d"=>"aaa"}
  # you may pass arguments as array as well
  #    {'a'=>'a','b'=>{'c'=>{'d'=>'aaa'}}}.value_at(['b', 'c', 'd'])
  # => "aaa"
  def value_at(*key_path)
    ret_value = self
    not_founded = false
    key_path.flatten.each do |curr_key|
      if ret_value.is_a?(Hash) && ret_value.key?(curr_key)
        ret_value = ret_value[curr_key]
      else
        not_founded = true
        break
      end
    end
    not_founded ? nil : ret_value
  end

  #Returns value at the given position (nested hashes) that is specified as string
  #{'a'=>'a','b'=>{'c'=>{'d'=>'aaa'}}}.value_from_nested_key('b[c]')
  # => {"d"=>"aaa"}
  def value_from_nested_key(str_key)
    return nil if str_key.blank?
    value_at(str_key.gsub(/[\[\]]/,',').split(',').select{|x| !x.blank?})
  end

  def nested_keys(separator = '.')
    output = []
    nested_keys_recursive(self, separator, output)
    output
  end
    
  private

  def nested_keys_recursive(hash, separator, output=[], prefix='', last='')
    hash.each do |key, value|
      if prefix.blank?
        unless last.blank?
          prefix = last + separator + key.to_s
        else
          prefix = key.to_s
        end
      else
        prefix = prefix + separator + key.to_s
      end
      if value.is_a?(Hash)
        nested_keys_recursive(value, separator, output, prefix, prefix)
      else
        output << prefix
      end
      prefix = ''
    end
  end
  
end
