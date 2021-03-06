require 'test/unit'
require 'rbvmomi'
VIM = RbVmomi::VIM unless Object.const_defined? :VIM

class MiscTest < Test::Unit::TestCase
  def test_overridden_const
    assert(VIM::SecurityError < RbVmomi::BasicTypes::Base)
    assert_equal 'SecurityError', VIM::SecurityError.wsdl_name
  end

  # XXX
  def disabled_test_dynamically_overridden_const
    assert !VIM.const_defined?(:ClusterAttemptedVmInfo)
    Object.const_set :ClusterAttemptedVmInfo, :override
    assert VIM::ClusterAttemptedVmInfo.is_a?(Class)
    assert(VIM::ClusterAttemptedVmInfo < RbVmomi::BasicTypes::Base)
    assert_equal 'ClusterAttemptedVmInfo', VIM::ClusterAttemptedVmInfo.wsdl_name
  end
end

