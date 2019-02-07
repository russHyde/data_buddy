from buddy.validation_classes import Md5sumValidator


class ValidationWorkflow:
    def __init__(self, validators):
        self.validators = validators

    def get_failing_validators(self):
        return {k: v for k, v in self.validators.items() if not v.is_valid()}

    def format_failure_report(self):
        def format_single_failure(validator):
            return "\t".join(
                [
                    "test_name:{}".format(validator.test_name),
                    "test_type:{}".format(validator.test_type),
                    "input_file:{}".format(validator.input_file),
                ]
            )

        failures = self.get_failing_validators()
        return "\n".join(map(format_single_failure, failures.values()))

    @staticmethod
    def parse_validator_details(yaml_dictionary):
        # each test is of the form {test_name: {key1: value1, key2: value2, ...}}
        # - To compare md5sum between a file and a string, one of the keys should be
        # `md5sum` and another should be `input_file`

        # For each validation test in the dictionary, return an object with a
        # `validate` method
        validators = {
            k: Md5sumValidator(
                input_file=v["input_file"],
                test_name=k,
                expected_md5sum=v["expected_md5sum"],
            )
            for k, v in yaml_dictionary.items()
        }

        return validators
