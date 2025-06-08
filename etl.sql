/* On my honor, as an Aggie, I have neither given nor received unauthorized assistance on this assignment. I further affirm that I have not and will not provide this code to any person,
platform, or repository, without the express written permission of Dr. Gomillion. I understand that any violation of these standards will have serious repercussions. */
source structure.sql
\upos


create table Customer_tmp (

       CustomerID Varchar(32),
       FirstName Varchar(32),
       LastName Varchar(32),
       City Varchar(128),
       State Varchar(4),
       Zip Varchar(5),
       AddressLine1 Varchar(128),
       AddressLine2 Varchar(128),
       Email Varchar(128),
       Birthdate Varchar(15)

 ) ENGINE = INNODB;

create table Product_tmp(
        ProductID Varchar(128),
        Name Varchar(128),
        Price Varchar(128),
        QuantityOnHand Varchar(128)
) ENGINE  = INNODB;

create table orders_tmp(
        OID Varchar(128),
        CID Varchar(128),
        OrderDate Varchar(128),
        ShipmentDate Varchar(128)
) ENGINE = INNODB;

create table order_line_tmp(
        OID Varchar(128),
        ProductID Varchar(128)
) ENGINE = INNODB;

LOAD DATA LOCAL INFILE '/home/dgomillion/customers.csv'
INTO TABLE Customer_tmp
FIELDS TERMINATED BY ',' -- or the appropriate delimiter
ENCLOSED BY '"' -- if your CSV fields are enclosed in double quotes
LINES TERMINATED BY '\n' -- or '\r\n' if needed
IGNORE 1 LINES; -- if the first line of the CSV is a header

LOAD DATA LOCAL INFILE '/home/dgomillion/products.csv'
INTO TABLE Product_tmp
FIELDS TERMINATED BY ',' -- or the appropriate delimiter
ENCLOSED BY '"' -- if your CSV fields are enclosed in double quotes
LINES TERMINATED BY '\n' -- or '\r\n' if needed
IGNORE 1 LINES; -- if the first line of the CSV is a header

LOAD DATA LOCAL INFILE '/home/dgomillion/orders.csv'
INTO TABLE orders_tmp
FIELDS TERMINATED BY ',' -- or the appropriate delimiter
ENCLOSED BY '"' -- if your CSV fields are enclosed in double quotes
LINES TERMINATED BY '\n' -- or '\r\n' if needed
IGNORE 1 LINES; -- if the first line of the CSV is a header

LOAD DATA LOCAL INFILE '/home/dgomillion/orderlines.csv'
INTO TABLE order_line_tmp
FIELDS TERMINATED BY ',' -- or the appropriate delimiter
ENCLOSED BY '"' -- if your CSV fields are enclosed in double quotes
LINES TERMINATED BY '\n' -- or '\r\n' if needed
IGNORE 1 LINES; -- if the first line of the CSV is a header



----Updating and Formatting the Customer Table-------------

UPDATE Customer_tmp
SET Birthdate = STR_TO_DATE(Birthdate, '%m/%d/%Y');


Update Customer_tmp
set Birthdate = NULL
where Birthdate = '' OR Birthdate = '0000-00-00';

Update Customer_tmp
set AddressLine2 = NULL
where AddressLine2 = '';



------ INSERTION to main city table-----
INSERT INTO City (Zip, City, State)
SELECT Distinct Zip, City, State
FROM Customer_tmp;



------ INSERTION to main customer table -------------
INSERT INTO Customer
SELECT CustomerID, FirstName, LastName, Email, AddressLine1, AddressLine2, NULL, Birthdate, Zip
FROM Customer_tmp;




-------------- Temp Product Table data cleaning--------------
UPDATE Product_tmp
SET Price = REPLACE(Price, '$', '');

UPDATE Product_tmp
SET Price = REPLACE(Price, ',', '');

----------------------INSERT INTO MAIN PRODUCT TABLE-----------------------

INSERT INTO Product
SELECT ProductID, Name, Price, QuantityOnHand
FROM Product_tmp;

------------Order Table Cleanup------------------------


UPDATE orders_tmp
SET ShipmentDate = NULL
WHERE ShipmentDate = 'Cancelled';


----------------------------INSERT INTO MAIN ORDER TABLE-----------------------

INSERT INTO `Order`
SELECT OID, OrderDate, ShipmentDate, CID
FROM orders_tmp;

-----------------ORDERLINE TABLE INSERT and COUNT---------------------------------

INSERT INTO OrderLine
SELECT OID, ProductID, count(ProductID)
FROM order_line_tmp
GROUP BY OID, ProductID;



drop table Customer_tmp;
drop table Product_tmp;
drop table orders_tmp;
drop table order_line_tmp;


-------End of the script----
