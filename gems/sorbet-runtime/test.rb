def foo
  p "foo"
  p caller_locations(2,1)
end

def bar
  foo
end

bar
