downloadActivityEffort = function(activityId, segmentCount) {
  fetch("/activities/" + activityId + "/download", { credentials: 'include' }).then(function(response) {
    return response.json()
  }).then(function(data) {
    if(data.downloaded_segment_efforts == segmentCount) {
      window.location.pathname = '/'
    }
    document.querySelector('.downloaded-count').innerText = data.downloaded_segment_efforts
    downloadActivityEffort(activityId, segmentCount)
  })
}

var TemplateEngine = function(html, options) {
    var re = /{([^}]+)?}/g, reExp = /(^( )?(if|for|else|switch|case|break|{|}))(.*)?/g, code = 'var r=[];\n', cursor = 0, match;
    var add = function(line, js) {
        js? (code += line.match(reExp) ? line + '\n' : 'r.push(' + line + ');\n') :
            (code += line != '' ? 'r.push("' + line.replace(/"/g, '\\"') + '");\n' : '');
        return add;
    }
    while(match = re.exec(html)) {
        add(html.slice(cursor, match.index))(match[1], true);
        cursor = match.index + match[0].length;
    }
    add(html.substr(cursor, html.length - cursor));
    code += 'return r.join("");';
    return new Function(code.replace(/[\r\t\n]/g, '')).apply(options);
}

function addSegment(segment, map) {
  path = google.maps.geometry.encoding.decodePath(segment.points)

    var segmentLine = new google.maps.Polyline({
      path: path,
      map: map
    })
}

function initMap() {
  mapElement = document.getElementById('map')

  if(mapElement) {
    map = new google.maps.Map(mapElement, { zoom: 14 })

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(position) {
        var pos = {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        }

        map.setCenter(pos)

        boundsString = map.getBounds().toString().replace(/[\(\)]/g, '')

          fetch("/segments?bounds=" + boundsString, { credentials: 'include' }).then(function(response) {
            return response.json()
          }).then(function(data) {

            data.forEach(function(segment) { addSegment(segment, map); })

            console.log(data)
            window.z = data
          })
      })
    }
  }
}
