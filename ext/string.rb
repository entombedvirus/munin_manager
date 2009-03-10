class String
  unless String.new.respond_to?(:starts_with?)
    def starts_with?(prefix)
      prefix = prefix.to_s
      self[0, prefix.length] == prefix
    end
  end
end
