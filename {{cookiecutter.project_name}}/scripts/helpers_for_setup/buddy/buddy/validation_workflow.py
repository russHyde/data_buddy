class ValidationWorkflow:
    def __init__(self, validators):
        self.validators = validators

    def get_failing_validators(self):
        return {k: v for k, v in self.validators.items() if not v.is_valid()}

    #def format_report(self):
    #    pass