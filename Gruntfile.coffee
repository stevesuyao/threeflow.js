child_process = require "child_process"
eco           = require "eco"

module.exports = (grunt)->
  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"

    # coffee
    coffee:
      client:
        options:
          join:true
        files:
          "bin/threeflow.js":"src/client/**/*.coffee"
      examples:
        options:
          bare:true
        files: grunt.file.expandMapping("src/examples/*.coffee","examples/js/",
          flatten:true
          rename:(destBase,destPath)->
            destBase + destPath.replace(".coffee",".js")
          )
      extras:
        files:
          "bin/threeflow_datgui.js":"src/extras/DatGui.coffee"
    uglify:
      main:
        files:
          "bin/threeflow.min.js":"bin/threeflow.js"
          "bin/threeflow_datgui.min.js":"bin/threeflow_datgui.js"
    copy:
      examples:
        expand:true
        flatten:true
        src:"bin/*.*"
        dest: "examples/js/"

    watch:
      main:
        files:[ "src/client/**/*.coffee","src/server/**/*.coffee", "src/examples/*.coffee","src/examples/*.html.eco","src/extras/*.coffee" ]
        tasks:["coffee","copy","examples-html"]


  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-watch"

  grunt.registerTask "default",["deploy"]
  grunt.registerTask "deploy",["coffee","uglify","copy"]
  grunt.registerTask "dev",["watch"]

  grunt.registerTask "server",()->
    done = @async()
    child = child_process.exec "coffee src/server/server.coffee",done
    child.stdout.pipe process.stdout
    child.stderr.pipe process.stderr
    null


  grunt.registerTask "examples-html",()->
    examples = grunt.file.expandMapping "src/examples/*.coffee","examples/",
      flatten:true
      rename:(destBase,destPath)->
        destBase + destPath.replace(".coffee",".html")

    template = grunt.file.read "src/examples/example.html.eco"

    # write example html files.
    for example in examples
      js = example.src[0].split("/").pop().replace(".coffee",".js")
      example.name = js.replace(".js","")
      example.html = example.dest.split("/").pop()

      rendered = eco.render template,
        example_name: example.name
        example_js: js

      console.log "Written ", example.dest
      grunt.file.write example.dest,rendered

    # write index.html
    index = "examples/index.html"
    template = grunt.file.read "src/examples/index.html.eco"
    grunt.file.write index,eco.render(template,{examples:examples})
    console.log "Written ", index
    null


  grunt.registerTask "convert-obj",()->
    files = grunt.file.expand "src/models/*.obj"
    done = @async()
    next = ()->
      if files.length
        obj = files.pop()
        inFile = obj
        outFile = "examples/models/" + obj.split("/").pop().replace("obj","json")

        command = "python src/models/convert_obj_three.py -i " + inFile + " -o " + outFile
        child_process.exec command,next
      else
        done()

    next()



