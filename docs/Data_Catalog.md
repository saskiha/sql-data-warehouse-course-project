# Data Catalog – Gold Layer

## Overview

The Gold Layer represents the business-ready level of the data warehouse. It is designed to support analytical and reporting activities by providing structured data through **dimension tables** and **fact tables**.

This data catalog documents the tables and attributes implemented in the Gold Layer as part of my SQL training project.

> **Attribution:**
> This project is based on the **SQL Data Warehouse Project by Data With Baraa**, which served as the foundation for my SQL training. The original project concept and learning materials were created by Data With Baraa.
>
> **Original Project:**
> https://github.com/DataWithBaraa/sql-data-warehouse-project

---

## 1. `gold.dim_customers`

### Purpose

The `dim_customers` table contains customer-related information and combines personal, demographic, and geographic attributes to provide a comprehensive view of each customer.

### Columns

| Column Name       | Data Type    | Description                                                                                         |
| ----------------- | ------------ | --------------------------------------------------------------------------------------------------- |
| `customer_key`    | INT          | Surrogate key used to uniquely identify a customer record within the dimension table.               |
| `customer_id`     | INT          | Numeric identifier assigned to the customer in the source system.                                   |
| `customer_number` | NVARCHAR(50) | Alphanumeric customer reference used to identify and track the customer.                            |
| `first_name`      | NVARCHAR(50) | First name of the customer as stored in the source data.                                            |
| `last_name`       | NVARCHAR(50) | Family name or surname of the customer.                                                             |
| `country`         | NVARCHAR(50) | Country associated with the customer's place of residence.                                          |
| `marital_status`  | NVARCHAR(50) | Marital status recorded for the customer, such as `Married` or `Single`.                            |
| `gender`          | NVARCHAR(50) | Gender information available for the customer, including values such as `Male`, `Female`, or `n/a`. |
| `birthdate`       | DATE         | Date of birth of the customer, stored in date format.                                               |
| `create_date`     | DATETIME     | Date and time on which the customer record was created in the source system.                        |

---

## 2. `gold.dim_products`

### Purpose

The `dim_products` table provides descriptive information about the products available in the business. It contains product identifiers, classifications, attributes, pricing information, and product availability dates.

### Columns

| Column Name            | Data Type    | Description                                                                                             |
| ---------------------- | ------------ | ------------------------------------------------------------------------------------------------------- |
| `product_key`          | INT          | Surrogate key used to uniquely identify a product record within the product dimension.                  |
| `product_id`           | INT          | Numeric identifier assigned to the product in the source system.                                        |
| `product_number`       | NVARCHAR(50) | Alphanumeric product reference used for product identification, categorization, and inventory tracking. |
| `product_name`         | NVARCHAR(50) | Name of the product, including relevant characteristics such as product type, color, or size.           |
| `category_id`          | NVARCHAR(50) | Identifier used to associate the product with its corresponding product category.                       |
| `category`             | NVARCHAR(50) | High-level classification of the product, such as `Bikes` or `Components`.                              |
| `subcategory`          | NVARCHAR(50) | More specific classification that further groups products within a category.                            |
| `maintenance_required` | NVARCHAR(50) | Indicates whether the product requires maintenance, for example `Yes` or `No`.                          |
| `cost`                 | INT          | Base cost of the product expressed in whole monetary units.                                             |
| `product_line`         | NVARCHAR(50) | Product line or series to which the product belongs, such as `Road` or `Mountain`.                      |
| `start_date`           | DATE         | Date from which the product was available for sale or use.                                              |

---

## 3. `gold.fact_sales`

### Purpose

The `fact_sales` table contains transactional sales information and serves as the central fact table for sales-related analysis. It connects sales transactions with the relevant customer and product dimensions.

### Columns

| Column Name     | Data Type    | Description                                                                                     |
| --------------- | ------------ | ----------------------------------------------------------------------------------------------- |
| `order_number`  | NVARCHAR(50) | Alphanumeric reference that identifies the sales order.                                         |
| `product_key`   | INT          | Surrogate key used to associate the sales transaction with a record in the product dimension.   |
| `customer_key`  | INT          | Surrogate key used to associate the sales transaction with a record in the customer dimension.  |
| `order_date`    | DATE         | Date on which the sales order was placed.                                                       |
| `shipping_date` | DATE         | Date on which the ordered product was shipped to the customer.                                  |
| `due_date`      | DATE         | Date by which payment for the sales order was due.                                              |
| `sales_amount`  | INT          | Total sales value associated with the individual sales line, expressed in whole monetary units. |
| `quantity`      | INT          | Number of product units included in the sales line.                                             |
| `price`         | INT          | Unit price of the product for the respective sales line, expressed in whole monetary units.     |

---

## 🔗 Relationships

The Gold Layer follows a dimensional modeling approach in which the `fact_sales` table serves as the central transactional table and is connected to the relevant dimension tables through surrogate keys.

```text
                    ┌─────────────────────┐
                    │   dim_customers     │
                    │─────────────────────│
                    │ customer_key (PK)   │
                    │ customer_id         │
                    │ customer_number     │
                    │ ...                 │
                    └──────────┬──────────┘
                               │
                               │ customer_key
                               │
                               ▼
                    ┌─────────────────────┐
                    │     fact_sales      │
                    │─────────────────────│
                    │ order_number        │
                    │ product_key (FK)    │
                    │ customer_key (FK)   │
                    │ order_date          │
                    │ shipping_date       │
                    │ due_date            │
                    │ sales_amount        │
                    │ quantity            │
                    │ price               │
                    └──────────┬──────────┘
                               │
                               │ product_key
                               │
                               ▼
                    ┌─────────────────────┐
                    │    dim_products     │
                    │─────────────────────│
                    │ product_key (PK)    │
                    │ product_id          │
                    │ product_number      │
                    │ product_name        │
                    │ category            │
                    │ subcategory         │
                    │ ...                 │
                    └─────────────────────┘
```

### Key Relationships

* `fact_sales.customer_key` → `dim_customers.customer_key`
* `fact_sales.product_key` → `dim_products.product_key`

This structure enables sales transactions to be analyzed from different business perspectives, such as **customer**, **product**, **category**, and **time**.

---

## 📌 Summary

The Gold Layer provides a structured and business-oriented representation of the underlying source data.

The combination of:

* `dim_customers`
* `dim_products`
* `fact_sales`

creates the foundation for analytical queries and reporting. The dimensional structure makes it possible to examine sales performance while incorporating customer and product information.

The catalog documents the structure and purpose of these Gold Layer tables and supports the understanding and use of the resulting analytical data model.

---

## 🙏 Credits

This Data Catalog was created as part of my **SQL training project** and is based on the educational **SQL Data Warehouse Project by Data With Baraa**.

Credit for the original project concept, structure, and learning materials goes to **Data With Baraa**.

**Original project:**
https://github.com/DataWithBaraa/sql-data-warehouse-project

The descriptions in this catalog have been independently rewritten and documented by me for this portfolio repository.




