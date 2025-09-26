--!strict

local describe = require('@root/lib/describe')

return describe("testing framework") (
  function (it)
    it("should provide ability for positive testing", "positive") (
      function (check)
        assert(1 == 1, 'should not fail')
      end
    )

    it("should provide ability for negative testing", "negative") (
      function (check)
        assert(1 == 2, 'should fail')
      end
    )

    it("should provide ability to check assertions") (
      function (check)
        check.eq('1', '1', 'should be equal')
        check.neq(1, '1', 'should not be equal')
        check.required('a', 'should be defined')
        check.assert(1 == 1, 'should be correct')
      end
    )
  end
)
