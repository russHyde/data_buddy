import os, sys, subprocess


def conda_env_is_activated():
    return "CONDA_PREFIX" in os.environ


def conda_env_matches_expected(conda_prefix):
    return conda_env_is_activated() and os.environ["CONDA_PREFIX"] == conda_prefix


def python_matches_conda():
    return (
        conda_env_is_activated()
        and os.path.join(os.environ["CONDA_PREFIX"], "bin", "python") == sys.executable
    )


def rscript_matches_conda():
    if not conda_env_is_activated():
        return False

    expected_rscript = os.path.join(os.environ["CONDA_PREFIX"], "bin", "Rscript")
    which_rscript = subprocess.run(args=["which", "Rscript"], stdout=subprocess.PIPE)
    observed_rscript = which_rscript.stdout.decode("utf-8").strip()
    return expected_rscript == observed_rscript


def run_workflow(conda_prefix, is_r_required):
    assert conda_env_is_activated(), "project should be running in a conda environment"
    assert conda_env_matches_expected(
        conda_prefix
    ), "path to the conda environment should be {}".format(conda_prefix)
    assert python_matches_conda(), "`python` should be present in the conda environment"
    if is_r_required:
        assert (
            rscript_matches_conda()
        ), "`Rscript` should be present in the conda environment"
    return


if __name__ == "__main__":
    # TODO: add argparse command parser for
    # - conda-prefix [String]
    # - is-r-required [0/1]
    CONDA_PREFIX = sys.argv[1]
    IS_R_REQUIRED = bool(int(sys.argv[2]))
    run_workflow(CONDA_PREFIX, IS_R_REQUIRED)
