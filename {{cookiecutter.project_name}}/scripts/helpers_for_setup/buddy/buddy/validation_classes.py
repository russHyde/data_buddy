from buddy.validate_file_contents import get_md5sum


class Md5sumValidator:

    def __init__(self, test_name, input_file, md5_expected):
        self.test_name = test_name
        self.input_file = input_file
        self.md5_expected = md5_expected

    def is_valid(self):
        return get_md5sum(self.input_file) == self.md5_expected