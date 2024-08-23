# ruby-node-browsers-with-misspell

`circleci/ruby:2.6.5-node-browsers` + `misspell` + specific `node` version

## Docker Image のビルド

https://github.com/icare-jp-oss/ruby-node-browsers-with-misspell の master ブランチへの push をトリガーに、docker hub で image がビルドされます。
また、`dev/` で始まるブランチ名でpushを行うと（多くの場合はプルリクエストの送信が該当します）、同様に docker hub で image がビルドされます。

## Docker Image のタグ

タグの付け方は何通りかあります。

1. master ブランチへのマージ...`latest` タグでイメージがビルドされます。
2. Github でタグを付与...付けたタグでイメージがビルドされます。`tag_name` と付けた場合、イメージ名のフルパスは `icarejposs/ruby-node-browsers-with-misspell:tag_name` となります。
3. `dev/branch_name` というブランチ名でプルリクエストを作成した場合...`branch_name-dev`のタグでイメージがビルドされます。イメージ名のフルパスは `icarejposs/ruby-node-browsers-with-misspell:branch_name-dev` となります。
