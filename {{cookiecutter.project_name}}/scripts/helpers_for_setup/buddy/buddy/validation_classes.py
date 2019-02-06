import sys

import sh


class Md5sumValidator:

    def __init__(self, test_name, input_file, expected_md5sum):
        self.test_name = test_name
        self.input_file = input_file
        self.expected_md5sum = expected_md5sum

    def is_valid(self):
        return get_md5sum(self.input_file) == self.expected_md5sum


def get_md5sum(filepath):
    try:
        md5 = str(sh.md5sum(filepath)).strip().split()[0]
        return md5
    except Exception:
        raise
        sys.exit(1)