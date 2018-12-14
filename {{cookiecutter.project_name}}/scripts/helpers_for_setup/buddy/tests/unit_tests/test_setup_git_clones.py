import os
from mock import mock_open, patch

from buddy.setup_git_clones import parse_repository_details,\
    read_repository_details
from buddy.git_classes import ExternalRepository

from tests.unit_tests.data_for_tests import repo_data1, repo_dict1,\
    repo_data2, repo_dict2, yaml_document


class TestParseRepositoryDetails(object):

    def test_empty_input(self):
        assert parse_repository_details({}) == {}

    def test_single_repository(self):
        repo_yaml = {
            'repo_name': repo_dict1()
        }
        assert parse_repository_details(repo_yaml) == {
            'repo_name': ExternalRepository(*repo_data1())
        }

    def test_multiple_repositories(self):
        repo_yaml = {
            'repo1': repo_dict1(),
            'repo2': repo_dict2()
        }
        assert parse_repository_details(repo_yaml) == {
            'repo1': ExternalRepository(*repo_data1()),
            'repo2': ExternalRepository(*repo_data2())
        }

    def test_malformed_repository_data(self):
        pass


class TestReadRepositoryDetails(object):

    @patch('builtins.open', new_callable=mock_open, read_data="")
    def test_empty_yaml(self, m):
        assert read_repository_details("some_file") == {}

    @patch('builtins.open', new_callable=mock_open, read_data=yaml_document())
    def test_valid_yaml(self, m):
        assert read_repository_details("some_file") == {
            'repo1': repo_dict1(),
            'repo2': repo_dict2()
        }

    def test_malformed_yaml(self):
        pass


class TestLocalExists(object):

    def test_when_local_is_absent(self, monkeypatch):
        def mock_return(path):
            return True
        monkeypatch.setattr(os.path, 'exists', mock_return)
        repo = ExternalRepository(*repo_data1())
        assert repo.local_exists()

    def test_when_local_is_present(self, monkeypatch):
        def mock_return(path):
            return False
        monkeypatch.setattr(os.path, 'exists', mock_return)
        repo = ExternalRepository(*repo_data1())
        assert not repo.local_exists()
