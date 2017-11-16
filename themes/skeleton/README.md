# Skeleton for Hugo
This is [Hugo](//gohugo.io/) theme for developers. Use it to make your own theme.


## Installation
```sh
# This will add repository as a submodule to your site’s repository.
$ git submodule add https://github.com/channprj/hugo-skeleton themes/skeleton

# Now, you will have to pull the theme.
$ git submodule init
$ git submodule update

# That’s all, Skeleton is ready to be used. Happy Coding!
```

## Configuration
> Work in Progress... Sample `config.toml` will be uploaded.

Open `config.toml` in the base of the Hugo site and ensure the theme option is set to `skeleton`.

```toml
...
theme = "skeleton"
...
```

Skeleton uses `TOML` as default, but you can also use `YAML` or `JSON`. If you need more information, [Configuration Guide](https://gohugo.io/getting-started/configuration/) would be helpful.

For more information, Read the official [Setup Guide](https://gohugo.io/overview/installing/) of Hugo.

## Contributing
Have you found a bug or got an idea for a new feature? Feel free to use the [issue tracker](https://github.com/channprj/hugo-skeleton/issues) to let me know. Or make directly a [pull request](https://github.com/channprj/hugo-skeleton/pulls).

## License

This theme is released under the [MIT](https://github.com/channprj/hugo-skeleton/blob/master/LICENSE).
