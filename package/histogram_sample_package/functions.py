from pystac_client import Client
import rasterio
import numpy as np


def histogram(image_file: str):
    """Calculates the histogram for a given (single band) image file."""

    with rasterio.open(image_file) as src:
        band = src.read()

    hist, _ = np.histogram(band, bins=256)
    return hist


def ndvi_files(collection: str, start_date: str, end_date: str,
               min_lon: float, max_lon: float, min_lat: float, max_lat: float):
    """Uses the Terrascope STAC API to return a list of NDVI cog products
    specified by a combination of collection id, time window and bounding box.

    The Terrascope STAC Items contain an alternate href which points to the mounted product file in the cluster.
    See https://docs.terrascope.be/Developers/WebServices/TerraCatalogue/STACAPI.html for more information.
    """

    catalog = Client.open('https://stac.terrascope.be/')

    stac_items = catalog.search(
        collections=[collection],
        datetime=[start_date, end_date],
        bbox=[min_lon, min_lat, max_lon, max_lat]
    ).items()

    return [item.assets.get('NDVI').extra_fields.get('alternate').get('local').get('href') for item in stac_items]