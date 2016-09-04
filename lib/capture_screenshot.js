var page = require('webpage').create()
var system = require('system')
var url = system.args[1]
var path = system.args[2]
var width = system.args[3]
var height = system.args[4]
var zoomFactor = system.args[5]
page.settings.resourceTimeout = 2000
page.viewportSize = {width: width, height: height}
page.zoomFactor = zoomFactor

page.open(url, function (status) {
  page.render(path)
  phantom.exit()
});

