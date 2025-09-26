--!strict

type TestFunction = () -> ()

return function(name: string)
  print(name)
  print('-----------------------------')
  return function(tests: {TestFunction})
    for _, test in tests do
      test()
    end
  end
end
