-- json.sql

-- Include the source trig.sql as the first non-attestation line
SOURCE trig.sql;

-- Create a SQL select statement to generate the first aggregate for Customers
SELECT
    CustomerID,
    CONCAT(FirstName, ' ', LastName) AS `Customer Name`,
    CONCAT(
        Address1,
        IFNULL(CONCAT('\n', Address2), ''),
        '\n',
        City,
        '\n',
        State,
        '\n',
        Zip
    ) AS AddressInfo
INTO OUTFILE '/var/lib/mysql/pos/cust1.json'
FROM Customers;
