import buddy

from buddy.validation_workflow import ValidationWorkflow
from buddy.validation_classes import Md5sumValidator


def single_md5sum_validator():
    return {
        "my_test": Md5sumValidator(
            input_file="some_file", test_name="my_test", expected_md5sum="a" * 32
        )
    }


class TestValidationWorkflowConstruction(object):
    def test_trivial_workflow_constructor(self):
        validator_dict = {}
        workflow = ValidationWorkflow(validator_dict)
        assert isinstance(workflow, ValidationWorkflow)
        assert validator_dict == workflow.validators

    def test_validation_workflow_constructor(self):
        validator_dict = single_md5sum_validator()
        workflow = ValidationWorkflow(validator_dict)
        assert isinstance(workflow, ValidationWorkflow)
        assert validator_dict == workflow.validators


class TestGetFailingValidators(object):
    def test_no_validators_means_no_failures(self):
        validator_dict = {}
        workflow = ValidationWorkflow(validator_dict)
        assert {} == workflow.get_failing_validators()

    def test_all_passing_validators_means_no_failures(self, monkeypatch):
        def mock_md5sum(filepath):
            return "a" * 32

        monkeypatch.setattr(buddy.validation_classes, "get_md5sum", mock_md5sum)

        validator_dict = single_md5sum_validator()
        workflow = ValidationWorkflow(validator_dict)
        assert {} == workflow.get_failing_validators()

    def test_all_failing_validators(self, monkeypatch):
        def mock_md5sum(filepath):
            return "b" * 32

        monkeypatch.setattr(buddy.validation_classes, "get_md5sum", mock_md5sum)

        validator_dict = single_md5sum_validator()
        workflow = ValidationWorkflow(validator_dict)
        assert validator_dict == workflow.get_failing_validators()


class TestValidationReportFormatting(object):
    def test_all_passing_means_no_report(self, monkeypatch):
        # returns a string
        # lines are of form "test_name:XYZ\ttest_type:md5sum\tinput_file:ABC"
        def mock_md5sum(filepath):
            return "a" * 32

        monkeypatch.setattr(buddy.validation_classes, "get_md5sum", mock_md5sum)

        validator_dict = single_md5sum_validator()
        workflow = ValidationWorkflow(validator_dict)
        assert "" == workflow.format_failure_report()

    def test_all_failing_gives_report(self, monkeypatch):
        def mock_md5sum(filepath):
            return "b" * 32

        monkeypatch.setattr(buddy.validation_classes, "get_md5sum", mock_md5sum)

        validator_dict = single_md5sum_validator()
        workflow = ValidationWorkflow(validator_dict)
        report = "\t".join(
            ["test_name:my_test", "test_type:md5sum", "input_file:some_file"]
        )
        assert report == workflow.format_failure_report()


class TestParseValidatorDetails(object):
    def test_md5sum_validators_can_be_parsed(self):
        yaml_dict = {
            "test1": {"input_file": "some_file", "expected_md5sum": "a" * 32},
            "test2": {"input_file": "another_file", "expected_md5sum": "b" * 32},
        }

        expected_validators = {
            "test1": Md5sumValidator(
                test_name="test1", input_file="some_file", expected_md5sum="a" * 32
            ),
            "test2": Md5sumValidator(
                test_name="test2", input_file="another_file", expected_md5sum="b" * 32
            ),
        }
        validators = ValidationWorkflow.parse_validator_details(yaml_dict)

        assert all(map(lambda x: isinstance(x, Md5sumValidator), validators.values()))
        assert validators == expected_validators
