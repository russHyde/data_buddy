import hashlib

import pytest
import sh

from buddy.validation_classes import get_md5sum

# user can compare the md5sum of a file to a reference


class TestMd5sum(object):
    def test_md5sum_for_existing_files(self, tmpdir):
        with sh.pushd(tmpdir):
            empty_string_md5 = hashlib.md5("".encode("utf-8")).hexdigest()

            f_empty = "empty_file"
            f_non_empty = "non_empty_file"

            sh.touch(f_empty)
            with open(f_non_empty, "w") as f:
                print("some-data", file=f)

            assert isinstance(get_md5sum(f_empty), str)
            assert get_md5sum(f_empty) == empty_string_md5
            assert get_md5sum(f_non_empty) != empty_string_md5
        pass

    def test_md5sum_for_missing_file(self, tmpdir):
        with sh.pushd(tmpdir):
            f0 = "missing_file"
            with pytest.raises(Exception):
                get_md5sum(f0)