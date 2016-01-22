# Sasha's CV builder

This is the tool I use to generate the CV at [www.chedygov.com](http://www.chedygov.com/). It's a complete one-off tool that is not meant for general use, only for me.

To run, make a Python virtualenv and install the dependencies:

    pip install -r requirements.txt

Then:

    python builder.py data.yaml

To have the builder run any time any of the relevant files are changed:

    ./watch.sh

And that's it.

I suppose the "next steps" would be to generalize it and have it automatically upload the output to S3. Maybe add some testing, too. I doubt that's ever going to happen, though.
