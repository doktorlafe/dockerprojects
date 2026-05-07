#!/bin/bash

# Generování SSL certifikátů
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx.key \
  -out nginx.crt \
  -subj "/C=CZ/ST=State/L=City/O=Org/CN=localhost"
