# Getting started
## Get your Data from Google:

https://takeout.google.com/settings/takeout and schedule your "Location
History" Download in JSON format.

Once it's done, extract the archive and put the 'Location History.json' into
this project's working directory.

## Set up the whole funnel

In this project's directory, first things first:

```
touch raw_json
```


### Launch Elasticsearch:

```
docker run --rm -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" --name elasticsearch docker.elastic.co/elasticsearch/elasticsearch:7.6.2
```

### Option 1: Mapping / Index pattern `locations-*`:

Downside: Turned out to be pretty slow in the first experiments
Upside: Logstash usually does this for logs.


```
curl -X PUT "localhost:9200/_template/template_1?pretty" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["locations-*"],
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
    "properties": {
      "location": {
        "type": "geo_point"
      }
    }
  }
}
'
```

### Option 2: Everything into one single index `locations`

*Preferred!*

Downside: One index contains A LOT information then, which cannot
replicate/shard well
Upside: Quicker queries(?)


```
curl -X PUT "localhost:9200/locations?pretty" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "location": {
        "type": "geo_point"
      }
    }
  }
}
'
```

### Launch Logstash

This step prepares logstash to be ready to load the `raw_json` file the
following step creates. The contents of this file will be read into
ElasticSearch once the `raw_json` file gets written.

```
docker run --name logstash --rm --workdir=/app --link elasticsearch -v $(pwd):/app -ti docker.elastic.co/logstash/logstash:7.6.2 logstash -f logstash.conf
```

### Launch Kibana

```
docker run --rm --link elasticsearch:elasticsearch -p 5601:5601 --name kibana docker.elastic.co/kibana/kibana:7.6.2
```

## Turn Google Takeout into `raw_json`
... so that logstash can put it into the ELK cluster.

```
./00_google2raw.sh 'Location History.json'
```

Your `raw_json` now contains your location history in a format that can be
digested by logstash.

Logstash will automatically pick it up once it's there.

## Access Kibana and display the data

Go to http://localhost:5601 and open Kibana in your browser. Go to the
administration panel and create an *Index Pattern* that matches your index
treatment selected above (either `locations-*` for Option 1 or `locations` for
Option 2).

Once you're done, you can start [start
discovering](http://localhost:5601/app/kibana#/discover/). Mind the selected
time window.

Head over to [visualizations](http://localhost:5601/app/kibana#/visualize?_g=()) in order to play around with the data visually. Recommended visualizations include *Coordinate Map* and *Maps*.
But also *Pie* and others can be interesting in order to explore various
non-spatial aspects of your data.

# Remarks & Hints

## Boooh, Kibana clusters all my activity around my home & my work

Okay, first, the system wants to tell you you're a couch potatoe or a workaholic. 

Second, you can overcome this problem by providing Kibana an ElasticSearch query (yes you can do that!)
that's excluding specific areas, just like your home or your work. See this
example, look at this like a pseudocde `NOT([lat1,lon1] OR [lat2,lon2])`:

```
{
  "bool":{
    "must_not":{
      "bool":{
        "should":[
          {
            "bool":{
              "must":{
                "match_all":{

                }
              },
              "filter":{
                "geo_distance":{
                  "distance":"500m",
                  "location":{
                    "lat":52.582713,
                    "lon":13.381726
                  }
                }
              }
            }
          },
          {
            "bool":{
              "must":{
                "match_all":{

                }
              },
              "filter":{
                "geo_distance":{
                  "distance":"1800m",
                  "location":{
                    "lat":52.128841,
                    "lon":13.819237
                  }
                }
              }
            }
          }
        ]
      }
    }
  }
}

```

**Note**: This will "punch holes" into your visualizations. Feel free to find
better exclusion methods.


# Possible next steps

* Roll out this approach to some other technology? Jupyter Notebooks? MongoDB?
* Deal with the `activity` arrays more and figure out WHAT you've been doing
