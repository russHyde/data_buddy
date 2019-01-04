"""
Functions for identifying which git repos need to be cloned for the current
project, and for cloning them
"""

import yaml

from buddy.git_classes import ExternalRepository


def read_repository_details(yaml_file):
    """
    Reads all data stored in a yaml file; returns a dictionary storing the
    key-value pairs within the file
    """
    yaml_dict = yaml.load(open(yaml_file, "r"))
    if yaml_dict is None:
        return {}
    return yaml_dict


def parse_repository_details(yaml_dictionary):
    """
    Extracts details of git repositories: where are they stored, where are they
    to be copied, which commit should be checked out?
    """
    repositories = {
        k: ExternalRepository(v["url"], v["commit"], v["output"])
        for k, v in yaml_dictionary.items()
    }
    return repositories


def import_repository_details(yaml_file):
    """
    Reads and extracts repository information from a yaml file
    """
    # yaml_dict = read_repository_details(yaml_file)
    # return parse_repository_details(yaml_dict)
    return {}


def get_command_args():
    """
    Extract command args that were used when calling this program
    """
    return {}


if __name__ == "__main__":
    pass
#    args = get_command_args()
#    repositories = import_repository_details(args.yaml)
#    for repo in repositories:
#        repo.clone()
