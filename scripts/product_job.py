# product_job.py
import sys
import time
import random
from typing import List

import pandas as pd
from pyspark import SparkContext
from pyspark.rdd import RDD

def process_product(product_id: int) -> float:
    """
    Simulates a complex calculation for a single product.
    This function is called by .map() for each element in the RDD.

    :param product_id: The ID of the product to process.
    :return: The calculated score as a float.
    """
    # In a real remote sensing job, this could be running a land use
    # classification model on an image tile or performing atmospheric correction.
    processing_time = random.uniform(0.5, 2.0)
    time.sleep(processing_time)
    
    score: float = (product_id % 23) * random.uniform(0.9, 1.1)
    return score

def main(num_products: int) -> None:
    """
    Main Spark job to run a per-product parallelized map-reduce operation.

    :param num_products: The total number of products to generate and process.
    """
    sc: SparkContext = SparkContext(appName="PerProductMapReduce")
    
    print("\n--- Job Configuration ---")
    print(f"Number of Products to process: {num_products}")
    print("-------------------------")

    # 1. Data Generation
    df: pd.DataFrame = pd.DataFrame({'product_id': range(1, num_products + 1)})
    products_to_process: List[int] = df['product_id'].tolist()
    
    # 2. Parallelize: Create an RDD of integers
    rdd: RDD[int] = sc.parallelize(products_to_process, len(products_to_process))
    print(f"RDD created with {rdd.getNumPartitions()} partitions (one per product).")

    print("\n🚀 Starting Map-Reduce job...")
    start_time: float = time.time()

    # 3. Map-Reduce
    total_score: float = rdd.map(process_product).reduce(lambda a, b: a + b)

    end_time: float = time.time()
    print("Job finished.")

    print("\n--- Job Results ---")
    print(f"Aggregated total score for all products: {total_score:,.2f}")
    print(f"Execution time: {end_time - start_time:.2f} seconds.")
    print("-------------------")

    sc.stop()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: spark-submit product_job.py <num_products>", file=sys.stderr)
        sys.exit(-1)
    
    try:
        num_products_arg: int = int(sys.argv[1])
        if num_products_arg <= 0:
            raise ValueError("Input must be a positive integer.")
    except ValueError:
        print("Error: <num_products> must be a positive integer.", file=sys.stderr)
        sys.exit(-1)
        
    main(num_products_arg)