# Sasha's CV builder

This is the tool I use to generate the CV at [www.chedygov.com](http://www.chedygov.com/). It's a complete one-off tool that is not meant for general use, only for me.

### Setup

Make a Python virtualenv and install the dependencies:

```sh
$ pip install -r requirements.txt
```

You must also [install LESS](https://lesscss.org/usage/) so that `lessc` is available in your path.

### Building the site

```sh
$ ./builder.py data.yaml
```

The output goes into the `out/` directory. To have the builder run any time any of the input files are changed:

```sh
$ ./watch.sh
```

### Copying to S3

Copy `sample.env` to `.env` and input your AWS credentials. (Alternatively, log in through the AWS CLI.) After building, to upload the output files to an S3 bucket, run:

```sh
$ ./upload.py
```
