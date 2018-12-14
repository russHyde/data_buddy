from buddy.git_classes import ExternalRepository, \
    LocalRepository

from tests.unit_tests.data_for_tests import repo_data1, repo_data2


class TestExternalRepositoryClass(object):

    def test_init(self):
        path, commit, output = repo_data1()
        repo = ExternalRepository(
            path, commit, output
        )
        assert isinstance(repo, ExternalRepository)
        assert repo.input_path == path
        assert repo.commit == commit
        assert repo.output_path == output

    def test_object_equality(self):
        repo1 = ExternalRepository(*repo_data1())
        repo2 = ExternalRepository(*repo_data1())
        assert repo1 == repo1
        assert repo1 == repo2

    def test_object_inequality(self):
        repo1 = ExternalRepository(*repo_data1())
        repo2 = ExternalRepository(*repo_data2())
        assert repo1 != repo2


class TestLocalRepositoryClass(object):

    def test_init(self):
        path, commit, _ = repo_data1()
        repo = LocalRepository(path, commit)
        assert isinstance(repo, LocalRepository)
        assert repo.path == path
        assert repo.commit == commit
