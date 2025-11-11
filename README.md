# SimpleBBS

## Get start

```shell
bundle install
cp .env.example .env
sqlite3 bbs.db < dbinit.sq3
```

## Run

```shell
bundle exec ruby simplebbs.rb
```

## misc

https://github.com/NixOS/templates/tree/master/ruby

```shell
nix flake init -t templates#ruby
```

```shell
nix-shell
```
