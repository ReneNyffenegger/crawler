#!/usr/bin/perl
use warnings;
use strict;

use lib '..';
use Oeffnungszeiten;

use utf8;

  Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Post/wgetted/*.html", 'Post');
# Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Post/wgetted/001PST_001102036.html", 'Post');
# Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Post/wgetted/001PST_001102038.html", 'Post');
# Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Post/wgetted/001PST_001103648.html", 'Post');
# Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Post/wgetted/001PST_001102044.html", 'Post');
