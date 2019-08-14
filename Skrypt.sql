DO $$
DECLARE
   _warstwa TEXT := 'baea_nests';
  _curs   CURSOR FOR  SELECT geom FROM  baea_nests ;
  _typ TEXT	:=  st_geometrytype(l.geom) FROM baea_nests l  LIMIT 1;
  _table  TEXT     := 'heksagonyPunkty99';
  _srid   INTEGER  := 4326;
  _height NUMERIC  := 0.1;
  _width  NUMERIC  := _height * 0.866;
  _geom   GEOMETRY;
  _hx     GEOMETRY := ST_GeomFromText(
                        FORMAT('POLYGON((0 0, %s %s, %s %s, %s %s, %s %s, %s %s, 0 0))',
                          (_width *  0.5), (_height * 0.25),
                          (_width *  0.5), (_height * 0.75),
                                       0 ,  _height,
                          (_width * -0.5), (_height * 0.75),
                          (_width * -0.5), (_height * 0.25)
                        ), _srid);

BEGIN
  CREATE TEMP TABLE hx_tmp (geom GEOMETRY(POLYGON));

  OPEN _curs;
  LOOP
    FETCH
    _curs INTO _geom;
    EXIT WHEN NOT FOUND;


    INSERT INTO hx_tmp
      SELECT
        ST_Translate(_hx, x_series, y_series)::GEOMETRY(POLYGON) geom
      FROM
        generate_series(
          (st_xmin(_geom) / _width)::INTEGER * _width - _width,
          (st_xmax(_geom) / _width)::INTEGER * _width + _width,
          _width) x_series,
        generate_series(
          (st_ymin(_geom) / (_height * 1.5))::INTEGER * (_height * 1.5) - _height,
          (st_ymax(_geom) / (_height * 1.5))::INTEGER * (_height * 1.5) + _height,
          _height * 1.5) y_series
      WHERE
        ST_Intersects(ST_Translate(_hx, x_series, y_series)::GEOMETRY(POLYGON), _geom);

    INSERT INTO hx_tmp
      SELECT ST_Translate(_hx, x_series, y_series)::GEOMETRY(POLYGON) geom
      FROM
        generate_series(
          (st_xmin(_geom) / _width)::INTEGER * _width - (_width * 1.5),
          (st_xmax(_geom) / _width)::INTEGER * _width + _width,
          _width) x_series,
        generate_series(
          (st_ymin(_geom) / (_height * 1.5))::INTEGER * (_height * 1.5) - (_height * 1.75),
          (st_ymax(_geom) / (_height * 1.5))::INTEGER * (_height * 1.5) + _height,
          _height * 1.5) y_series
      WHERE
        ST_Intersects(ST_Translate(_hx, x_series, y_series)::GEOMETRY(POLYGON), _geom);


  END LOOP;
  CLOSE _curs;

  --CREATE INDEX sidx_hx_tmp_geom ON linear_proj USING GIST (geom);
  EXECUTE 'DROP TABLE IF EXISTS tmp';
  EXECUTE 'CREATE TABLE tmp (geom GEOMETRY(POLYGON, '|| _srid ||'), id SERIAL)';
  EXECUTE 'INSERT INTO tmp SELECT * FROM hx_tmp GROUP BY geom';
  EXECUTE 'CREATE INDEX sidx_tmp_geom ON  tmp USING GIST (geom)';
  EXECUTE 'DROP TABLE IF EXISTS ' || _table ;

			IF _typ =  'ST_MultiPoint' THEN
			EXECUTE 'CREATE TABLE ' || _table || ' (geom GEOMETRY(POLYGON, '||_srid||' ), id INTEGER, iloscPunktow INTEGER);
			INSERT INTO ' || _table || '
			SELECT
			  hex.geom, hex.id,
				  count(punkty.geom)
			FROM tmp hex, '||_warstwa||' punkty
			WHERE st_intersects(punkty.geom, hex.geom)
			GROUP BY hex.geom, hex.id';

			ELSIF _typ = 'ST_MultiLineString'  THEN
			EXECUTE 'CREATE TABLE ' || _table || ' (geom GEOMETRY(POLYGON, '||_srid||' ), id INTEGER, dlugoscLinii NUMERIC);
			INSERT INTO ' || _table || '
			SELECT
			  hex.geom, hex.id,
			  round(
				  sum(
					  st_length(
						  st_intersection(
							  linie.geom,
							  hex.geom)
					  )
				  ) :: NUMERIC, 3) dlugosci
			FROM tmp hex, '||_warstwa||' linie
			WHERE st_intersects(linie.geom, hex.geom)
			GROUP BY hex.geom, hex.id';

			ELSIF _typ = 'ST_MultiPolygon'  THEN
			EXECUTE 'CREATE TABLE ' || _table || ' (geom GEOMETRY(POLYGON, '||_srid||' ), id INTEGER, powPoligonow NUMERIC);
			INSERT INTO ' || _table || '
			SELECT
			hex.geom, hex.id,
			round(
				  sum(
					  st_area(
						  st_intersection(
							  poligony.geom,
							  hex.geom)
					  )*1000
				  ) :: NUMERIC, 3)
			FROM tmp hex, '||_warstwa||' poligony
			WHERE st_intersects(poligony.geom, hex.geom)
			GROUP BY hex.geom, hex.id';

	ELSE
		RAISE NOTICE 'Dodałeś nieobsługiwany typ warstwy';
	END IF;

  DROP TABLE IF EXISTS hx_tmp;
END $$;
