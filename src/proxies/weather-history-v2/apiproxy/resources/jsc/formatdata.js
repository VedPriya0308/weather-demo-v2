// parse JSON from BigQuery response
var dataSet = JSON.parse(context.proxyResponse.content);

// array to hold temperature data
var values = [];

// add date and value data to array
for(i=0; i < dataSet.totalRows; i+=2) {
	values.push({"date": dataSet.rows[i].f[0].v, "low": dataSet.rows[i].f[1].v, "high": dataSet.rows[i+1].f[1].v});		
}	

// create new object with data
var station =  context.getVariable('station');
var year = context.getVariable('year');
var output = {"station" : station, "year" : year, "data" : values }

// convert object to a string and replace the HTTP response with new, formatted data
context.proxyResponse.content = JSON.stringify(output);
