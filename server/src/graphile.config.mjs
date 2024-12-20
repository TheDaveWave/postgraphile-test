import { PostGraphileAmberPreset } from "postgraphile/presets/amber";
import { makePgService } from "postgraphile/adaptors/pg";

/** @type {GraphileConfig.Preset} */
const preset = {
  extends: [PostGraphileAmberPreset],
  pgServices: [makePgService({ connectionString: "postgres://postgres:postgres@localhost:5432/bublr" })],
  grafserv: { watch: true },
};

export default preset;