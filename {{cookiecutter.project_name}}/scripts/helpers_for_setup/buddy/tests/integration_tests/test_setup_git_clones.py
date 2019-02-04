import tempfile
import sh
import os

class TestCheckoutHead(object):

    def test_clone_git_repo(self):
        with tempfile.TemporaryDirectory() as temp_dir_name:
            repo = os.path.join(temp_dir_name, "my_repo")
            assert not os.path.isdir(repo)
            sh.git("init", repo)
            assert os.path.isdir(repo)

