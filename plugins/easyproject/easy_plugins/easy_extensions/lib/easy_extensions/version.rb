module EasyExtensions
  module VERSION
    MAJOR = 2011
    MINOR = 0
    TINY  = 1
    REVISION = 100
    BRANCH = nil

    ARRAY = [MAJOR, MINOR, TINY, BRANCH, REVISION].compact
    STRING = ARRAY.join('.')

    def self.to_a; ARRAY; end;
    def self.to_s; STRING; end;
  end
end
