#!/usr/bin/env moon

serpent = require "serpent"

file = io.open arg[1]
content = file\read "*all"
file\close!

_, data = serpent.load content

total = 0

print "Nom, Menu, Simple, Sucré, Prix"

for k,v in pairs data
	price = v.menu * 2.3 + v.simple * 1 + v.sugary * 0.5

	print "#{v.name}, #{v.menu}, #{v.simple}, #{v.sugary}, #{price} €"

	total += price

print ",,,,#{total}"

