FROM node:latest

RUN apt-get update && apt-get install nano -y

COPY ./src/ /opt/app

WORKDIR /opt/app

# Quick boolean to update database configs in order to ensure running app without docker works as well.
ENV IS_DOCKER=true

RUN npm install

# CMD [ "npm", "start" ]

CMD [ "npm", "run", "dev" ]
