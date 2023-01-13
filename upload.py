#!/usr/bin/env python3

import mimetypes
import time
import os

import boto3
from botocore.config import Config
from dotenv import load_dotenv

load_dotenv()

out_dir = 'out'
bucket_name = 'www.chedygov.com'
region_name = 'us-west-2'

config = Config(region_name=region_name)
s3_client = boto3.client('s3', config=config)
cf_client = boto3.client('cloudfront', config=config)


def list_existing_objects():
    response = s3_client.list_objects_v2(Bucket=bucket_name)
    if response['KeyCount'] == 0:
        return []
    return [item['Key'] for item in response['Contents']]


def delete_objects(keys):
    if not keys:
        return
    s3_client.delete_objects(
        Bucket=bucket_name,
        Delete={
            'Objects': [{'Key': key} for key in keys],
        },
    )


def upload_file(file_path):
    key = os.path.basename(file_path)
    mime_type, _ = mimetypes.guess_type(file_path)
    s3_client.upload_file(
        file_path,
        bucket_name,
        key,
        ExtraArgs={'ContentType': mime_type},
    )


def get_output_filenames():
    output_filenames = []
    for root_path, dirnames, filenames in os.walk(out_dir):
        for filename in filenames:
            output_filenames.append(os.path.join(root_path, filename))
    return output_filenames


def upload_files(filenames):
    for filename in filenames:
        upload_file(filename)


def distribution_has_domain(distribution, domain):
    for item in distribution['Origins']['Items']:
        if item['DomainName'].startswith(domain):
            return True
    return False


def invalidate_cache():
    response = cf_client.list_distributions()
    distributions = response['DistributionList']['Items']
    distribution = [dist for dist in distributions if distribution_has_domain(dist, bucket_name)][0]
    dist_id = distribution['Id']
    cf_client.create_invalidation(
        DistributionId=dist_id,
            InvalidationBatch={
            'Paths': {
                'Quantity': 1,
                'Items': ['/*']
            },
            'CallerReference': str(time.time()),
        },
    )


def run():
    output_files = get_output_filenames()
    if not output_files:
        raise ValueError('No files in the output directory. Nothing to upload!')
    objects = list_existing_objects()
    delete_objects(objects)
    upload_files(output_files)
    invalidate_cache()


if __name__ == '__main__':
    run()
