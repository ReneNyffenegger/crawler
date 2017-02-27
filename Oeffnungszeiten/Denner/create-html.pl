#!/usr/bin/perl
use warnings;
use strict;

use lib '..';
use Oeffnungszeiten;

use utf8;

Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Denner/wgetted/*.html", 'Denner');
