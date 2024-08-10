
var stations = []; // array to hold temperature data
var address =  context.getVariable('request.queryparam.near'); // street address from search
var lat = context.getVariable('lat'); // geocoded lat
var lon = context.getVariable('lon'); // geocoded lon

 // parse JSON from BigQuery response
var dataSet = JSON.parse(context.proxyResponse.content);

// add date and temperture data to array
for(i=0; i < dataSet.totalRows; i++) {
    distance = getDistanceFromLatLonInKm(lat,lon,dataSet.rows[i].f[3].v,dataSet.rows[i].f[4].v) 
	stations.push({"id": dataSet.rows[i].f[0].v, 
	            "name": dataSet.rows[i].f[1].v.replace(/"/g, ''),
	            "state": dataSet.rows[i].f[2].v,
	            "lat": dataSet.rows[i].f[3].v,	            
	            "lon": dataSet.rows[i].f[4].v,
	            "hcn_crn_flag": dataSet.rows[i].f[5].v,
	            "distance": Math.round(distance * 100) / 100
	});		
}	

// sort by distance
stations.sort(function(a, b){return a.distance - b.distance});

var output = {"address" : address, "lat" : lat, "lon" : lon, "stations" : stations }

// convert object to a string and replace the HTTP response with new, formatted data
context.proxyResponse.content = JSON.stringify(output);

// Calculate the distance between two points
function getDistanceFromLatLonInKm(lat1,lon1,lat2,lon2) 
{
  var R = 6371; // Radius of the earth in km
  var dLat = deg2rad(lat2-lat1);  // deg2rad below
  var dLon = deg2rad(lon2-lon1); 
  var a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2)
    ; 
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  var d = R * c; // Distance in km
  d = d * 0.62137; // convert to miles
  
  return d;
}

function deg2rad(deg) 
{
  return deg * (Math.PI/180)
}
