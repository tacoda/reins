class Object
  # Lightweight autoloader: when an undefined constant is referenced, try to
  # require the underscore-cased filename and return the constant. If the file
  # doesn't exist, re-raise as NameError (the framework's autoloader is for
  # app-author code; stdlib lookups should fall through cleanly).
  #
  # M7 replaces this with a Zeitwerk-style scoped loader.
  def self.const_missing(name)
    @reins_const_missing_in_progress ||= {}
    raise NameError, "uninitialized constant #{name}" if @reins_const_missing_in_progress[name]

    @reins_const_missing_in_progress[name] = true
    begin
      require Reins.to_underscore(name.to_s)
      const_get(name)
    rescue LoadError
      raise NameError, "uninitialized constant #{name}"
    ensure
      @reins_const_missing_in_progress[name] = false
    end
  end
end
