import argparse


def setup_workflow(yaml_file):
    # yaml_dict = read_yaml(yaml_file)
    # validators = ValidationWorkflow.parse_validator_details(yaml_dict)
    # workflow = ValidationWorkflow(validators)
    # return workflow
    pass


def run_workflow(yaml_file):
    # workflow = setup_workflow(yaml_file)
    # report = workflow.get_failure_report()
    # print(report)
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
