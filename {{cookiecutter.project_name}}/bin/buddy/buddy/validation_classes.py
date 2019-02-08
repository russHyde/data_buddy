import os
import sh


class Md5sumValidator:
    def __init__(self, test_name, input_file, expected_md5sum):
        self.test_name = test_name
        self.input_file = input_file
        self.expected_md5sum = expected_md5sum
        self.test_type = "md5sum"

    def is_valid(self):
        return get_md5sum(self.input_file) == self.expected_md5sum

    def __eq__(self, other):
        return (
            self.test_name == other.test_name
            and self.input_file == other.input_file
            and self.expected_md5sum == other.expected_md5sum
        )


def get_md5sum(filepath):
    try:
        md5 = str(sh.md5sum(filepath)).strip().split()[0]
        return md5
    except sh.ErrorReturnCode:
        if isinstance(filepath, str) and not os.path.isfile(filepath):
            raise FileNotFoundError(filepath)
        else:
            raise
