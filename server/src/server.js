const express = require("express");
const { postgraphile } = require("postgraphile");

const PORT = process.env.PORT || 9000;

const app = express();

const DB_URL = "postgres://postgres@localhost:5432/bublr"

const postgraphileOpts = {
    subscriptions: true,
    watchPg: true,
    dynamicJson: true,
    setofFunctionsContainNulls: false,
    ignoreRBAC: false,
    showErrorStack: "json",
    extendedErrors: ["hint", "detail", "errcode"],
    appendPlugins: [require("@graphile-contrib/pg-simplify-inflector")],
    exportGqlSchemaPath: "schema.graphql",
    graphiql: true,
    enhanceGraphiql: true,
    allowExplain(req) {
        // TODO: customise condition!
        return true;
    },
    enableQueryBatching: true,
    legacyRelations: "omit",
    pgSettings(req) {
        /* TODO */
    },
}

app.use(
    postgraphile(
        DB_URL,
        "public",
        postgraphileOpts
    )
);

app.listen(PORT, () => {
    console.log(`Listening on port: ${PORT}`);
});