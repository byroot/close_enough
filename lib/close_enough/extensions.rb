class Module
  def const_missing(name)

    if const = CloseEnough.nearest(constants, name)
      return const_get(const)
    end

    namespaces = self.name.split('::')
    namespaces.pop

    until namespaces.empty?
      namespace = const_get(namespaces.join('::'))
      if const = CloseEnough.nearest(namespace.constants, name)
        return namespace.const_get(const)
      end
    end

    if const = CloseEnough.nearest(Object.constants, name)
      return Object.const_get(const)
    end

    raise NameError.new("uninitialized constant #{name}")
  end
end

module CloseEnough

  def self.nearest(choices, name)
    dl = DamerauLevenshtein
    ms = choices.map(&:to_s).reject {|m| m =~ /to_.+/}
    return false if ms.empty?
    selected = ms.min_by {|possible| dl.distance(name.to_s, possible)}

    unless dl.distance(name.to_s, selected) < 3
      return false
    else
      warn "[CloseEnough] #{name.to_s} not found, using #{selected.to_s} instead"
      return selected
    end
  end

  module Extensions
    module ClassMethods

    end

    module InstanceMethods
      private

      def method_missing(name, *args, &block)
        meth = CloseEnough.nearest(methods, name)
        meth ? send(meth, *args, &block) : super
      end

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end

end
