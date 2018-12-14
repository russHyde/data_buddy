import yaml

from buddy.git_classes import ExternalRepository


def read_repository_details(yaml_file):
    yaml_dict = yaml.load(open(yaml_file, 'r'))
    if yaml_dict is None:
        return {}
    else:
        return yaml_dict


def parse_repository_details(yaml_dictionary):
    repositories = {
        k: ExternalRepository(v['url'], v['commit'], v['output'])
        for k, v in yaml_dictionary.items()
    }
    return repositories


def import_repository_details(yaml):
    # read_repository_details()
    # parse_repository_details()
    return {}


def get_command_args():
    return {}


if __name__ == "__main__":
    pass
#    args = get_command_args()
#    repositories = import_repository_details(args.yaml)
#    for repo in repositories:
#        repo.clone()