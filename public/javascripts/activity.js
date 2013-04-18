function draw_activity(url) {
  var colors = ["#eee", "#d6e685", "#8cc665", "#44a340", "#1e6823"];
  
  var z = 11, w = 709, h = 111;
  var day = d3.time.format("%w"),
      week = d3.time.format("%U"),
      formatDate = d3.time.format("%Y-%m-%d");
      
  var today = new Date();
  var one_year_ago = new Date(); one_year_ago.setTime(today.getTime() - 365 * 24 * 60 * 60 * 1000);

  var svg = d3.select("#activity").selectAll(".year")
      .data(d3.range(2012,2013))
    .enter().append("div")
      .attr("class", "year")
      .style("display", "inline-block")
    .append("svg:svg")
      .attr("width", w + "px")
      .attr("height", h +"px")
      .attr("class", "RdYlGn")
    .append("svg:g")
      .attr("transform", "translate(20,20)");

  var months = d3.time.month.range(one_year_ago, today).map(
    function(d) { return d3.time.format("%b")(d); });
  svg.selectAll("text.month")
      .data(months)
    .enter().append("svg:text")
      .attr("class", "month")
      .attr("x", function(d, i) { return (i+1) * 52; })
      .attr("y", "-5")
      .text(function(d) {return d;});


  var rect = svg.selectAll("rect.day")
      .data(function(d) { return d3.time.days(one_year_ago, today); })
    .enter().append("svg:rect")
      .attr("class", "day")
      .attr("width", z)
      .attr("height", z)
      .attr("x", function(d) {
        return (week(d) - week(one_year_ago) + (d.getYear() - one_year_ago.getYear()) * 52)  * (z+2);
      }).attr("y", function(d) { return day(d) * (z+2); });

  rect.append("svg:title");
  d3.json(url, function(error, json) {
    var max = 1;
    max = d3.max(json, function(d) { return Math.max(d[1],max); });

    svg.each(function(year) {
      d3.select(this).selectAll("rect.day")
        .attr("style", function(d, i) {
          return "fill: " + colors[Math.ceil(json[i][1] * (colors.length-1) / max)];
        })
        .on("click", function(e) { /* search */ })
        .select("title")
          .text(function(d) { return formatDate(d); });
    });
  });
}