// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"
import $ from "jquery"
import airports from "./airports.topo"
import countries from "./countries.topo"

$(function() {
  var AIRPORTS = [
    "ATL",
    "PEK",
    "LHR",
    "NRT",
    "ORD",
    "LAX",
    "CDG",
    "DFW",
    "CGK",
    "DXB",
    "FRA",
    "HKG",
    "DEN",
    "SIN",
    "AMS",
    "JFK",
    "MAD",
    "IST",
    "PVG",
    "SFO",
    "LAS",
    "MIA",
    "FCO",
    "MCO",
    "SYD",
    "YYZ",
    "SEA",
    "BOM",
    "SVO",
    "MEX",
    "CUN",
    "YYC",
    "EZE",
    "ARN",
    "CPT",
    "CAI",
    "DEL",
    "HNL",
    "GRU"
  ];

  var currentWidth = $('#map').width();
  var width = 938;
  var height = 620;

  var projection = d3.geo
                     .mercator()
                     .scale(150)
                     .translate([width / 2, height / 1.41]);

  var path = d3.geo
               .path()
               .pointRadius(2)
               .projection(projection);
  
  var svg = d3.select("#map")
              .append("svg")
              .attr("preserveAspectRatio", "xMidYMid")
              .attr("viewBox", "0 0 " + width + " " + height)
              .attr("width", currentWidth)
              .attr("height", currentWidth * height / width);

  var airportMap = {};

  function transition(plane, route) {
    // var l = route.node().getTotalLength();
    // plane.transition()
    //     .duration(100)
    //     .attrTween("transform", delta(plane, route.node()))
    //     .each("end", function() { route.remove(); })
    //     .remove();

    route.transition()
      .duration(500)
      .remove()
  }
  
  function delta(plane, path) {
    var l = path.getTotalLength();
    var plane = plane;
    return function(i) {
      return function(t) {
        var p = path.getPointAtLength(t * l);

        var t2 = Math.min(t + 0.05, 1);
        var p2 = path.getPointAtLength(t2 * l);

        var x = p2.x - p.x;
        var y = p2.y - p.y;
        var r = 90 - Math.atan2(-y, x) * 180 / Math.PI;

        var s = Math.min(Math.sin(Math.PI * t) * 0.7, 0.3);

        return "translate(" + p.x + "," + p.y + ") scale(" + s + ") rotate(" + r + ")";
      }
    }
  }

  function fly(origin, destination) {
    var route = svg.append("path")
                   .datum({type: "LineString", coordinates: [airportMap[origin], airportMap[destination]]})
                   .attr("class", "route")
                   .attr("d", path);

    // var plane = svg.append("path")
    //                .attr("class", "plane")
    //                .attr("d", "m25.21488,3.93375c-0.44355,0 -0.84275,0.18332 -1.17933,0.51592c-0.33397,0.33267 -0.61055,0.80884 -0.84275,1.40377c-0.45922,1.18911 -0.74362,2.85964 -0.89755,4.86085c-0.15655,1.99729 -0.18263,4.32223 -0.11741,6.81118c-5.51835,2.26427 -16.7116,6.93857 -17.60916,7.98223c-1.19759,1.38937 -0.81143,2.98095 -0.32874,4.03902l18.39971,-3.74549c0.38616,4.88048 0.94192,9.7138 1.42461,13.50099c-1.80032,0.52703 -5.1609,1.56679 -5.85232,2.21255c-0.95496,0.88711 -0.95496,3.75718 -0.95496,3.75718l7.53,-0.61316c0.17743,1.23545 0.28701,1.95767 0.28701,1.95767l0.01304,0.06557l0.06002,0l0.13829,0l0.0574,0l0.01043,-0.06557c0,0 0.11218,-0.72222 0.28961,-1.95767l7.53164,0.61316c0,0 0,-2.87006 -0.95496,-3.75718c-0.69044,-0.64577 -4.05363,-1.68813 -5.85133,-2.21516c0.48009,-3.77545 1.03061,-8.58921 1.42198,-13.45404l18.18207,3.70115c0.48009,-1.05806 0.86881,-2.64965 -0.32617,-4.03902c-0.88969,-1.03062 -11.81147,-5.60054 -17.39409,-7.89352c0.06524,-2.52287 0.04175,-4.88024 -0.1148,-6.89989l0,-0.00476c-0.15655,-1.99844 -0.44094,-3.6683 -0.90277,-4.8561c-0.22699,-0.59493 -0.50356,-1.07111 -0.83754,-1.40377c-0.33658,-0.3326 -0.73578,-0.51592 -1.18194,-0.51592l0,0l-0.00001,0l0,0z");

    transition(null, route);
  }

  function hashCode (str){
    var hash = 0;
    if (str.length == 0) return hash;
    for (let i = 0; i < str.length; i++) {
      let char = str.charCodeAt(i);
      hash = ((hash<<5)-hash)+char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
  }

  function loaded() {
    svg.append("g")
       .attr("class", "countries")
       .selectAll("path")
       .data(topojson.feature(countries, countries.objects.countries).features)
       .enter()
       .append("path")
       .attr("d", path);

    svg.append("g")
       .attr("class", "airports")
       .selectAll("path")
       .data(topojson.feature(airports, airports.objects.airports).features)
       .enter()
       .append("path")
       .attr("id", function(d) {return d.id;})
       .attr("d", path);

    var geos = topojson.feature(airports, airports.objects.airports).features;
    for (let i in geos) {
      airportMap[geos[i].id] = geos[i].geometry.coordinates;
    }
  }

  let channel = socket.channel("room:lobby", {})

  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

  channel.on("routing_event", payload => {
    console.log(payload);
    let from = payload.current;
    let to = payload.gateway;

    let from_index = hashCode(from) % AIRPORTS.length;
    let to_index = hashCode(to) % AIRPORTS.length;

    console.log(AIRPORTS.length);
    console.log(from_index);
    console.log(to_index);

    fly(AIRPORTS[from_index], AIRPORTS[to_index]);
  });

  loaded();

  $(window).resize(function() {
    currentWidth = $("#map").width();
    svg.attr("width", currentWidth);
    svg.attr("height", currentWidth * height / width);
  });
});
