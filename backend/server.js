const express = require("express");
const cors = require("cors");
require("dotenv").config();

const db = require("./db");

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Database connection test
app.get("/db-test", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT 1 AS result");

    res.status(200).json({
      status: "UP",
      database: "MySQL",
      result: rows[0].result
    });
  } catch (error) {
    console.error("Database error:", error.message);

    res.status(500).json({
      status: "DOWN",
      message: error.message
    });
  }
});

// Health Check
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "UP",
    message: "E-Commerce Backend is running"
  });
});

// Root
app.get("/", (req, res) => {
  res.json({
    message: "E-Commerce API",
    version: "1.0.0"
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Get all products
app.get("/api/products", async (req, res) => {
  try {
    const [products] = await db.query(
      "SELECT * FROM products ORDER BY created_at DESC"
    );

    res.status(200).json(products);
  } catch (error) {
    console.error("Products error:", error.message);

    res.status(500).json({
      status: "ERROR",
      message: "Failed to fetch products"
    });
  }
});
// Create a new product
app.post("/api/products", async (req, res) => {
  try {
    const { name, description, price, stock, image_url } = req.body;

    const [result] = await db.query(
      `INSERT INTO products
       (name, description, price, stock, image_url)
       VALUES (?, ?, ?, ?, ?)`,
      [name, description, price, stock, image_url]
    );

    res.status(201).json({
      message: "Product created successfully",
      productId: result.insertId
    });
  } catch (error) {
    console.error("Create product error:", error.message);

    res.status(500).json({
      status: "ERROR",
      message: "Failed to create product"
    });
  }
});
// Update a product
app.put("/api/products/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price, stock, image_url } = req.body;

    const [result] = await db.query(
      `UPDATE products
       SET name = ?, description = ?, price = ?, stock = ?, image_url = ?
       WHERE id = ?`,
      [name, description, price, stock, image_url, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        status: "ERROR",
        message: "Product not found"
      });
    }

    res.status(200).json({
      message: "Product updated successfully"
    });
  } catch (error) {
    console.error("Update product error:", error.message);

    res.status(500).json({
      status: "ERROR",
      message: "Failed to update product"
    });
  }
});
// Delete a product
app.delete("/api/products/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await db.query(
      "DELETE FROM products WHERE id = ?",
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        status: "ERROR",
        message: "Product not found"
      });
    }

    res.status(200).json({
      message: "Product deleted successfully"
    });
  } catch (error) {
    console.error("Delete product error:", error.message);

    res.status(500).json({
      status: "ERROR",
      message: "Failed to delete product"
    });
  }
});
