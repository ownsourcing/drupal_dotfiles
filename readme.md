# Drupal dotfiles

## Introduction

This repository is intended for OS X users only and sets your [dotfiles], so that your terminal is optimised for the [Drupal] CMS.

[dotfiles]: http://en.wikipedia.org/wiki/Dot-file
[Drupal]: https://drupal.org/


## Installation / update

### Install

You can clone the repository wherever you want. (I like to keep it in `~/Projects/drupal_dotfiles`, with `~/drupal_dotfiles` as a symlink.) The bootstrapper script will pull in the latest version and copy the files to your home folder.

```bash
git clone https://github.com/willembressers/drupal_dotfiles.git && cd drupal_dotfiles && source bootstrap.sh
```

### Update

To update, `cd` into your local `drupal_dotfiles` repository and then:

```bash
source bootstrap.sh
```

Alternatively, to update while avoiding the confirmation prompt:

```bash
set -- -f; source bootstrap.sh
```

## Configuration

Add an `.extra` file to your home folder where you can make it more personal.

### .extra ###

This file is ignored from the repository so that you can personalize your Terminal.

```bash
# Define your Drupal root folder.
DRUPAL_ROOT="$HOME/Sites/d7"
```

## Thanks to…

* [Simon Owen](http://simonowendesign.co.uk/) and his [Setting Up a Mac Dev Machine From Zero to Hero With Dotfiles](http://net.tutsplus.com/tutorials/tools-and-tips/setting-up-a-mac-dev-machine-from-zero-to-hero-with-dotfiles)
* [Mathias Bynens](http://mathiasbynens.be/) and his [dotfiles repository](https://github.com/mathiasbynens/dotfiles)
