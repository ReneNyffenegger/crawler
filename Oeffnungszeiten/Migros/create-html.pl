#!/usr/bin/perl
use warnings;
use strict;

use lib '..';
use Oeffnungszeiten;

use utf8;

Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Migros/wgetted/*.html", 'Migros');
# Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Migros/wgetted/0024400.html", 'Migros');
