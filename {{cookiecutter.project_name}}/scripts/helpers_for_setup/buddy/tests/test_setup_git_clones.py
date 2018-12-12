from mock import mock_open, patch

from buddy.setup_git_clones import Repository,\
    parse_repository_details, \
    read_repository_details


def repo_data1():
    return 'https://some_url.org', 'a1b2c3d', './store/me/here/repo_name'


def repo_dict1():
    return dict(zip(['url', 'commit', 'output'], repo_data1()))


def repo_data2():
    return 'git@github.com:user/my_package.git', 'zyx9876', 'my_local_package'


def repo_dict2():
    return dict(zip(['url', 'commit', 'output'], repo_data2()))


def yaml_document():
    return """
    repo1:
        url: https://some_url.org
        commit: a1b2c3d
        output: ./store/me/here/repo_name
    repo2:
        url: git@github.com:user/my_package.git
        commit: zyx9876
        output: my_local_package
    """


class TestRepositoryClass(object):

    def test_init(self):
        url, commit, output = repo_data1()
        repo = Repository(
            url=url, commit=commit, output=output
        )
        assert isinstance(repo, Repository)
        assert repo.url == url
        assert repo.commit == commit
        assert repo.output == output

    def test_object_equality(self):
        url, commit, output = repo_data1()
        repo1 = Repository(
            url=url, commit=commit, output=output
        )
        repo2 = Repository(*repo_data1())
        assert repo1 == repo1
        assert repo1 == repo2

    def test_object_inequality(self):
        repo1 = Repository(*repo_data1())
        repo2 = Repository(*repo_data2())
        assert repo1 != repo2


class TestParseRepositoryDetails(object):

    def test_empty_input(self):
        assert parse_repository_details({}) == {}

    def test_single_repository(self):
        url, commit, output = repo_data1()
        repo_yaml = {
            'repo_name': {'url': url, 'commit': commit, 'output': output}
        }
        assert parse_repository_details(repo_yaml) == {
            'repo_name': Repository(*repo_data1())
        }

    def test_multiple_repositories(self):
        url1, commit1, output1 = repo_data1()
        url2, commit2, output2 = repo_data2()
        repo_yaml = {
            'repo1': {'url': url1, 'commit': commit1, 'output': output1},
            'repo2': {'url': url2, 'commit': commit2, 'output': output2}
        }
        assert parse_repository_details(repo_yaml) == {
            'repo1': Repository(*repo_data1()),
            'repo2': Repository(*repo_data2())
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
