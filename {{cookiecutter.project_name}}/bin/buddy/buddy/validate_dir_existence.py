import errno
import os
import os.path

from buddy.file_utils import read_yaml


def run_workflow(yaml_path):
    """
    Checks that every directory mentioned in the yaml file is really a
    directory

    :param yaml_path: a file-path
    :return:
    """
    dirs = read_yaml(yaml_path)
    for d in dirs:
        if not os.path.isdir(d):
            raise FileNotFoundError(
                errno.ENOENT, os.strerror(errno.ENOENT), d
            )


def define_command_arg_parser():
    """
    Get a parser that extracts the command args used when calling this program
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("required_dirs_yaml", nargs=1)
    return parser


# ---- run as a script

if __name__ == "__main__":
    ARGS = define_command_arg_parser().parse_args()
    run_workflow(ARGS.required_dirs_yaml[0])