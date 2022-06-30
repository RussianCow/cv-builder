#!/usr/bin/env python3

import mimetypes
import os

import boto3
from botocore.config import Config
from dotenv import load_dotenv

load_dotenv()

out_dir = 'out'
bucket_name = 'www.chedygov.com'
region_name = 'us-west-2'

config = Config(region_name=region_name)
client = boto3.client('s3', config=config)


def list_existing_objects():
    response = client.list_objects_v2(Bucket=bucket_name)
    if response['KeyCount'] == 0:
        return []
    return [item['Key'] for item in response['Contents']]


def delete_objects(keys):
    if not keys:
        return
    client.delete_objects(
        Bucket=bucket_name,
        Delete={
            'Objects': [{'Key': key} for key in keys],
        },
    )


def upload_file(file_path):
    key = os.path.basename(file_path)
    mime_type, _ = mimetypes.guess_type(file_path)
    client.upload_file(
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


def run():
    output_files = get_output_filenames()
    if not output_files:
        raise ValueError('No files in the output directory. Nothing to upload!')
    objects = list_existing_objects()
    delete_objects(objects)
    upload_files(output_files)


if __name__ == '__main__':
    run()
