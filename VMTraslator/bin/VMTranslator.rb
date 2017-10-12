#!/usr/bin/env ruby

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'vm'

t = Vm::VMTranslator.new(ARGV[0])
t.run
