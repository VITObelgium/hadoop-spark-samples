"""
This sample program uses Apache Spark to calculate a histogram for each Sentinel-2 NDVI tile within a given time range and
bounding box and sums them up - all in parallel.

The code in the __main__ block will be executed on a single node, the 'driver'. It describes the different steps that need
to be executed in parallel.
"""
from operator import add
from pyspark import SparkContext

from histogram_sample_package.functions import ndvi_files, histogram

if __name__ == '__main__':
    # Query the Sentinel-2 files that will be processed.
    # This method returns a list of paths to tif files that match a specific time range and bounding box.
    files = ndvi_files(collection='terrascope-s2-ndvi-v2',
                       start_date='2024-05-01T00:00:00Z', end_date='2024-06-10T00:00:00Z',
                       min_lon=4.91, max_lon=5.24, min_lat=51.16, max_lat=51.27)

    #The SparkContext is our entry point to bootstrap parallel operations.
    sc = SparkContext(appName='python-spark-quickstart')

    try:
        #Distribute the local file list over the cluster. In Spark terminology, the result is called an RDD (Resilient Distributed Dataset).
        filesRDD = sc.parallelize(files)
        #Apply the 'histogram' function to each filename using 'map', keep the result in memory using 'cache'.
        hists = filesRDD.map(histogram).cache()
        #Count number of histograms
        count = hists.count()
        #Combine distributed histograms into a single result
        total = list(hists.reduce(lambda h, i: map(add, h, i)))

        print( "sum of %i histograms: %s" % (count, total) )
    finally:
        sc.stop()
