/* On my honor, as an Aggie, I have neither given nor received unauthorized assistance on this assignment. I further affirm that I have not and will not provide this code to any person,
platform, or repository, without the express written permission of Dr. Gomillion. I understand that any violation of these standards will have serious repercussions. */

source etl.sql
\upos


-------------------First View-------------
CREATE OR REPLACE VIEW v_CustomerNames AS
SELECT LastName AS "Last Name", FirstName AS "First Name"
FROM Customer
ORDER BY LastName, FirstName;


-------------------------Second view----------------
CREATE OR REPLACE VIEW v_Customers AS
SELECT CustomerID AS customer_number,FirstName AS first_name,LastName AS last_name, Address1 AS street1,
Address2 AS street2, City AS City, State AS ST, C.Zip AS zip_code
FROM Customer C join City Ci
ON C.Zip = Ci.Zip;

---------------------------Third View-------------------
CREATE OR REPLACE VIEW v_ProductBuyers AS
SELECT p.ProductID AS productID, p.Name AS productName,
GROUP_CONCAT(DISTINCT CONCAT(c.CustomerID, ' ', c.FirstName, ' ', c.LastName) ORDER BY c.CustomerID) AS customers
FROM Product p
LEFT JOIN OrderLine ol ON p.ProductID = ol.ProductID
LEFT JOIN `Order` o ON ol.OrderID = o.OrderID
LEFT JOIN Customer c ON o.CustomerID = c.CustomerID
GROUP BY p.ProductID, p.Name;

------------------------------Fourth View--------------------------------------
CREATE OR REPLACE VIEW v_CustomerPurchases AS
SELECT c.CustomerID AS CustomerID, c.FirstName AS FirstName, c.LastName AS LastName,
GROUP_CONCAT(DISTINCT CONCAT( p.ProductID, ' ', p.Name) ORDER BY p.ProductID SEPARATOR '|') AS products
FROM Product p
RIGHT JOIN OrderLine ol ON p.ProductID = ol.ProductID
RIGHT JOIN `Order` o ON ol.OrderID = o.OrderID
RIGHT JOIN Customer c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;

------------------------------------Fifth View--------------------------------------


create or replace table mv_ProductBuyers as select * from v_ProductBuyers;


 -----------------------------------Sixth View------------------------------------------
create or replace table mv_CustomerPurchases as select * from v_CustomerPurchases;


--------------------------------------Indexes-----------------------
create or replace index idx_CustomerEmail on Customer(Email);


create or replace index idx_ProductName on Product(Name);


