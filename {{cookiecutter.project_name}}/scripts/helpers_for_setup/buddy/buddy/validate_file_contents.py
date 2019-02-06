import argparse
import sh
import sys


def get_md5sum(filepath):
    try:
        md5 = str(sh.md5sum(filepath)).strip().split()[0]
        return md5
    except Exception:
        raise
        sys.exit(1)


def parse_validator_details(yaml_dictionary):
    # each test is of the form {test_name: {key1: value1, key2: value2, ...}}
    # - To compare md5sum between a file and a string, one of the keys should be
    # `md5sum` and another should be `input_file`

    # For each validation test in the dictionary, return an object with a
    # `validate` method
    pass


def run_workflow(yaml_file):
    pass


def define_command_arg_parser():
    """
    Get a parser that extracts the command args used when calling this program
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("validate_yaml", nargs=1)
    return parser


if __name__ == "__main__":
    ARGS = define_command_arg_parser().parse_args()
    run_workflow(ARGS.validate_yaml[0])
