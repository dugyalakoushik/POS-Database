/* On my honor, as an Aggie, I have neither given nor received unauthorized assistance on this assignment. I further affirm that I have not and will not provide this code to any person,
platform, or repository, without the express written permission of Dr. Gomillion. I understand that any violation of these standards will have serious repercussions. */

drop database if exists pos;
create database pos;


use pos;

create table City(

        Zip Decimal(5) zerofill PRIMARY KEY,
        City Varchar(32),
        State Varchar(4)

) ENGINE = InnoDB;


create table Product(

        ProductID Integer PRIMARY KEY,
        Name Varchar(128),
        CurrentPrice Decimal(6,2),
        QtyOnHand Integer

) ENGINE = InnoDB;

create table PriceHistory(

        ChangeID BIGINT UNSIGNED PRIMARY KEY,
        OldPrice Decimal(6,2),
        NewPrice Decimal(6,2),
        TS Timestamp,
        ProductID Integer,
        FOREIGN KEY(ProductID) REFERENCES Product(ProductID)

) ENGINE = InnoDB;


create table Customer(

       CustomerID Integer PRIMARY KEY,
       FirstName Varchar(32),
       LastName Varchar(32),
       Email Varchar(128),
       Address1 Varchar(128),
       Address2 Varchar(128),
       Phone Varchar(32),
       Birthdate Date,
       Zip Decimal(5) zerofill,
       FOREIGN KEY(Zip) REFERENCES City(Zip)

) ENGINE = InnoDB;


create table `Order`(

        OrderID BIGINT UNSIGNED PRIMARY KEY,
        datePlaced Date,
        dateShipped Date,
        CustomerID Integer,
        FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID)


) ENGINE = InnoDB;


create table OrderLine(

        OrderID BIGINT UNSIGNED,
        ProductID Integer,
        Quantity Integer,
        PRIMARY KEY(OrderID, ProductID),
        FOREIGN KEY(OrderID) REFERENCES `Order`(OrderID),
        FOREIGN KEY(ProductID) REFERENCES Product(ProductID)


) ENGINE = InnoDB;

