import "phoenix_html"

import socket from "./socket"
import $ from "jquery"
import cities from "./cities.topo"
import countries from "./countries.topo"

$(function() {
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

  // create marker definition
  svg.append("defs")
     .append("marker")
     .attr("id", "arrow")
     .attr("viewBox", "0 -5 10 10")
     .attr("refX", 10)
     .attr("refY", 0)
     .attr("markerWidth", 4)
     .attr("markerHeight", 4)
     .attr("orient", "auto")
     .append("path")
     .attr("d", "M0,-5L10,0L0,5");

  // create countries
  svg.append("g")
     .attr("class", "countries")
     .selectAll("path")
     .data(topojson.feature(countries, countries.objects.countries).features)
     .enter()
     .append("path")
     .attr("d", path);

  // create cities
  svg.append("g")
     .attr("class", "cities")
     .selectAll("path")
     .data(topojson.feature(cities, cities.objects.cities).features)
     .enter()
     .append("path")
     .attr("id", function(d) {return d.id;})
     .attr("d", path);

  var citiesMap = {};
  var geos = topojson.feature(cities, cities.objects.cities).features;
  for (let i in geos) {
    citiesMap[geos[i].id] = geos[i].geometry.coordinates;
  }

  function transition(route) {
    route.transition()
      .duration(500)
      .remove()
  }

  function fly(origin, destination) {
    var route = svg.append("path")
      .datum({type: "LineString", coordinates: [citiesMap[origin], citiesMap[destination]]})
      .attr("class", "route")
      .attr("d", path)
      .attr("marker-end", "url(#arrow)");

    transition(route);
  }

  // websocket setup
  let channel = socket.channel("room:lobby", {})

  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

  channel.on("routing_event", payload => {
    console.log(payload);
    let from = payload.current;
    let to = payload.gateway;
    fly(from, to);
  });

  $(window).resize(function() {
    currentWidth = $("#map").width();
    svg.attr("width", currentWidth);
    svg.attr("height", currentWidth * height / width);
  });
});
