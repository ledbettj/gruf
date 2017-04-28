# Copyright 2017, Bigcommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
# 3. Neither the name of BigCommerce Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
require_relative 'base'
require_relative 'statsd'
require_relative 'output_metadata_timer'

module Gruf
  module Instrumentation
    ##
    # Registry of all hooks added
    #
    class Registry
      class HookDescendantError < StandardError; end

      class << self
        ##
        # Add an authentication strategy, either through a class or a block
        #
        # @param [String] name
        # @param [Gruf::Hooks::Base|NilClass] hook
        # @return [Class]
        #
        def add(name, hook = nil, &block)
          base = Gruf::Instrumentation::Base
          hook ||= Class.new(base)
          hook.class_eval(&block) if block_given?

          # all hooks require either the before, after, or around method
          raise NoMethodError unless hook.method_defined?(:call)

          raise HookDescendantError, "Hooks must descend from #{base}" unless hook.ancestors.include?(base)

          _registry[name.to_sym] = hook
        end

        ##
        # Return a strategy type registry via a hash accessor syntax
        #
        def [](name)
          _registry[name.to_sym]
        end

        ##
        # Iterate over each hook in the registry
        #
        def each
          _registry.each do |name, s|
            yield name, s
          end
        end

        ##
        # @return [Hash<Class>]
        #
        def to_h
          _registry
        end

        ##
        # @return [Boolean]
        #
        def any?
          to_h.keys.count > 0
        end

        ##
        # @return [Hash]
        #
        def clear
          @_registry = {}
        end

        private

        ##
        # @return [Hash<Class>]
        #
        def _registry
          @_registry ||= {}
        end
      end
    end
  end
end