#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'rake'
require 'test/filecreation'

######################################################################
class TestTask < Test::Unit::TestCase
  def setup
    Task.clear
  end

  def test_create
    arg = nil
    t = Task.lookup(:name).enhance { |task| arg = task; 1234 }
    assert_equal "name", t.name
    assert_equal [], t.prerequisites
    assert t.prerequisites.is_a?(FileList)
    assert t.needed?
    t.execute
    assert_equal t, arg
    assert_nil t.source
  end

  def test_invoke
    runlist = []
    t1 = Task.lookup(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    t2 = Task.lookup(:t2).enhance { |t| runlist << t.name }
    t3 = Task.lookup(:t3).enhance { |t| runlist << t.name }
    assert_equal [:t2, :t3], t1.prerequisites
    t1.invoke
    assert_equal ["t2", "t3", "t1"], runlist
  end

  def test_no_double_invoke
    runlist = []
    t1 = Task.lookup(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    t2 = Task.lookup(:t2).enhance([:t3]) { |t| runlist << t.name }
    t3 = Task.lookup(:t3).enhance { |t| runlist << t.name }
    t1.invoke
    assert_equal ["t3", "t2", "t1"], runlist
  end

  def test_find
    task :tfind
    assert_equal "tfind", Task[:tfind].name
    ex = assert_raises(RuntimeError) { Task[:leaves] }
    assert_equal "Don't know how to build task 'leaves'", ex.message
  end

  def test_defined
    assert ! Task.task_defined?(:a)
    task :a
    assert Task.task_defined?(:a)
  end

  def test_multi_invocations
    runs = []
    p = proc do |t| runs << t.name end
    task({:t1=>[:t2,:t3]}, &p)
    task({:t2=>[:t3]}, &p)
    task(:t3, &p)
    Task[:t1].invoke
    assert_equal ["t1", "t2", "t3"], runs.sort
  end

  def test_task_list
    task :t2
    task :t1 => [:t2]
    assert_equal ["t1", "t2"], Task.tasks.collect {|t| t.name}
  end

end

