# Hexagons
This script creates hexagonal grid on the basis which spatial statistics are calculated.<br>
Skrypt tworzy siatkę heksagonalną, na podstawie której obliczane są statystyki przestrzenne.

The easiest and fastest way to run is:
1. Install postgres
2. Install pgadmin
3. Create table
4. Install Postgis extension to your postgres and CREATE EXTENSION postgis in database
5. Install Qgis and connect it with database
6. Load spatial layer(no matter if point, line or polygon type) via Qgis to your database with earlier added postgis extension
7. Change in Skrypt.sql (in DECLARE section) :<br>
a) !IN 3 PLACES! <baea_nests> to your spatial layername, <br>
b) <heksagonyPunkty99> to name of output hexagons which will made,<br>
c) <4326> to EPSG code of your layer<br>
d) <0.1> height of output hexagons in units depends on coordinate system you choosed<br>
e) <0.866> height of hexagons to width ratio<br>
8. Paste script to Query Tool in pgAdmin
9. A new spatial layer with hexagons should be created. In one of created column in this layer should be data with points density, length of lines or polygons area in each hexagon depends on file format you added.
