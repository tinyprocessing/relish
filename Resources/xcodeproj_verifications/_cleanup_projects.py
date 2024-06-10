#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sorts objects within all or just the modifed PBXProj files. Sorting objects reduces the number of insignificant
conflicts when working on Xcode project files.
"""

# Because of the large number of developers working together we want to reduce the number of possible merge conflicts in project
# files. One way conflicts can happen is when new files are added to a project, Xcode's default behavior inserts the entries in
# arbitrary order. This script helps to reduce conflicts primarily by sorting files deterministically, in alphabetical order.

import sys, os, logging
from argparse import ArgumentParser
from subprocess import run
from urllib.parse import urlparse

import xUnique
from xUnique import XUnique


def _list_all_pbxproj():
    """Lists all PBXProj files"""
    directories = [".", "platform/ios"]
    file_paths = set()
    for directory in directories:
        for dirpath, _, files in os.walk(directory):
            for file in files:
                if file.endswith(".pbxproj") and ".build" not in dirpath:
                    file_paths.add(os.path.join(dirpath, file))
    return file_paths


def _list_modified_pbxproj():
    """Call `git status --porcelain` to list only the modified PBXProj files"""
    file_paths = set(
        [
            l.strip()
            for l in run(
                ["git", "status", "--porcelain"],
                capture_output=True,
                universal_newlines=True,
            ).stdout.splitlines()
        ]
    )
    return {
        l.split(" ")[-1]
        for l in file_paths
        if l.startswith("M") and l.endswith(".pbxproj")
    }


def main(args):
    logging.basicConfig(
        level=args.loglevel or logging.INFO, format="%(levelname)s %(message)s"
    )

    pbxproj_paths = set()
    if args.files:
        pbxproj_paths = set(args.files)
    elif args.all:
        pbxproj_paths = _list_all_pbxproj()
    else:
        pbxproj_paths = set(_list_modified_pbxproj())


    root_directory = find_root_directory()
    if root_directory is None:
        print("Executing script outside of repository.")
        sys.exit(1)

    modified_pbxprojs = set()
    for pbxproj_path in pbxproj_paths:
        xunique = XUnique(pbxproj_path, False)
        xunique.sort_pbxproj(True)
        
        if xunique.is_modified:
            modified_pbxprojs.add(pbxproj_path)

    if args.throw and modified_pbxprojs:
        for modified_pbxproj in modified_pbxprojs:
            print("Modified: ", modified_pbxproj, file=sys.stderr)
        sys.exit(1)

def find_root_directory():
    current_directory = os.getcwd()
    print(current_directory)
    return current_directory

def find_directories_with_suffix(directory, suffix):
    directories = []
    for root, dirnames, _ in os.walk(directory):
        for dirname in dirnames:
            if dirname.endswith(suffix):
                directories.append(os.path.join(root, dirname))
    return directories

def get_last_path_component(url):
    parsed_url = urlparse(url)
    last_path_component = parsed_url.path.split('/')[-1]
    return last_path_component

if __name__ == "__main__":
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        "--all", "-a", help="Process all pbxproj files", action="store_true", dest="all"
    )
    parser.add_argument(
        "-t",
        "--throw",
        help="If set the script will fail if it made any changes",
        action="store_true",
        dest="throw",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        help="Verbose log information",
        const=logging.DEBUG,
        dest="loglevel",
        action="store_const",
    )
    parser.add_argument(
        '-f',
        '--files',
        help="A list of project file paths to sort.",
        nargs='+',
        dest="files",
        default=[]
    )

    # Patch xUnique's custom print functions, which can't be silenced
    # through class instantiation or options.
    xUnique.warning_print = lambda *args, **kwargs: None  # noop
    xUnique.success_print = lambda *args, **kwards: None  # noop

    main(parser.parse_args())
