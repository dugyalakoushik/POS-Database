/*On my honor, as an Aggie, I have neither given nor received unauthorized assistance on this assignment. I further affirm that I have not and will not provide this code to any person,
platform, or repository, without the express written permission of Dr. Gomillion. I understand that any violation of these standards will have serious repercussions.*/

--restoring database
source proc.sql
--calling procedures
call proc_FillUnitPrice();
call proc_FillOrderTotal();
call proc_RefreshMV();

----create temp table for tax rate
create table SalesTaxTemp (
        State Varchar(5),
        ZipCode Decimal(5) primary key,
        TaxRegionName Varchar(10),
        EstimatedCombinedRate float,
        StateRate float,
        EstimatedCountyRate float,
        EstimatedCityRate float,
        EstimatedSpecialRate float,
        RiskLevel float
);



---create sales tax table
create table SalesTax (
        ZipCode Decimal(5) primary key,
        TaxRate float
);

LOAD DATA LOCAL INFILE '/home/dgomillion/TAXRATES.csv'
INTO TABLE SalesTaxTemp
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES; -- the first line of the CSV is a header


delete from SalesTaxTemp where ZipCode = 'ZipCode';


--insert into permnent table
INSERT INTO SalesTax select ZipCode,EstimatedCombinedRate from SalesTaxTemp;


/*create table SalesTax (
        ZipCode Integer(128) primary key,
        TaxRate float
);


LOAD DATA LOCAL INFILE '/home/dgomillion/TAXRATES.csv'
INTO TABLE SalesTax
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- the first line of the CSV is a header
(ZipCode, EstimatedCombinedRate);*/

---------Alter pricehistory table
ALTER TABLE PriceHistory
MODIFY CHANGEID BIGINT AUTO_INCREMENT,
MODIFY TS TIMESTAMP DEFAULT NOW();

----------Alter Order Table
ALTER TABLE pos.Order
RENAME COLUMN OrderTotal TO OrderSubtotal;

ALTER TABLE pos.Order
ADD COLUMN SalesTax DECIMAL(5,2) DEFAULT 0.00;


ALTER TABLE pos.Order
ADD COLUMN OrderTotal DECIMAL(8,2) GENERATED ALWAYS AS (OrderSubtotal + SalesTax) VIRTUAL;


-----Trigger to insert into pricehistory table
DELIMITER //
CREATE OR REPLACE TRIGGER PriceHistoryTrigger AFTER UPDATE ON Product FOR EACH ROW
BEGIN
  IF  NEW.CurrentPrice != OLD.CurrentPrice THEN
  INSERT INTO PriceHistory(ProductID,OldPrice,NewPrice,TS) VALUES (OLD.ProductID,OLD.CurrentPrice, NEW.CurrentPrice, Default);
  END IF;
END; //
DELIMITER ;



-------------------------------------OrderLineTrigger-------------------------------------------
DELIMITER //
CREATE OR REPLACE TRIGGER OrderLineTrigger BEFORE INSERT ON OrderLine FOR EACH ROW
BEGIN
  SET NEW.UnitPrice = (SELECT CurrentPrice FROM Product WHERE ProductID = NEW.ProductID);
END;
//
DELIMITER ;


------------------SubTotal Trigger----------------------------------------------
DELIMITER //
CREATE OR REPLACE TRIGGER OrderSubtotalInsertTrigger
AFTER INSERT ON OrderLine
FOR EACH ROW
BEGIN

        UPDATE `Order`
        SET OrderSubTotal = (SELECT SUM(OrderLine.LineTotal) FROM OrderLine WHERE OrderLine.OrderID = `Order`.OrderID)
        WHERE OrderID = NEW.OrderID;

END;
//
DELIMITER ;

DELIMITER //
CREATE OR REPLACE TRIGGER OrderSubtotalUpdateTrigger
AFTER UPDATE ON OrderLine
FOR EACH ROW
BEGIN

        UPDATE `Order`
        SET OrderSubTotal = (SELECT SUM(OrderLine.LineTotal) FROM OrderLine WHERE OrderLine.OrderID = `Order`.OrderID)
        WHERE OrderID = NEW.OrderID;

END;
//
DELIMITER ;

DELIMITER //
CREATE OR REPLACE TRIGGER OrderSubtotalDeleteTrigger
AFTER DELETE ON OrderLine
FOR EACH ROW
BEGIN

        UPDATE `Order`
        SET OrderSubTotal = (SELECT SUM(OrderLine.LineTotal) FROM OrderLine WHERE OrderLine.OrderID = `Order`.OrderID)
        WHERE OrderID = OLD.OrderID;

END;
//
DELIMITER ;


------------------Delimiter to set quantity on OrderLine------------------------------------------------------------------------
DELIMITER //

CREATE OR REPLACE TRIGGER SetQtyTriggerINS BEFORE INSERT ON OrderLine
FOR EACH ROW
BEGIN
    IF NEW.Quantity IS NULL THEN
        SET NEW.Quantity = 1;
    END IF;
END;
//

DELIMITER ;

DELIMITER //

----------------------------------------------------------------------
DELIMITER //

CREATE OR REPLACE TRIGGER SetQtyTriggerUPD BEFORE UPDATE ON OrderLine
FOR EACH ROW
BEGIN
    IF NEW.Quantity IS NULL THEN
        SET NEW.Quantity = 1;
    END IF;
END;
//

DELIMITER ;


---------------------update unventory levels in product------------------------------
DELIMITER //

CREATE OR REPLACE TRIGGER ProdQtyInsertTrigger
AFTER INSERT ON OrderLine
FOR EACH ROW
BEGIN

        UPDATE Product
        SET QtyOnHand = QtyOnHand - NEW.Quantity
        WHERE ProductID = NEW.ProductID;

END;
//
DELIMITER ;

DELIMITER //
CREATE OR REPLACE TRIGGER ProdQtyUpdateTrigger
AFTER UPDATE ON OrderLine
FOR EACH ROW
BEGIN

        UPDATE Product
        SET QtyOnHand = QtyOnHand + OLD.Quantity - NEW.Quantity
        WHERE ProductID = NEW.ProductID;

END;
//
DELIMITER ;

DELIMITER //
CREATE OR REPLACE TRIGGER ProdQtyDelTrigger AFTER DELETE ON OrderLine
FOR EACH ROW
BEGIN

        UPDATE Product
        SET QtyOnHand = QtyOnHand + OLD.Quantity
        WHERE ProductID = OLD.ProductID;

END;
//
DELIMITER ;

----------------SQL ERROR HANDLING USINS SIGNAL TO PREVENT OVERALLOCATION FORM PROD TABLE----------------------------------

DELIMITER //
CREATE OR REPLACE TRIGGER StopOverAllocINS BEFORE INSERT ON OrderLine
FOR EACH ROW
BEGIN

        DECLARE TotQuantity Integer;
        SELECT QtyOnHand into TotQuantity
        FROM Product
        where ProductId = NEW.ProductID;
        IF NEW.Quantity > TotQuantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You entered an insufficient quantity';
    END IF;
END;
//
DELIMITER ;
----------------------------------------------------------------------------UPDATE ERROR HANDLING-------------------------------------------------------------------------------------
DELIMITER //
CREATE OR REPLACE TRIGGER StopOverAllocUPD BEFORE UPDATE ON OrderLine
FOR EACH ROW
BEGIN
        DECLARE TotQuant Integer;
        SELECT QtyOnHand into TotQuant
        FROM Product
        where ProductId = NEW.ProductID;

        IF NEW.Quantity > TotQuant THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You entered an insufficient quantity';
    END IF;
END;
//
DELIMITER ;

--------------------QUESTION 11 UPDATE TAXRATES IN ORDER TABLE-----------------------------------
/*LOGIC:declaring subtotal, custid, custzip, taxrate
 sum linetotal into subtotal; orderline join order to get custid; use custid to get zip; use zip to get taxrate from tax table; calc tax --> virtually ordertotal generated*/
DELIMITER //

CREATE OR REPLACE TRIGGER CalculateOrderTotal AFTER INSERT ON OrderLine FOR EACH ROW
BEGIN
    /*DECLARE ordersubtotal float;*/
    DECLARE custid int(11);
    DECLARE custzip decimal(5);
    DECLARE combinedtaxrate float;

    SELECT DISTINCT CustomerID INTO custid
    FROM pos.Order o join OrderLine OL on o.OrderID=OL.OrderID
    AND o.OrderID = NEW.OrderID;


    SELECT Zip INTO custzip
    FROM Customer
    WHERE CustomerID = custid;

    SELECT TaxRate INTO combinedtaxrate
    FROM SalesTax
        WHERE ZipCode = custzip;

    UPDATE pos.Order
        SET SalesTax = OrderSubtotal*combinedtaxrate
        WHERE OrderID = NEW.OrderID;

END;
//

DELIMITER ;

/*for update statemennts on OrderLine table*/
/*LOGIC:declaring subtotal, custid, custzip, taxrate
 sum linetotal into subtotal; orderline join order to get custid; use custid to get zip; use zip to get taxrate from tax table; calc tax --> virtually ordertotal generated*/
DELIMITER //

CREATE OR REPLACE TRIGGER CalculateOrderTotalUPD AFTER UPDATE ON OrderLine FOR EACH ROW
BEGIN
    /*DECLARE ordersubtotalup float;*/
    DECLARE custidup int(11);
    DECLARE custzipup decimal(5);
    DECLARE combinedtaxrateup float;

    SELECT DISTINCT CustomerID INTO custidup
    FROM pos.Order o join OrderLine OL on o.OrderID=OL.OrderID
    AND o.OrderID = NEW.OrderID;


    SELECT Zip INTO custzipup
    FROM Customer
    WHERE CustomerID = custidup;

    SELECT TaxRate INTO combinedtaxrateup
    FROM SalesTax
        WHERE ZipCode = custzipup;


    UPDATE pos.Order
        SET SalesTax = OrderSubtotal*combinedtaxrateup
        WHERE OrderID = NEW.OrderID;

END;
//

DELIMITER ;


------------------------DELETE OPERATION FOR SALESTAX UPDATE ON ORDER TABLE---------------
/*LOGIC:declaring subtotal, custid, custzip, taxrate
 sum linetotal into subtotal; orderline join order to get custid; use custid to get zip; use zip to get taxrate from tax table; calc tax --> virtually ordertotal generated*/
DELIMITER //

CREATE OR REPLACE TRIGGER CalculateOrderTotalDEL AFTER DELETE ON OrderLine FOR EACH ROW
BEGIN
    /*DECLARE ordersubtotaldel float;*/
    DECLARE custiddel int(11);
    DECLARE custzipdel decimal(5);
    DECLARE combinedtaxratedel float;

    SELECT DISTINCT CustomerID INTO custiddel
    FROM pos.Order o join OrderLine OL on o.OrderID=OL.OrderID
    AND o.OrderID = OLD.OrderID;


    SELECT Zip INTO custzipdel
    FROM Customer
    WHERE CustomerID = custiddel;

    SELECT DISTINCT TaxRate INTO combinedtaxratedel
    FROM SalesTax
    WHERE ZipCode = custzipdel;

    UPDATE pos.Order
    SET SalesTax = OrderSubtotal*combinedtaxratedel
    WHERE OrderID = OLD.OrderID;

END;
//

DELIMITER ;


---------------------------------------TRIGGERS TO UPDATE THE MATERIALIZED VIEWS--------------------------

------------------------ Stored procedure for updating CustomerPurchases
/*DELIMITER //
CREATE PROCEDURE mv_CustomerPurchasesins(IN CustomerID INT)
BEGIN

        DECLARE custidins int(11);
        DECLARE prodnameins Varchar(128);
        DECLARE fnameins Varchar(128);
        DECLARE lnameins Varchar(128);
        DECLARE productslist mediumtext;
        DECLARE productsfinallist mediumtext;
        DECLARE prodid int(11);

        SET prodid = NEW.ProductID;

        select CustomerID into custidins from pos.Order
        where OrderID = NEW.OrderID;

        select Name into prodnameins from Product
        where ProductID = NEW.ProductID;

        select products into productslist from mv_CustomerPurchases
        where CustomerID = custidins;

        SET productsfinallist = GROUP_CONCAT( CONCAT (productslist, ' ', prodid , ' ', prodnameins)


        UPDATE mv_CustomerPurchases
        SET products = productsfinallist
        where CustomerID = custidins;
END;
//
DELIMITER ;*/

---------------------------------------------PROCEDURE---------------
delimiter //
CREATE OR REPLACE PROCEDURE mv_CustomerPurchases(IN CustomerIDtmp int)
BEGIN
DELETE FROM mv_CustomerPurchases where CustomerID = CustomerIDtmp;
INSERT INTO mv_CustomerPurchases SELECT c.CustomerID AS CustomerID, c.FirstName AS FirstName, c.LastName AS LastName,
GROUP_CONCAT(DISTINCT CONCAT( p.ProductID, ' ', p.Name) ORDER BY p.ProductID SEPARATOR '|') AS products
FROM Product p
RIGHT JOIN OrderLine ol ON p.ProductID = ol.ProductID
RIGHT JOIN `Order` o ON ol.OrderID = o.OrderID
RIGHT JOIN Customer c ON o.CustomerID = c.CustomerID
AND c.CustomerID =  CustomerIDtmp
GROUP BY c.CustomerID, c.FirstName, c.LastName;

END //
DELIMITER ;


------------------------------------------------------------TRIGGER FOR INSERT MVcUSTOMER PURCHASES-----------------------------------


DELIMITER //
CREATE TRIGGER Updatemv_CustomerPurchasesINS AFTER INSERT ON OrderLine
FOR EACH ROW
BEGIN
    -- Call the stored procedure to update MaterializedView1

   DECLARE custidins int(11);

        select CustomerID into custidins from pos.Order
        where OrderID = NEW.OrderID;

    CALL mv_CustomerPurchases(custidins);
END;
//
DELIMITER ;

-----------------------------------------------------------TRIGGER FOR INSERT MVcUSTOMER PURCHASE--------------------------

--------------------------------------------------------------------------------TRIGGER FOR UPDATE MVcUSTOMER PURCHASES---------------------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER Updatemv_CustomerPurchasesUPD AFTER UPDATE ON OrderLine
FOR EACH ROW
BEGIN
    -- Call the stored procedure to update MaterializedView1

   DECLARE custidins int(11);

        select CustomerID into custidins from pos.Order
        where OrderID = NEW.OrderID;

    CALL mv_CustomerPurchases(custidins);
END;
//
DELIMITER ;


--------------------------------------------------------------------------------TRIGGER FOR DELETE MVcUSTOMER PURCHASES---------------------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER Updatemv_CustomerPurchasesDEL AFTER DELETE ON OrderLine
FOR EACH ROW
BEGIN
    -- Call the stored procedure to update MaterializedView1

   DECLARE custidins int(11);

        select CustomerID into custidins from pos.Order
        where OrderID = OLD.OrderID;

    CALL mv_CustomerPurchases(custidins);
END;
//
DELIMITER ;

------------------------------------------------------------------------------------------PROCEDURE for MVproductsupdate table-------------------------------------------------------------------------------------------
delimiter //
CREATE OR REPLACE PROCEDURE mv_ProductBuyers(IN ProductIDtmp int)
BEGIN
DELETE FROM mv_ProductBuyers where ProductID = ProductIDtmp;
INSERT INTO mv_ProductBuyers SELECT p.ProductID AS productID, p.Name AS productName,
GROUP_CONCAT(DISTINCT CONCAT(c.CustomerID, ' ', c.FirstName, ' ', c.LastName) ORDER BY c.CustomerID) AS customers
FROM Product p
LEFT JOIN OrderLine ol ON p.ProductID = ol.ProductID
LEFT JOIN `Order` o ON ol.OrderID = o.OrderID
LEFT JOIN Customer c ON o.CustomerID = c.CustomerID
GROUP BY p.ProductID, p.Name;

END //
DELIMITER ;

-----------------------------------------------------------------------------------TRIGGER FOR INSERT MVcUSTOMER PURCHASES---------------------------------------------------------------------------------

DELIMITER //
CREATE TRIGGER Updatemv_ProductBuyersins AFTER INSERT ON OrderLine
FOR EACH ROW
BEGIN



    CALL mv_ProductBuyers(NEW.ProductID);
END;
//
DELIMITER ;



--------------------------------------------------------------------------------TRIGGER FOR UPDATE MVcUSTOMER PURCHASES---------------------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER Updatemv_ProductBuyersUPD AFTER UPDATE ON OrderLine
FOR EACH ROW
BEGIN




    CALL mv_ProductBuyers(NEW.ProductID);
END;
//
DELIMITER ;


--------------------------------------------------------------------------------TRIGGER FOR DELETE MVcUSTOMER PURCHASES---------------------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER UpdatemvProductBuyersDEL AFTER DELETE ON OrderLine
FOR EACH ROW
BEGIN



    CALL mv_ProductBuyers(OLD.ProductID);
END;
//
DELIMITER ;







/*-----------------view update-----------------------------------*/

/*CREATE OR REPLACE VIEW v_CustomerPurchases AS
SELECT c.CustomerID AS CustomerID, c.FirstName AS FirstName, c.LastName AS LastName,
GROUP_CONCAT(DISTINCT CONCAT( p.ProductID, ' ', p.Name) ORDER BY p.ProductID SEPARATOR '|') AS products
FROM Product p
RIGHT JOIN OrderLine ol ON p.ProductID = ol.ProductID
RIGHT JOIN `Order` o ON ol.OrderID = o.OrderID
RIGHT JOIN Customer c ON o.CustomerID = c.CustomerID
AND c.CustomerID = custidins
GROUP BY c.CustomerID, c.FirstName, c.LastName;*/


/*---------------------extract from view to do eager update on mv--------------------------------------*/
/*SELECT products into productslist
FROM v_CustomerPurchases
RIGHT JOIN OrderLine ol ON p.ProductID = ol.ProductID
RIGHT JOIN `Order` o ON ol.OrderID = o.OrderID
RIGHT JOIN Customer c ON o.CustomerID = c.CustomerID
AND c.CustomerID = custidins
GROUP BY c.CustomerID, c.FirstName, c.LastName;

        UPDATE mv_CustomerPurchases
        SET products = productslist
        WHERE CustomerID = custidins;

END;
//
DELIMITER ;*/

-----------------TRIGGER TO DO EAGER UPDATE ON mv--------------------------------------


-- Trigger to update mv_CustomerPurchases when products are added or removed
/*DELIMITER //
CREATE TRIGGER Updatemv_CustomerPurchasesins AFTER INSERT ON OrderLine
FOR EACH ROW
BEGIN
    -- Call the stored procedure to update MaterializedView1

   DECLARE custidins int(11);

        select CustomerID into custidins from pos.Order
        where OrderID = NEW.OrderID;

    CALL mv_CustomerPurchasesins(custidins);
END;
//
DELIMITER ;*/



