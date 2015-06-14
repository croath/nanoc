module Nanoc::Int
  # @api private
  class ItemRep
    # @return [Hash<Symbol,String>]
    attr_accessor :raw_paths

    # @return [Hash<Symbol,String>]
    attr_accessor :paths

    # @return [Nanoc::Int::Item]
    attr_reader :item

    # @return [Symbol]
    attr_reader :name

    # @return [Enumerable<Nanoc::Int:SnapshotDef]
    attr_reader :snapshot_defs

    class Contents
      # @return [Hash<Symbol,Nanoc::Int::Content]
      attr_accessor :snapshot_contents

      # @return [Boolean]
      attr_accessor :compiled
      alias_method :compiled?, :compiled

      def initialize(item_rep, initial_content, snapshot_defs)
        @item_rep = item_rep
        @initial_content = initial_content
        @snapshot_defs = snapshot_defs
        @compiled = false

        reset
      end

      def binary?
        @snapshot_contents[:last].binary?
      end

      def reset
        @snapshot_contents = { last: @initial_content }
      end

      def compiled_content(params = {})
        # Make sure we're not binary
        if binary?
          raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(@item_rep)
        end

        # Get name of last pre-layout snapshot
        snapshot_name = params.fetch(:snapshot) { @snapshot_contents[:pre] ? :pre : :last }
        is_moving = [:pre, :post, :last].include?(snapshot_name)

        # Check existance of snapshot
        snapshot_def = @snapshot_defs.find { |sd| sd.name == snapshot_name }
        if !is_moving && (snapshot_def.nil? || !snapshot_def.final?)
          raise Nanoc::Int::Errors::NoSuchSnapshot.new(@item_rep, snapshot_name)
        end

        # Verify snapshot is usable
        is_still_moving =
          case snapshot_name
          when :post, :last
            true
          when :pre
            snapshot_def.nil? || !snapshot_def.final?
          end
        is_usable_snapshot = @snapshot_contents[snapshot_name] && (compiled? || !is_still_moving)
        unless is_usable_snapshot
          raise Nanoc::Int::Errors::UnmetDependency.new(@item_rep)
        end

        @snapshot_contents[snapshot_name].string
      end
    end

    # @param [Nanoc::Int::Item] item
    #
    # @param [Symbol] name
    def initialize(item, name)
      # Set primary attributes
      @item   = item
      @name   = name

      # Set default attributes
      @raw_paths  = {}
      @paths      = {}
      @snapshot_defs = []
      @contents = Contents.new(self, item.content, @snapshot_defs)
    end

    def snapshot_contents
      @contents.snapshot_contents
    end

    def snapshot_contents=(new_snapshot_contents)
      @contents.snapshot_contents = new_snapshot_contents
    end

    def compiled?
      @contents.compiled?
    end

    def compiled=(new_compiled)
      @contents.compiled = new_compiled
    end

    def binary?
      @contents.binary?
    end

    def compiled_content(params = {})
      @contents.compiled_content(params)
    end

    def snapshot?(snapshot_name)
      !@contents.snapshot_contents[snapshot_name].nil?
    end
    alias_method :has_snapshot?, :snapshot?

    def forget_progress
      @contents.reset
    end

    # Returns the item rep’s raw path. It includes the path to the output
    # directory and the full filename.
    #
    # @option params [Symbol] :snapshot (:last) The snapshot for which the
    #   path should be returned
    #
    # @return [String] The item rep’s path
    def raw_path(params = {})
      snapshot_name = params[:snapshot] || :last
      @raw_paths[snapshot_name]
    end

    # Returns the item rep’s path, as used when being linked to. It starts
    # with a slash and it is relative to the output directory. It does not
    # include the path to the output directory. It will not include the
    # filename if the filename is an index filename.
    #
    # @option params [Symbol] :snapshot (:last) The snapshot for which the
    #   path should be returned
    #
    # @return [String] The item rep’s path
    def path(params = {})
      snapshot_name = params[:snapshot] || :last
      @paths[snapshot_name]
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [:item_rep, item.identifier, name]
    end

    def inspect
      "<#{self.class} name=\"#{name}\" binary=#{self.binary?} raw_path=\"#{raw_path}\" item.identifier=\"#{item.identifier}\">"
    end
  end
end
