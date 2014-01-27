class Array

  def self.warp(*args)
    return 'Warp drive is not available yet. Did you mean Array.wrap?'
  end

  def sort_with_nil(nil_on_start=true)
    sort{|a, b| a && b ? a <=> b : (a ? (nil_on_start ? 1 : -1) : (nil_on_start ? -1 : 1))}
  end

  def sort_by_with_nil(default, &block)
    raise ArgumentError, 'The variable \'default\' cannot be nil!' if default.nil?
    sort_by do |a|
      block_result = block.call(a)
      block_result || default
    end
  end

  def max_with_nil
    max{|a, b| a && b ? a <=> b : (a ? 1 : -1)}
  end

  def max_by_with_nil(default, &block)
    raise ArgumentError, 'The variable \'default\' cannot be nil!' if default.nil?
    max_by do |a|
      block_result = block.call(a)
      block_result || default
    end
  end

  def min_with_nil
    min{|a, b| a && b ? a <=> b : (a ? -1 : 1)}
  end

  def min_by_with_nil(default, &block)
    raise ArgumentError, 'The variable \'default\' cannot be nil!' if default.nil?
    min_by do |a|
      block_result = block.call(a)
      block_result || default
    end
  end

end
