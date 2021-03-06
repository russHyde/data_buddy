import pytest
import sh

from buddy.validation_classes import get_md5sum
from tests.integration_tests.data_for_md5sum_tests import empty_md5

# user
# .. can compare the md5sum of a file to a reference


class TestMd5sum(object):
    def test_md5sum_for_existing_files(self, tmpdir):
        with sh.pushd(tmpdir):
            f_empty = "empty_file"
            f_non_empty = "non_empty_file"

            sh.touch(f_empty)
            with open(f_non_empty, "w") as f:
                print("some-data", file=f)

            assert isinstance(get_md5sum(f_empty), str)
            assert get_md5sum(f_empty) == empty_md5()
            assert get_md5sum(f_non_empty) != empty_md5()
        pass

    def test_md5sum_fails_for_file_objects(self, tmpdir):
        # user must provide a file-name, not a file-object
        with sh.pushd(tmpdir):
            f0 = open("file_name", mode="w")
            with pytest.raises(Exception):
                get_md5sum(f0)

    def test_md5sum_for_missing_file(self, tmpdir):
        # a file should exist for any file-name passed in
        with sh.pushd(tmpdir):
            f0 = "missing_file"
            with pytest.raises(FileNotFoundError):
                get_md5sum(f0)


class TestMd5sumOnBinaryFile(object):
    def test_md5sum_for_utf8_binary_file(self, tmpdir):
        with sh.pushd(tmpdir):
            f_binary = "binary_file"
            with open(f_binary, "wb") as f:
                f.write(b"\x0a\x1b\x2c")
                f.write(b"\x3d\x4e\x5f")
            # computed using md5sum at command line:
            # - might be better to compare the python result with subprocess.run(["md5sum", f_binary])
            assert get_md5sum(f_binary) == "76aa4e16e87c63faa6cb03fc5f7f17f9"

    def test_md5sum_for_latin1_binary_file(self, tmpdir):
        with sh.pushd(tmpdir):
            f_latin1 = "latin1_file"
            with open(f_latin1, "wb") as f:
                # acute-'e'
                f.write(u"abcd\xe91".encode("latin-1"))
                f.write(u"\x3d\x4e\x5f".encode("latin-1"))
            # computed using md5sum at command line
            assert get_md5sum(f_latin1) == "ddb57847096b82ccaf7d84a66c03584b"


class TestMd5sumOnSubsetOfFile(object):
    def test_comment_only_file_has_empty_md5sum(self, tmpdir):
        with sh.pushd(tmpdir):
            f_comment = "comment_file"
            with open(f_comment, mode="w") as f:
                print("# comment line", file=f)

            assert get_md5sum(f_comment, comment="#") == empty_md5()
