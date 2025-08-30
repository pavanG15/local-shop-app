import express from "express";
import uploadHandler from "./api/upload-cloudinary-image.js";
import deleteHandler from "./api/delete-cloudinary-image.js";

const app = express();
app.use(express.json({ limit: "10mb" }));

app.post("/api/upload-cloudinary-image", uploadHandler);
app.post("/api/delete-cloudinary-image", deleteHandler);

app.listen(3000, () => {
  console.log("Local API running → http://localhost:3000");
});
