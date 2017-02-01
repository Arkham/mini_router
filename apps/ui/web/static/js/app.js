import "phoenix_html"

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

  var airportMap = {};

  function transition(route) {
    route.transition()
      .duration(3000)
      .remove()
  }

  function fly(origin, destination) {
    var route = svg.append("path")
      .datum({type: "LineString", coordinates: [airportMap[origin], airportMap[destination]]})
      .attr("class", "route")
      .attr("d", path)
      .attr("marker-end", "url(#arrow)");

    transition(route);
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

    fly(AIRPORTS[from_index], AIRPORTS[to_index]);
  });

  loaded();

  $(window).resize(function() {
    currentWidth = $("#map").width();
    svg.attr("width", currentWidth);
    svg.attr("height", currentWidth * height / width);
  });
});
