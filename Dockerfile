FROM ruby:3.1.4
WORKDIR /debunker-api

RUN apt-get update && apt-get install -y \
    build-essential \
    postgresql-client

ENV DOCKERIZED true

COPY . .
RUN bundle config --global frozen 1 && bundle install

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3001

CMD ["bundle", "exec", "rails", "server", "-p", "3001", "-b", "0.0.0.0"]
