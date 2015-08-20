#!/bin/bash

generate_test_html()
{
    local suite="$1"
    local t="$2"
    local tname="${suite}_${t%.*}"
    local sep="["
    local min_v=
    local max_v=0
    N=$(($N + 1))
    local chart_data="var data$N = "
    local sha_map="var sha$N = "

 cat <<EOF >> ${TARGETDIR?}/index.div

<div class="test_container">
   <div class="legend" >$suite/${t%.*}</div>
   <div class="chart_container">
       <div class="axis" id="axis$N"></div>
       <div class="chart" id="chart$N"></div>
   </div>
</div>

EOF

    while read l;
    do
	entry=($l);
	if [ "$min_v" == "" ] ; then
	    min_v="${entry[2]}";
	elif [ ${entry[2]} -lt $min_v ] ; then
	    min_v="${entry[2]}";
	fi
	if [ ${entry[2]} -gt $max_v ] ; then
	    max_v="${entry[2]}";
	fi
	sha_map="$sha_map $sep { x: ${entry[0]}, y: '${entry[1]}' } "
	chart_data="$chart_data $sep { x: ${entry[0]}, y: ${entry[2]} } "
	sep=","
    done < $t
    sha_map="$sha_map ];"
    chart_data="$chart_data ];"
cat <<EOF  >> ${TARGETDIR?}/index.js

$sha_map
$chart_data

var min$N = Number.MAX_VALUE;
var max$N = Number.MIN_VALUE;
  for (_l = 0, _len2 = data$N.length; _l < _len2; _l++) {
    point = data${N}[_l];
    min$N = Math.min(min$N, point.y);
    max$N = Math.max(max$N, point.y);
  }
  min$N = parseInt(min$N * 0.99);
  max$N = parseInt(max$N * 1.01);



var graph$N = new Rickshaw.Graph( {
        element: document.getElementById('chart$N'),
        renderer: 'line',
        min: min$N,
        max: max$N,
        series: [ {
                color: 'steelblue',
                data: data$N,
        } ]
} );

new Rickshaw.Graph.Axis.Time( { graph: graph$N } );

new Rickshaw.Graph.Axis.Y( {
        graph: graph$N,
        orientation: 'left',
        tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
        element: document.getElementById('axis$N'),
} );

new Rickshaw.Graph.HoverDetail( {
    graph: graph$N,
    formatter: function(series, x, y) {
       var index = 0;
       for(index = 0; index < sha$N.length; index++ ) {
           if (sha${N}[index].x == x) { break; }
       }
       var content = sha${N}[index].y + ": " + y;
       return content; 
   }
} );

graph$N.render();

EOF
    
}


generate_suite_html()
{
    local suite="${1%/}"

    pushd "${TARGETDIR?}/data/$suite" > /dev/null || die "cannot cd to $TARGETDIR/data/$suite"
    for t in * ; do
	generate_test_html $suite $t
#	break
    done
}

generate_html()
{
    cat <<EOF > ${TARGETDIR?}/index.html.new
<!doctype>
<link type="text/css" rel="stylesheet" href="css/graph.css">
<link type="text/css" rel="stylesheet" href="css/detail.css">
<link type="text/css" rel="stylesheet" href="css/lines.css">

<script src="./js/d3.v3.js"></script>
<script src="./js/rickshaw.js"></script>

<style>
   .test_container {
     width: 460px;
     height: 300px;
     float: left;
     margin: 16px;
  }
   .chart_container {
     position: relative;
  }
  .chart {
    position: absolute;
    top: 0;
    left: 60px;
    height: 250px;
  }
 .axis {
    position: absolute;
    top: 0;
    width: 60px;
    height: 250px;
  }
  .legend {
    position: relative;
    font-family: "Verdana, Geneva, sans-serif";
    font-size: 100%;
    margin: 4px 0;
    text-align: center;
  }
  #top-banner {
    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
    min-width: -moz-min-content;
    background-color: #00A500;
    border-color: transparent;
  }
  #top-title {
    color: #E0E0E0;
    flex-shrink: 0;
    flex-basis: auto;
    white-space: nowrap;
    background-color: #00A500;
  }
  #top-title h2 {
    margin-bottom: 0;
  }
  #top-title p {
    margin: 0;
  }
  #logo {
    margin: 15px;
  }
</style>

<div id="top-banner">
<div id="logo"><img alt=:logo" src="img/logo.png"></img></div>
<div id="top-title">
<h2>LibreOffice result of perfcheck</h2>
<p style="font-size:50%">As of $(date -u)</p>
</div>
</div>
<div id="main">
EOF

    cat /dev/null > ${TARGETDIR?}/index.div
    cat /dev/null > ${TARGETDIR?}/index.js

    pushd "${TARGETDIR?}/data" > /dev/null || die "cannot cd to $TARGETDIR/data"
    for d in */ ; do
	generate_suite_html $d
#	break
    done

    cat ${TARGETDIR?}/index.div >> ${TARGETDIR?}/index.html.new
    echo "</div><script>" >> ${TARGETDIR?}/index.html.new
    cat ${TARGETDIR?}/index.js >> ${TARGETDIR?}/index.html.new
    echo "</script>" >> ${TARGETDIR?}/index.html.new
    mv ${TARGETDIR?}/index.html.new ${TARGETDIR?}/index.html
    cat /dev/null > ${TARGETDIR?}/index.div
    cat /dev/null > ${TARGETDIR?}/index.js
}

TARGETDIR="$HOME/perf_www"
N=0

while [ "${1}" != "" ]; do
    parm=${1%%=*}
    arg=${1#*=}
    has_arg=
    if [ "${1}" != "${parm?}" ] ; then
        has_arg=1
    else
        arg=""
    fi

    case "${parm}" in
        --targetdir)
            TARGETDIR="$arg"
            ;;
        -*)
            die "Invalid option $1"
            ;;
        *)
            die "Invalid argument $1"
            ;;
    esac
    shift
done

generate_html
