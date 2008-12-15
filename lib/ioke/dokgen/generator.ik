
DokGen do(
  HtmlGenerator = Origin mimic do(
    generate = method(directory, collection,
      FileSystem ensureDirectory(directory)
      FileSystem ensureDirectory("#{directory}/files")
      FileSystem ensureDirectory("#{directory}/kinds")

      copyStationaryFiles(directory)
      copyReadmeIfAvailable(directory)

      generateFileFrame(directory, collection collectedFiles)
      generateKindFrame(directory, collection collectedKinds)
      generateCellFrame(directory, collection collectedCells)

      generateFileFiles(directory, collection collectedFiles)
      generateKindFiles(directory, collection collectedKinds, collection collectedCells)
    )

    copyStationaryFiles = method(dir,
      copyStationary("dokgen-style.css", dir)
      copyStationary("index.html", dir)
    )

    copyReadmeIfAvailable = method(dir,
      if(FileSystem exists?("README"),

        generateFromTemplate(Templates Readme, 
          out: "#{dir}/files/README.html", 
          content: FileSystem readFully("README"),
          basePath: "../"),

        copyStationary("README.html", "#{dir}/files"))
    )

    copyStationary = method(file, dir,
      FileSystem copyFile("#{System currentDirectory}/htmlGenerator/stationary/#{file}", dir)
    )
    
    generateFromTemplate = method(template, out:, +:krest,
      FileSystem withOpenFile(out, fn(f, template generateIntoFile(f, *krest)))
    )

    generateFileFrame = method(dir, files,
      names = (files keys sort - ["<init>"]) map(fname,
        [htmlizeName(fname), fname])

      content = "%*[<a href=\"files/%s\">%s</a><br />\n%]" format(names)

      generateFromTemplate(Templates FileFrame, 
        out: "#{dir}/fr_file_index.html", 
        content: content)
    )

    htmlizeName = method(name,
      if(#/ik$/ =~ name,
        "#{name[0..-4]}.html",
        "#{name}.html"))

    generateKindFrame = method(dir, kinds,
      allKinds = kinds keys sort map(x, [x replaceAll(" ", "/"), x])

      content = "%*[<a href=\"kinds/%s.html\">%s</a><br />\n%]" format(allKinds)
      generateFromTemplate(Templates KindFrame, 
        out: "#{dir}/fr_kind_index.html", 
        content: content)
    )

    generateCellFrame = method(dir, cells,
      cellData = []
      cells keys sort each(c, 
        xx = cells[c] sortBy(cc, [cc[0] kind, cc[3]])
        xx each(ccc,
          cellData << [ccc[0] kind replaceAll(" ", "/"), ccc[3], c asText replaceAll("<", "&lt;") replaceAll(">", "&gt;"), ccc[0] kind]))

      content = "%*[<a href=\"kinds/%s.html#C00%s\">%s (%s)</a><br />\n%]" format(cellData)
      generateFromTemplate(Templates CellFrame, 
        out: "#{dir}/fr_cell_index.html", 
        content: content)
    )

    generateFileFile = method(dir, sourceFileName, info,
      segments = sourceFileName split("/")
      beforeLinks = "../" * (segments length)

      htmlFile = "#{dir}/files/#{htmlizeName(sourceFileName)}"
      parent = FileSystem parentOf(htmlFile)
      FileSystem ensureDirectory(parent)
      methods = []
      macros = []
      
      ;; we need to sort on both the method name, the surrounding kind and the unique ID
      ;; since we need to guarantee a ordering. 
      ;; bad things will happen if the sort starts looking at the other elements in the list
      info sortBy(x, [x[1], x[0] kind, x[3]]) each(v,
        if(v[2] kind?("DefaultMacro"), 
          macros << [v[0] kind replaceAll(" ", "/"), v[3], v[1] asText replaceAll("<", "&lt;") replaceAll(">", "&gt;"), v[0] kind],
          if(v[2] kind?("Method"), 
            methods << [v[0] kind replaceAll(" ", "/"), v[3], v[1] asText replaceAll("<", "&lt;") replaceAll(">", "&gt;"), v[0] kind])))

      methodContent = "%*[<li><a href=\"#{beforeLinks}kinds/%s.html#C00%s\">%s (%s)</a><br /></li>\n%]" format(methods)
      macroContent = "%*[<li><a href=\"#{beforeLinks}kinds/%s.html#C00%s\">%s (%s)</a><br /></li>\n%]" format(macros)

      generateFromTemplate(Templates FileFile,
        out: htmlFile,
        filePath: sourceFileName,
        simpleFileName: segments last,
        fileDate: "---fluxie---",
        methodContent: methodContent,
        macroContent: macroContent,
        syntaxContent: "",
        basePath: beforeLinks
      )
    )

    generateFileFiles = method(dir, files,
      files each(f, unless(f key == "<init>", generateFileFile(dir, f key, f value)))
    )
  )

  generate = method(+args, HtmlGenerator generate(*args))
)

use("dokgen/htmlGenerator/templates")
