#!/bin/bash -x

launchctl unload /Users/oka_zzz/prg/stardigio/ruby-stardigio-tools/record.plist
launchctl load /Users/oka_zzz/prg/stardigio/ruby-stardigio-tools/record.plist
launchctl list jp.oka.record
