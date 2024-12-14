#!/bin/bash
set -eu -o pipefail

# 標準エラー出力にメッセージを表示
eecho() { echo "$@" 1>&2; }

usage() {
  cat <<EOF
Usage:
  bash $(basename "$0") <python-version> <requirements-file>
Description:
  Create lambda layer zip file according to the requirements file.
Requirements:
  docker, jq
Arguments:
  python-version    : Python version
  requirements-file : Path of pip requirements file
EOF
}

# 引数の数を確認
if [[ $# != 2 ]]; then
  usage && exit 1
fi

PYTHON_VERSION=$1
REQUIREMENTS_FILE=$2

# requirements.txt の存在確認
if [[ ! -f ${REQUIREMENTS_FILE} ]]; then
  eecho "[ERROR] requirements file '${REQUIREMENTS_FILE}' not found."
  exit 1
fi

# 一時ディレクトリを作成
DEST_DIR=$(mktemp -d)

# requirements.txt を一時ディレクトリにコピー
cp "${REQUIREMENTS_FILE}" "${DEST_DIR}"

(
  # 作業ディレクトリを変更
  cd "${DEST_DIR}"
  mkdir python

  # Docker コンテナ内でパッケージをインストール
  docker run --rm -u "${UID}:${UID}" \
    -v "${DEST_DIR}:/work" \
    -w /work \
    "python:${PYTHON_VERSION}" pip install --no-cache-dir -r "${REQUIREMENTS_FILE##*/}" -t ./python >&2

  # 不要なファイルを削除
  find python \( -name '__pycache__' -o -name '*.dist-info' \) -type d -print0 | xargs -0 rm -rf
  rm -rf python/bin

  # JSON 形式で結果を出力
  jq -n --arg path "${DEST_DIR}" '{"path":$path}'
)
