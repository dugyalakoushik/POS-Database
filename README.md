# Scalable POS Database on AWS Architecture
POS Database ETL, Aggregation, and P2P Clustering

**Overview**

This project focuses on implementing an ETL (Extract, Transform, Load) pipeline for a Point of Sale (POS) system database, aggregating key business metrics, and replicating data across a MongoDB P2P (peer-to-peer) cluster. The solution ensures seamless data flow, transformation, and availability across distributed nodes.


Key Features

    ETL Pipeline Implementation:
      	Extraction of transactional data from the POS relational database.
      	Transformation to optimize data structure and prepare it for analytical workloads.
      	Loading processed data into a MongoDB cluster for distributed access.
       
    Data Aggregation:
            Generation of insightful business reports, including revenue, sales trends, and customer behavior.
        
    MariaDB P2P Clustering:
     	Replication of data across distributed nodes for high availability and fault tolerance.
     	Implementation of sharding strategies to optimize query performance.
      	Ensuring data consistency and synchronization across the cluster.
   
Project Architecture

    Data Extraction: Extract raw sales, inventory, and customer data from the POS database via SQL queries.
    Data Transformation: Cleanse and normalize data for consistency. Aggregate transactional data to support business intelligence. Format data to align with MongoDB document structure.
    Data Loading: Insert transformed data into MongoDB collections. Implement indexing strategies for optimized retrieval.

![image](https://github.com/user-attachments/assets/7f4fe782-46a5-430a-8e2d-4b747e93493b)

Schema Overview
1.	Product
   
      o	id: Product ID
  	
      o	name: Product Name
  	
      o	currentPrice: Current Price
  	
      o	availableQuantity: Quantity in Stock
  	
3.	City
   
      o	zip: ZIP Code
  	
      o	city: City Name
  	
      o	state: State Name
  	
5.	Customer
      o	id: Customer ID
  	
      o	firstName: First Name
  	
      o	lastName: Last Name
  	
      o	email: Email Address
  	
      o	address1: Primary Address
  	
      o	address2: Secondary Address (optional)
  	
      o	phone: Phone Number
  	
      o	birthdate: Birthdate
  	
      o	zip: ZIP Code (linked to City)
  	
7.	Order
      o	id: Order ID
  	
      o	datePlaced: Date the order was placed
  	
      o	dateShipped: Shipping Date
  	
      o	customer_id: Linked Customer ID
  	
9.	Orderline
      o	order_id: Linked Order ID
  	
      o	product_id: Linked Product ID
  	
      o	quantity: Quantity ordered

Aggregate Tables
1.	Customer Order History Table: Combines customer information with a nested array of orders and order details.
2.	Product Purchase Details Table: Lists products with an array of customers who purchased them.

Example Target Queries:
MySQL
1. List all customers and their associated cities:

2. Get all orders with total price and shipping date:

3. Get products purchased by a specific customer (e.g., customer ID = 1):

MongoDB
1. Find all orders placed by a specific customer (e.g., Customer ID = 1):

2. Get all products purchased by customers in a specific city (e.g., "Houston"):

3. List all products with their buyers:
