"""
This sample program uses Apache Spark to calculate a histogram for each Sentinel-2 NDVI tile within a given time range and
bounding box and sums them up - all in parallel.

The code in the __main__ block will be executed on a single node, the 'driver'. It describes the different steps that need
to be executed in parallel.
"""
from operator import add
from pyspark import SparkContext
import argparse

from .functions import ndvi_files, histogram, valid_date



def main():
    # Handle input via the command line to parametrize script execution
    parser = argparse.ArgumentParser(
        prog='histcalc',
        description='Calculate a histogram for a time range and bounding box of Sentinel-2 NDVI tiles.')

    parser.add_argument('--start_date', '-s', type=valid_date, default='2024-05-01',
                        help='Time range start date (yyyy-mm-dd)')
    parser.add_argument('--end_date', '-e', type=valid_date, default='2024-06-10',
                        help='Time range end date (yyyy-mm-dd)')
    args = parser.parse_args()

    # Query the Sentinel-2 files that will be processed.
    # This method returns a list of paths to tif files that match a specific time range and bounding box.
    files = ndvi_files(collection='terrascope-s2-ndvi-v2',
                       start_date=f'{args.start_date}T00:00:00Z', end_date=f'{args.end_date}T00:00:00Z',
                       min_lon=4.91, max_lon=5.24, min_lat=51.16, max_lat=51.27)

    #The SparkContext is our entry point to bootstrap parallel operations.
    sc = SparkContext(appName='python-spark-quickstart')

    try:
        #Distribute the local file list over the cluster. In Spark terminology, the result is called an RDD (Resilient Distributed Dataset).
        filesRDD = sc.parallelize(files)
        #Apply the 'histogram' function to each filename using 'map', keep the result in memory using 'cache'.
        hists = filesRDD.map(histogram).cache()
        #Count the number of histograms
        count = hists.count()
        #Combine distributed histograms into a single result
        total = list(hists.reduce(lambda h, i: map(add, h, i)))

        print( "sum of %i histograms: %s" % (count, total) )
    finally:
        sc.stop()

if __name__ == "__main__":
    main()