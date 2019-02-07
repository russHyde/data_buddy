class ValidationWorkflow:
    def __init__(self, validators):
        self.validators = validators

    def get_failing_validators(self):
        return {k: v for k, v in self.validators.items() if not v.is_valid()}

    def format_failure_report(self):
        def format_single_failure(validator):
            return "\t".join([
                "test_name:{}".format(validator.test_name),
                "test_type:{}".format(validator.test_type),
                "input_file:{}".format(validator.input_file)
            ])

        failures = self.get_failing_validators()
        return "\n".join(
            map(format_single_failure, failures.values())
        )
