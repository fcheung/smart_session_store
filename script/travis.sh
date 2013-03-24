#!/bin/sh

(DATABASE=mysql2 bundle exec rake) &&
(DATABASE=sqlite bundle exec rake) &&
(DATABASE=postgresql bundle exec rake)