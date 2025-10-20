"""A Google Cloud Python Pulumi program"""

import pulumi
from pulumi_gcp import storage

bucket = storage.Bucket("intuneai-bucket", location="US")

pulumi.export("bucket_name", bucket.url)
