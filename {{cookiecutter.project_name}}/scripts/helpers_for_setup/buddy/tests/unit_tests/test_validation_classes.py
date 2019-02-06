import buddy.validate_file_contents

from buddy.validation_classes import Md5sumValidator

# user
# .. can ensure the md5sum for a file matches a given value
#


class TestMd5sumValidatorConstruction(object):
    def test_can_construct_md5sum_validator(self):
        validator = Md5sumValidator(
            test_name="test1", input_file="some_file", expected_md5sum="a" * 32
        )
        assert isinstance(validator, Md5sumValidator)


class TestMd5sumValidatorMethods(object):
    def test_is_valid_detects_matching_md5sum(self, monkeypatch):
        def mock_return(filepath):
            return "a" * 32

        monkeypatch.setattr(buddy.validation_classes, "get_md5sum", mock_return)

        validator = Md5sumValidator(
            test_name="test1", input_file="some_file", expected_md5sum="a" * 32
        )

        assert validator.is_valid()

    def test_is_valid_detects_nonmatching_md5sum(self, monkeypatch):
        def mock_return(filepath):
            return "b" * 32

        monkeypatch.setattr(buddy.validation_classes, "get_md5sum", mock_return)

        validator = Md5sumValidator(
            test_name="test1", input_file="some_file", expected_md5sum="a" * 32
        )

        assert not validator.is_valid()
