function downloadActivityEffort(activityId, segmentCount) {
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

function templateEngine(html, options) {
    var re = /{([^}]+)?}/g, reExp = /(^( )?(if|for|else|switch|case|break|{|}))(.*)?/g, code = 'var r=[];\n', cursor = 0, match;
    var add = function(line, js) {
        js? (code += line.match(reExp) ? line + '\n' : 'r.push(' + line + ');\n') :
            (code += line != '' ? 'r.push("' + line.replace(/"/g, '\\"') + '");\n' : '')
        return add
    }
    while(match = re.exec(html)) {
        add(html.slice(cursor, match.index))(match[1], true)
        cursor = match.index + match[0].length
    }
    add(html.substr(cursor, html.length - cursor))
    code += 'return r.join("");'
    return new Function(code.replace(/[\r\t\n]/g, '')).apply(options)
}

function speedToHSL(estimatedTime, KOMTime) {
  if(estimatedTime <= KOMTime) {
    return 200
  } else {
    in_min = 50
    out_min = 0
    in_max = 100
    out_max = 120
    current = Math.max(in_min, 1 / (estimatedTime / KOMTime) * 100)

    return parseInt((current - in_min) * (out_max - out_min) / (in_max - in_min) + out_min)
  }
}

function addSegment(segment) {
  path = google.maps.geometry.encoding.decodePath(segment.points)

    var segmentLine = new google.maps.Polyline({
      path: path,
      map: window.map
    })

  segmentContent = templateEngine(document.getElementById('segmentTemplate').innerHTML, {
    id: segment.id,
    name: segment.name,
    distance: (segment.distance / 1000).toFixed(1),
    grade: segment.avg_grade,
    KOMSpeed: (segment.distance / 1000 / segment.leaderboard.entries[0].elapsed_time * 3600).toFixed(2),
    estimatedSpeed: (segment.distance / 1000 / segment.predicted_time * 3600).toFixed(2),
    hsl: speedToHSL(segment.predicted_time, segment.leaderboard.entries[0].elapsed_time),
    speedIndex: parseInt((segment.predicted_time / segment.leaderboard.entries[0].elapsed_time) * 1000)
  })

  document.getElementById('map-sidebar__segments').insertAdjacentHTML('beforeend', segmentContent)
}

function getSegments() {
  boundsString = window.map.getBounds().toString().replace(/[\(\)]/g, '')

  fetch("/segments?bounds=" + boundsString, { credentials: 'include' }).then(function(response) {
    return response.json()
  }).then(function(data) {
    window.data = data
    data.forEach(function(segment) { addSegment(segment); })
  })
}

function initMap() {
  mapElement = document.getElementById('map')

  if(mapElement) {
    window.map = new google.maps.Map(mapElement, { zoom: 16 })

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(position) {
        var pos = {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        }

        window.map.setCenter(pos)
      })
    }
  }
}

document.getElementById('map-sidebar__scan-button').onclick = function() {
  getSegments()

  return false;
}
