#!/usr/bin/env python3

from datetime import date
import logging
import os
import shutil
import subprocess
import sys

import jinja2
from markdown import markdown
import yaml


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

out_dir = 'out'
public_dir = 'public'


def build(data_file_name):
    """Loads the data in the file given by `data_file_name` and builds
       the CV."""
    clean_output()
    os.makedirs(out_dir, exist_ok=True)
    with open(data_file_name) as f:
        data = yaml.load(f, Loader=yaml.CLoader)
        data['last_updated'] = get_current_date()
        build_html(data)
    build_css(['style.less'])
    copy_public_files()
    logger.info('Successfully built CV')


def clean_output():
    for root_path, dirs, files in os.walk(out_dir):
        for d in dirs:
            shutil.rmtree(os.path.join(root_path, d))
        for f in files:
            os.unlink(os.path.join(root_path, f))


def build_html(data):
    """Renders templates with the data and writes the output HTML file."""
    rendered = render_template('index.html', **data)
    out_path = os.path.join(out_dir, 'index.html')
    with open(out_path, 'w') as out_file:
        out_file.write(rendered)


def build_css(file_names):
    """Compiles all LESS files in `file_names` into CSS files with
       the same name."""
    for file_name in file_names:
        css_file_name = '.'.join(file_name.split('.')[:-1]) + '.css'
        css_file_path = os.path.join(out_dir, css_file_name)
        which_ret = subprocess.run(['which', 'lessc'], capture_output=True)
        lessc_path = which_ret.stdout.rstrip(b'\n')
        subprocess.run([lessc_path, file_name, css_file_path])


def copy_public_files():
    for root_path, dirs, files in os.walk(public_dir):
        for f in files:
            shutil.copyfile(os.path.join(root_path, f), os.path.join(out_dir, f))


def render_template(file_name, *args, **kwargs):
    """Renders the template at `file_name` given the arguments as
       data. Returns the rendered template."""
    loader = jinja2.FileSystemLoader(searchpath='.')
    env = jinja2.Environment(loader=loader)
    env.globals = {'render_text': render_text}
    template = env.get_template(file_name)
    return template.render(*args, **kwargs)


def render_text(text):
    """A helper function for rendering blocks of text (like job
       descriptions) using Markdown."""
    return markdown(text)


def get_current_date():
    return date.today().strftime('%Y-%m-%d')


if __name__ == '__main__':
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
    )
    data_file_name = sys.argv[1]
    build(data_file_name)
