rrd2Canopsis
============

This is something that allow to import RRD to Canopsis. You have to develop your own script that return some object that contains informations and RRD path.


##Requirements

Conenctor script :

    cpan -i JSYNC
    
Script "rrd2Obj.pl" :

    cpan -i JSYNC
    
Script "obj2Canopsis.pl" :

    cpan -i JSYNC
    cpan -i Net::RabbitFoot
    cpan -i JSON::XS
    
##Steps

This connector is splited in 3 parts : first the connector script (which is the one you have to develop), the second is "rrd2Obj.pl (which will parse RRD data) and the last is "obj2Canopsis.pl" (which will send data to Canopsis).

Example :

    ./muninDF2Obj.pl | ./rrd2Obj.pl | ./obj2Canopsis.pl
    
Your can use "global" option on "rrd2Obj.pl" to send all RRD Data, if you don't only the last record of each RRD file will be send.

    ./muninDF2Obj.pl | ./rrd2Obj.pl --global | ./obj2Canopsis.pl
    
Note : you can use it with SSH (all data will transfered to another script with JSON to STDOUT/IN).

##Connector

Use script "muninDF2Obj.pl" to create your own connector script. In this, I use "datafile" which is located in /var/lib/munin/ to generate an object list.

That list have to contains : 

    component (munin-node)
    resource (plugin)
    metric (for each lines on graphs)
        name
        id
        type
        path (path of RRD)
        
Note : In my case, each object is a Munin's plugin.

Bellow an example of the print Dumper of an object :

    bless( {
                     'resource' => 'diskstats_utilization',
                     'component' => 'master.triden.org',
                     'metric' => [
                                   bless( {
                                            'name' => 'Device utilization',
                                            'data' => {
                                                        '1374842404' => '2.92757475083056'
                                                      },
                                            'id' => 'sda.util',
                                            'type' => 'GAUGE'
                                          }, 'sda.util' ),
                                   bless( {
                                            'name' => 'sda',
                                            'data' => {
                                                        '1374842404' => '2.92757475083056'
                                                      },
                                            'id' => 'sda_util',
                                            'type' => 'GAUGE'
                                          }, 'sda_util' )
                                 ]
                   }, 'triden.org-master.triden.org-diskstats_utilization' )
                   
When you have created a pretty object, you have to encode it and print it :

    my $json = JSYNC::dump($obj);
    print $json;
