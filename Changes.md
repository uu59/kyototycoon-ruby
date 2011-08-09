## v0.6.0

* added KyotoTycoon::Cursor for cursor support
* always close socket at script exit

## v0.5.6

* fixed for ruby 1.8.7

## v0.5.5

* fixed bulk methods. [Thanks rickyrobinson!](https://github.com/uu59/kyototycoon-ruby/pull/1/files)

## v0.5.4

* Added bin/kyototycoon-console. it's like as Sequel's `sequel` script

## v0.5.3

* fixed bug using base64 encoding
* regenerate socket when that closed

## v0.5.2

* fixed encoded response handling
* fixed miss named method

## v0.5.1

* changing server dicision logic
* added KT::Stream.run

## v0.5.0

* Always Keep-Alive connection
* remove Tsvrpc::Nethttp, and KT#agent=
* default KT#colenc = :B (Base64)
* modified benchmark/*.rb

## v0.1.2

* added KT#configure, KT#create
* added KT#incr, KT#decr, KT#decrement
* rspec connect to localhost:19999 for safety

## v0.1.1

* fixed always xt=0

## v0.1.0

* first release
