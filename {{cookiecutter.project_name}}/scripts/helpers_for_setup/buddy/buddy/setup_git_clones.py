import yaml


class Repository:
    # url, commit, output

    # check that len(commit) >= 7

    def __init__(self, url, commit, output):
        self.url = url
        self.commit = commit
        self.output = output

    def __eq__(self, other):
        return self.url == other.url and \
            self.commit == other.commit and \
            self.output == other.output

    def local_exists(self):
        pass

    def sha1_matches(self):
        pass

    def clone_into(self, directory):
        # TODO:
        # git clone from url to directory
        #
        # try:
        #   sh.git.clone(self.url, directory)
        # except sh.ErrorReturnCode as e:
        #   print(e)
        #   sys.exit(1)
        #
        pass

    def clone(self):
        # TODO:
        # check if output directory is occupied
        # if it is:
        # - check that the sha-1 hash matches the wanted commit
        #   and throw an exception if it doesn't
        # otherwise:
        # - check that the URL exists
        # - clone from the URL to a temp directory
        # - checkout the requested commit (throw exception if it
        #   doesn't exist)
        # - move from the temp directory to output
        pass


def read_repository_details(yaml_file):
    yaml_dict = yaml.load(open(yaml_file, 'r'))
    if yaml_dict is None:
        return {}
    else:
        return yaml_dict


def parse_repository_details(yaml_dictionary):
    repositories = {
        k: Repository(v['url'], v['commit'], v['output'])
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