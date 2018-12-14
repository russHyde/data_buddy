import os


class LocalRepository:

    def __init__(self, path, commit):
        self.path = path
        self.commit = commit


class ExternalRepository:
    # input_path (ie, url or file-path), commit, output_path (local file-path)

    # check that len(commit) >= 7

    def __init__(self, input_path, commit, output_path):
        self.input_path = input_path
        self.commit = commit
        self.output_path = output_path

    def __eq__(self, other):
        return self.input_path == other.input_path and \
               self.commit == other.commit and \
               self.output_path == other.output_path

    def local_exists(self):
        return os.path.exists(self.output_path)

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