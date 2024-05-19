#!/bin/bash -xv

# ffmpegを使用してHDRからSDRへの変換を行う
# 指定フォルダにあるHDR動画ファイルをSDRに変換する
# Usage: hdr2sdr.sh input_folder

# 変数
tmp=$(mktemp)

# 対象フォルダを引数から取得
input_folder=$1
output_folder="$1/sdr"
backup_folder="$1/hdr"

# フォルダが存在しないならエラー
if [ ! -d "$input_folder" ]; then
  echo "Error: $input_folder is not a directory"
  exit 1
fi

# 出力フォルダが存在しないなら作成
if [ ! -d "$output_folder" ]; then
  mkdir "$output_folder"
fi

# バックアップフォルダが存在しないなら作成
if [ ! -d "$backup_folder" ]; then
  mkdir "$backup_folder"
fi

# 対象ファイルの一覧を取得し
find "$input_folder" -maxdepth 1 -type f -name "*.mp4" |

# mp4ファイルのうち、Pixel7で撮影されたファイルだけを抽出
while read file; do
  ffprobe "$file" 2>&1 |
  grep -q "arib-std-b67"
  if [ $? -eq 0 ]; then
    echo "$file"
  fi
done > $tmp-filelist

# 対象ファイルをHDRからSDRへ変換し、別フォルダにコピー
cat $tmp-filelist |
while read file; do
  # 出力ファイル名を生成
  output_file="$output_folder/$(basename $file)"
  # 変換実行
  ffmpeg -hide_banner -nostdin -y -i $file -vf "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p" -c:v libx264 "$output_file"

  # 変換が成功したらバックアップフォルダに移動
  if [ $? -eq 0 ]; then
    mv "$file" "$backup_folder"
  fi
done

# 一時ファイルを削除
rm -rf $tmp

