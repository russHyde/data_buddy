from buddy.validate_file_contents import parse_validator_details
from buddy.validation_classes import Md5sumValidator

# ----

# user
# .. can import validation-test definitions from a .yaml file
# .. can ensure two files have row-subset-matching values
# .. can ensure two files have column-subset-matching values
# .. can ensure two files have matching values

# program
# .. ensures that validation-test definitions conform to a schema
# .. can convert free-text definition of validation-test into Validator objects

# ----


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
        validators = parse_validator_details(yaml_dict)

        assert all(map(lambda x: isinstance(x, Md5sumValidator), validators.values()))
        assert validators == expected_validators
