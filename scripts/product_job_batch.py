import sys
import time
import random
import math
import pandas as pd
from pyspark import SparkContext

def process_partition(iterator):
    """
    Processes an entire partition, demonstrating one-time initialization.
    The expensive setup runs only once for the entire batch of products.
    """
    # 1. Expensive, one-time initialization for the entire partition (batch).
    # This code runs ONCE per partition on a worker node. If we were using .map(),
    # this expensive step would have to run for every single product.
    print("--- Initializing shared resources for partition... ---")
    time.sleep(2) # Simulate expensive model loading time
    
    # Pretend this is our loaded model or resource.
    model = {'type': 'classification_model', 'version': 1.5}
    print(f"--- Initialization complete. Model: {model} ---")

    # 2. Process each product in the batch using the single initialized resource.
    for product_id in iterator:
        # Simulate using the model on each product ID
        score = (product_id % 23) * random.uniform(0.9, 1.1) + model['version']
        
        # 'yield' returns a stream of scores, which is memory-efficient.
        yield score

def main(num_products, batch_size):
    """
    Main Spark job to run a batched map-reduce operation.

    :param num_products: The total number of products to generate and process.
    :param batch_size: The number of products to group into a single partition/task.
    """
    sc = SparkContext(appName="BatchedInitProcessing")
    
    print("\n--- Job Configuration ---")
    print(f"Number of Products to process: {num_products}")
    print(f"Products per Partition (Batch Size): {batch_size}")
    print("-------------------------")

    df = pd.DataFrame({'product_id': range(1, num_products + 1)})
    products_to_process = df['product_id'].tolist()
    
    num_partitions = math.ceil(num_products / batch_size)
    
    rdd = sc.parallelize(products_to_process, num_partitions)
    print(f"RDD created with {rdd.getNumPartitions()} partitions.")

    print("\n🚀 Starting Map-Reduce job...")
    start_time = time.time()

    # mapPartitions runs 'process_partition' once per batch.
    # The 'reduce' step sums all the scores yielded from all partitions.
    total_score = rdd.mapPartitions(process_partition).reduce(lambda a, b: a + b)

    end_time = time.time()
    print("Job finished.")

    print("\n--- Job Results ---")
    print(f"Aggregated total score for all products: {total_score:,.2f}")
    print(f"Execution time: {end_time - start_time:.2f} seconds.")
    print("-------------------")

    sc.stop()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: spark-submit product_job.py <num_products> <batch_size>", file=sys.stderr)
        sys.exit(-1)
    
    try:
        num_products = int(sys.argv[1])
        batch_size = int(sys.argv[2])
        if num_products <= 0 or batch_size <= 0:
            raise ValueError("Inputs must be positive integers.")
    except ValueError:
        print("Error: <num_products> and <batch_size> must be positive integers.", file=sys.stderr)
        sys.exit(-1)
        
    main(num_products, batch_size)
