use("ispec")
use("text_scanner")

describe(TextScanner,
  it("should have the correct kind",
    TextScanner should have kind("TextScanner")
  )

  describe("mimic",
    it("should be possible to mimic a new TextScanner with a given piece of text",
      t = TextScanner mimic("text")
      t should have kind("TextScanner")
    )
  )

  describe("text",
    it("should be possible to retrieve the original piece of text to be scanned",
      t = TextScanner mimic("original text")
      t text should == "original text"
    )
  )

  describe("rest",
    it("should return all of the text before any scanning has taken place",
      t = TextScanner mimic("original text")
      t rest should == "original text"
    )

    it("should return the remainder of the text after an initial scan",
      t = TextScanner mimic("original text")
      t scan(#/original/)
      t rest should == " text"
    )
  )

  describe("scan",
    it("should return the matching text if the provided regexp matches text from the pointer position",
      t = TextScanner mimic("original matchable text")
      t scan(#/original/) should == "original"
    )

    it("should not match if the match doesn't start at the pointer position",
      t = TextScanner mimic("original matchable text")
      t scan(#/matchable/) should == nil
    )

    it("should advance the pointer position to the position after the first match",
      t = TextScanner mimic("original matchable text")
      t position should == 0
      t scan(#/original/)
      t position should == 8
    )

    it("should advance the pointer position multiple times with multiple matches",
      t = TextScanner mimic("my umbrella is asymetric")
      t position should == 0
      t scan(#/my/) should == "my"
      t position should == 2
      t scan(#/umbrella/) should == nil
      t position should == 2
      t scan(#/ /) should == " "
      t position should == 3
      t scan(#/umb.*/) should == "umbrella is asymetric"
      t position should == "my umbrella is asymetric" length
    )
  )

  describe("search",
    it("should find a match at the end of the text",
      t = TextScanner mimic("original matchable text")
      t search(#/text/) should == "original matchable text"
    )

    it("should find a match in the middle of the text h",
      t = TextScanner mimic("original matchable text")
      t search(#/matchable/) should == "original matchable"
    )

    it("should find a match in the middle of the text and return all the text from the pointer position to the match",
      t = TextScanner mimic("original matchable text")
      t scan(#/original/)
      t position should == 8
      t search(#/text/) should == " matchable text"
      t position should == "original matchable text" length
    )

    it("should advance the pointer position",
      t = TextScanner mimic("original matchable text")
      t search(#/matchable/)
      t position should == 18
    )
  )

  describe("position",
    it("should return 0 before any scanning has been done",
      t = TextScanner mimic("text")
      t position should == 0
    )
  )
)