
ISpec do(
  Formatter = Origin mimic

  Formatter do(
    TextFormatter = ISpec Formatter mimic do(
      noAnsi = (System windows?) || (System feature?(:java) && (java:lang:System getProperty("ispec.ansi") asText == "false"))

      start = method(exampleCount, @pendingExamples = [])

      examplePending = method(example, message,
        pendingExamples << [example fullDescription, message]
      )

      dumpFailure = method(counter, failure,
        println("")
        println("#{counter})")
        if(failure mimics?(ISpec Reporter Failure),
          println(red("#{failure header}"))
          if(failure condition cell?(:currentValues),
            println(red(" Failing values:"))
            failure condition currentValues each(v,
              println(red("   #{v[0]}: #{v[1] inspect}"))))
          println(red("#{failure condition report}"))
          println("  #{failure condition example stackTraceAsText(failure condition)}"),

          println(magenta("#{failure header}"))
          println("\n  #{failure result exhaustionStackTrace}")
        )

        if(failure cell?(:propertyResult),
          println("\n  #{formatPropertyResult(failure propertyResult)}")
        )
      )

      dumpSummary = method(duration, exampleCount, failureCount, pendingCount, propertyCount, exhaustedCount, propertyInstanceCount, discardedCount,
        println("")
        println("Finished in #{duration} seconds")
        println("")

        summary = "#{exampleCount} example#{if(exampleCount == 1, "", "s")}, "
        summary += "#{failureCount} failure#{if(failureCount == 1, "", "s")}"

        if(pendingCount > 0,
          summary += ", #{pendingCount} pending")

        if(propertyCount > 0,
          summary += " - #{propertyCount} propert#{if(propertyCount == 1, "y", "ies")}"
          summary += ", #{propertyInstanceCount} succeeded"
          if(exhaustedCount > 0,
            summary += ", #{exhaustedCount} exhausted")
          if(discardedCount > 0,
            summary += ", #{discardedCount} discarded")
        )

        if(failureCount == 0,
          if(pendingCount > 0,
            println(yellow(summary)),
            println(green(summary))),
          println(red(summary))))

      dumpPending = method(
        unless(pendingExamples empty?,
          println("")
          println("Pending:")
          pendingExamples each(pe,
            println("#{pe[0]} (#{pe[1]})"))))

      formatPropertyResult = method(result,
        classifiers = if(result classifier empty?,
          "",
          " -%:[ %s: %s%]" % result classifier)
        
        "#{result succeeded} succeeded, #{result discarded} discarded#{classifiers}"
      )

      colour = method(
        "outputs text with colour if possible",
        text, colour_code,

        if(noAnsi,
          text,
          "#{colour_code}#{text}\e[0m"))

      green   = method(text, colour(text, "\e[32m"))
      red     = method(text, colour(text, "\e[31m"))
      magenta = method(text, colour(text, "\e[35m"))
      yellow  = method(text, colour(text, "\e[33m"))
      blue    = method(text, colour(text, "\e[34m"))
    )

    SpecDocFormatter = ISpec Formatter TextFormatter mimic do(
      addExampleGroup = method(exampleGroup,
        super(exampleGroup)
        println("")
        println(exampleGroup fullName))

      exampleFailed = method(example, counter, failure,
        println(red("- #{example description} (FAILED - #{counter})"))
      )

      propertyExampleFailed = method(example, counter, failure, 
        println(red("- #{example description} (FAILED - #{counter})    [#{formatPropertyResult(failure propertyResult)}]"))
      )

      propertyExampleExhausted = method(example, counter, result,
        println(magenta("- #{example description} (EXHAUSTED - #{counter})    [#{formatPropertyResult(result)}]"))
      )

      examplePassed = method(example,
        println(green("- #{example description}"))
      )

      propertyExamplePassed = method(example, result,
        println(green("- #{example description}    [#{formatPropertyResult(result)}]"))
      )

      examplePending = method(example, message,
        super(example, message)
        println(yellow("- #{example description} (PENDING: #{message})"))
      )
    )

    ProgressBarFormatter = ISpec Formatter TextFormatter mimic do(
      exampleFailed = method(example, counter, failure,
        print(red("F"))
      )

      examplePassed = method(example,
        print(green("."))
      )

      examplePending = method(example, message,
        super(example, message)
        print(yellow("P"))
      )

      propertyExamplePassed = method(example, result,
        print(green(","))
      )

      propertyExampleExhausted = method(example, counter, result,
        print(magenta("X"))
      )

      propertyExampleFailed = method(example, counter, failure, 
        print(red("@"))
      )


      startDump      = method(println(""))
      pass           = method(+rest, +:krest, nil) ;ignore other methods
    )

    HtmlFormatter = ISpec Formatter TextFormatter mimic do(
      use("blank_slate")
      html = BlankSlate create(fn(bs,
            bs pass = method(+args, +:attrs,
              args "<%s%:[ %s=\"%s\"%]>%[%s%]</%s>\n" format(
                currentMessage name, attrs, args, currentMessage name))))

      start = method(exampleCount,
        super(exampleCount)
        html style(type: "text/css",
          ".spec {
             padding: 3px;
             margin: 3px;
           }

           .exampleGroup {
             background-color: #005500;
             padding: 5px;
             color: white
           }

           .failed {
             background-color: #ffaaaa;
             border-left: solid 3px #ff1122;
           }

           .passed {
             background-color: #33ff55;
             border-left: solid 3px #005500;
           }

           .pending {
             background-color: #ffee77;
             border-left: solid 3px #ffee22;
           }"
        ) println
      )

      stackTraceAsLink = method(example, name nil,
        if(example cell?(:shouldMessage),
          txmtLink(example shouldMessage, name),
          txmtLink(example code, name))
      )

      txmtLink = method(code, name,
        ; txmt://open/?url=file://~/.bash_profile&line=11&column=2
        name ||= "#{code filename}:#{code line}:#{code position}"
        html a(href: "txmt://open/?url=file://#{code filename}&line=#{code line}&column=#{code position}", name)
      )

      addExampleGroup = method(exampleGroup,
        super(exampleGroup)
        html div(class: "exampleGroup", exampleGroup fullName) println
      )

      exampleFailed = method(example, counter, failure,
        html div(class: "failed spec",
          link = stackTraceAsLink(failure condition example, "#{failure condition example code filename}:#{failure condition example code line}")
          "#{example description}<br/>FAILED: #{failure condition report replaceAll(#/\n/, "<br/>")}#{link}"
        ) println
      )

      examplePassed = method(example,
        html div(class: "passed spec", example description) println
      )

      examplePending = method(example, message,
        super(example, message)
        html div(class: "pending spec", "#{example description} (PENDING: #{message})") println
      )

      dumpSummary = method(duration, exampleCount, failureCount, pendingCount, propertyCount, exhaustedCount, propertyInstanceCount, discardedCount, nil)
      dumpFailure = method(counter, failure, nil)
      dumpPending = method(nil)
    )

    addExampleGroup = method(exampleGroup, @exampleGroup = exampleGroup)
    start           = method(exampleCount, nil)
    exampleStarted  = method(example, nil)
    exampleFailed   = method(example, counter, failure, nil)
    examplePassed   = method(example, nil)
    examplePending  = method(example, message, nil)
    dumpFailure     = method(counter, failure, nil)
    dumpSummary     = method(duration, exampleCount, failureCount, pendingCount, propertyCount, exhaustedCount, propertyInstanceCount, discardedCount, nil)
    dumpPending     = method(nil)
    startDump       = method(nil)
    output          = System out mimic do(close = nil)
    close           = method(output close)
    println         = method(a, output println(a))
    print           = method(a, output print(a))

    propertyExampleStarted   = method(example, nil)
    propertyExamplePassed    = method(example, result, nil)
    propertyExampleExhausted = method(example, counter, result, nil)
    propertyExampleFailed    = method(example, counter, failure, nil)
  )
)
