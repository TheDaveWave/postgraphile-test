const express = require("express");
const { postgraphile } = require("postgraphile");
const preset = require("./graphile.config.mjs");

const PORT = process.env.PORT || 9000;

const app = express();

app.use(postgraphile(preset));

app.listen(PORT, () => {
    console.log(`Listening on port: ${PORT}`);
});