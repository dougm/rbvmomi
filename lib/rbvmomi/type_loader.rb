# Copyright (c) 2010 VMware, Inc.  All Rights Reserved.
require 'cdb'
require 'set'

module RbVmomi

class TypeLoader
  attr_reader :typenames

  def initialize target, fn
    @target = target
    @fn = fn
  end

  def init
    @db = CDB.new @fn
    @vmodl = Hash.new { |h,k| if e = @db[k] then h[k] = Marshal.load(e) end }
    @typenames = Set.new(Marshal.load(@db['_typenames']) + BasicTypes::BUILTIN)
    @target.constants.select { |x| has_type? x.to_s }.each { |x| load_type x.to_s }
    BasicTypes::BUILTIN.each do |x|
      @target.const_set x, BasicTypes.const_get(x)
      load_extension x
    end
    Object.constants.map(&:to_s).select { |x| has_type? x }.each do |x|
      load_type x
    end
  end

  def has_type? name
    fail unless name.is_a? String
    @typenames.member? name
  end

  def load_type name
    fail unless name.is_a? String
    @target.const_set name, make_type(name)
    load_extension name
    nil
  end

  private

  def load_extension name
    dirs = @target.extension_dirs
    dirs.map { |x| File.join(x, "#{name}.rb") }.
         select { |x| File.exists? x }.
         each { |x| load x }
  end

  def make_type name
    name = name.to_s
    fail if BasicTypes::BUILTIN.member? name
    desc = @vmodl[name] or fail "unknown VMODL type #{name}"
    case desc['kind']
    when 'data' then make_data_type name, desc
    when 'managed' then make_managed_type name, desc
    when 'enum' then make_enum_type name, desc
    else fail desc.inspect
    end
  end

  def make_data_type name, desc
    superclass = @target.const_get desc['wsdl_base']
    Class.new(superclass).tap do |klass|
      klass.init name, desc['props']
    end
  end

  def make_managed_type name, desc
    superclass = @target.const_get desc['wsdl_base']
    Class.new(superclass).tap do |klass|
      klass.init name, desc['props'], desc['methods']
    end
  end

  def make_enum_type name, desc
    Class.new(BasicTypes::Enum).tap do |klass|
      klass.init name, desc['values']
    end
  end
end

end
