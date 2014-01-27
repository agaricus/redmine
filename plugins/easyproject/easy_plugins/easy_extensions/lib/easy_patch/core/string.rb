require 'unicode'

class String

  def self.compare(a, b, do_not_compare_as_downcase = false)
    if do_not_compare_as_downcase
      Unicode::strcmp(a, b)
    else
      Unicode::strcmp(Unicode::downcase(a), Unicode::downcase(b))
    end
  end

  if RUBY_VERSION < '1.9'
    def <=>(value)
      self.class.compare(self, value, false)
    end
  end

  def utf8_safe_split_on_char(n)
    self[n] < 0x80 || self[n] >= 0xC0
  end

  def utf8_safe_split(n)
    if RUBY_VERSION < '1.9'
      if length <= n
        [self, nil]
      else
        until self.utf8_safe_split_on_char(n)
          n = n - 1
        end
        before = self[0, n]
        after = self[n..-1]
        [before, after.empty? ? nil : after]
      end
    else
      self.force_encoding('UTF-8') if self.respond_to?(:force_encoding)
      before = self[0, n]
      after = self[n..-1]
      [before, after.blank? ? nil : after]
    end
  end

  def to_boolean
    ['true', 1, '1', 'yes', 't', 'y'].include?(self.downcase)
  end

end
