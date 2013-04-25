#!/bin/sh

(DATABASE=mysql2 bundle exec rake) &&
(DATABASE=sqlite bundle exec rake) &&
(DATABASE=postgres bundle exec rake)