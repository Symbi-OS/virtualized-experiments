#!/bin/bash

set -x

$1 -y update
$1 -y install wget gcc flex make bison elfutils-libelf-devel bc hostname perl diffutils $2

