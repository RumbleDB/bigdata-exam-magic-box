# Exam Docker Magic Box

Docker setup for the Big Data exam: Jupyter (Spark, JSONiq, SQL), PostgreSQL and Adminer. Exercises are in the [course repository](https://github.com/RumbleDB/bigdata-exercises).

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with Compose 2.33+ (`docker compose version`)
- 6 GB RAM for Docker (8 GB recommended), 5 GB free disk

## Usage

1. Download the latest `bigdata-exam-magic-box-*.zip` from [Releases](../../releases) and unzip it.
2. `docker compose up -d`, then open [localhost:8888](http://localhost:8888).
3. `docker compose down` to stop.

Put exercise notebooks into `notebooks/`. To reset everything, including the database, run `./run.sh`.

**Updates** are automatic: `docker compose up` checks for a new image once a day. To update now: `docker compose pull && docker compose up -d`. No need to download the zip again.

---

## Maintainers

Git holds the image and tooling. Datasets (`notebooks/`, `db/`) are not in git; they ship in the release zip. Only `notebooks/Cheatsheet.ipynb` is in git.

**Image updates**
- Renovate opens immediate PRs for JSONiq / language server releases, groups routine updates weekly,
  and opens separate major-update PRs. Lock-file maintenance runs monthly. Merges are manual;
  CI builds and tests each PR on amd64 and arm64.
- Merging publishes `:latest` and `:YYYY.MM.DD-<sha>`.
- Python packages: edit the grouped dependencies in `jupyter/pyproject.toml`, then regenerate the lock:
  `cd jupyter && uv lock`. Commit both `pyproject.toml` and `uv.lock`.
- Renovate updates Python dependencies and regenerates `uv.lock` in the same PR.
  Docker exports each dependency group from `uv.lock` and installs `base` before `jsoniq`,
  so a JSONiq release only rebuilds the small JSONiq layer.
- Language server: `JSONIQ_LS_VERSION` in `jupyter/Dockerfile`.
- Python runtime: `jupyter/.python-version` pins the exact version installed by uv;
  Renovate updates it within Python 3.11. The image uses Node's Debian slim base and installs Java with apt.
- Test locally: `docker build -t exam-lab:test jupyter && tests/run.sh exam-lab:test`
- Check versions: `docker compose exec jupyter exam-lab-versions`

**Exams**
- Pin the image: in `docker-compose.yml`, replace `latest` in the Jupyter image with a version tag before building the zip.
- Roll back `latest`: `docker buildx imagetools create -t ghcr.io/rumbledb/bigdata-exam-magic-box:latest ghcr.io/rumbledb/bigdata-exam-magic-box:<good-tag>`

**New semester**
1. Overwrite `notebooks/Cheatsheet.ipynb`, commit and push.
2. Put the SQL dumps it needs into `db/`. Every `*.sql` there is loaded on first start, alphabetically.
3. Build and publish the zip. The release tag (`2027-spring`) also marks that semester's cheatsheet:
   ```sh
   scripts/make_release.sh 2027-spring
   gh release create 2027-spring dist/bigdata-exam-magic-box-2027-spring.zip --title "Exam lab 2027 Spring"
   ```

Past cheatsheets: `git show 2026-fall:notebooks/Cheatsheet.ipynb > old.ipynb` (any release tag).

**Repo moved?** Update the Jupyter image in `docker-compose.yml` (CI and `make_release.sh` check it) and ship a new zip.
