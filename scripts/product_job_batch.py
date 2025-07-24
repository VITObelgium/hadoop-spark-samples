# product_job_batch.py
import sys
import time
import random
import math
from typing import List, Iterator, Dict, Any

import pandas as pd
from pyspark import SparkContext
from pyspark.rdd import RDD

def process_partition(iterator: Iterator[int]) -> Iterator[float]:
    """
    Processes an entire partition, demonstrating one-time initialization.
    The expensive setup runs only once for the entire batch of products.

    :param iterator: An iterator of product IDs for this partition.
    :return: A generator that yields calculated scores as floats.
    """
    # 1. Expensive, one-time initialization for the entire partition (batch).
    print("--- Initializing shared resources for partition... ---")
    time.sleep(2) # Simulate expensive model loading time
    
    # Pretend this is our loaded model or resource.
    model: Dict[str, Any] = {'type': 'classification_model', 'version': 1.5}
    print(f"--- Initialization complete. Model: {model} ---")

    # 2. Process each product in the batch using the single initialized resource.
    for product_id in iterator:
        # Simulate using the model on each product ID
        score: float = (product_id % 23) * random.uniform(0.9, 1.1) + model['version']
        
        # 'yield' makes this function a generator, which is memory-efficient.
        yield score

def main(num_products: int, batch_size: int) -> None:
    """
    Main Spark job to run a batched map-reduce operation.

    :param num_products: The total number of products to generate and process.
    :param batch_size: The number of products to group into a single partition/task.
    """
    sc: SparkContext = SparkContext(appName="BatchedInitProcessing")
    
    print("\n--- Job Configuration ---")
    print(f"Number of Products to process: {num_products}")
    print(f"Products per Partition (Batch Size): {batch_size}")
    print("-------------------------")

    df: pd.DataFrame = pd.DataFrame({'product_id': range(1, num_products + 1)})
    products_to_process: List[int] = df['product_id'].tolist()
    
    num_partitions: int = math.ceil(num_products / batch_size)
    
    rdd: RDD[int] = sc.parallelize(products_to_process, num_partitions)
    print(f"RDD created with {rdd.getNumPartitions()} partitions.")

    print("\n🚀 Starting Map-Reduce job...")
    start_time: float = time.time()

    # mapPartitions runs 'process_partition' once per batch.
    # The 'reduce' step sums all the scores yielded from all partitions.
    total_score: float = rdd.mapPartitions(process_partition).reduce(lambda a, b: a + b)

    end_time: float = time.time()
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
        num_products_arg: int = int(sys.argv[1])
        batch_size_arg: int = int(sys.argv[2])
        if num_products_arg <= 0 or batch_size_arg <= 0:
            raise ValueError("Inputs must be positive integers.")
    except ValueError:
        print("Error: <num_products> and <batch_size> must be positive integers.", file=sys.stderr)
        sys.exit(-1)
        
    main(num_products_arg, batch_size_arg)