
=== Drop old expected result table
DROP TABLE IF EXISTS foglio_articoli_from_drive;

=== Read expected results
CREATE EXTERNAL TABLE foglio_articoli_from_drive (
  `Codice` STRING,
  `Obs` STRING,
  `Descrizione` STRING,
  `Nota` STRING,
  `Data_config` STRING,
  `Descrizione_breve` STRING,
  `Descrizione_breve_2` STRING,
  `Um` STRING,
  `Um2` STRING,
  `Coef` STRING,
  `Cod_barre` STRING,
  `Cod_Cat` STRING,
  `Categoria` STRING,
  `Cod_Tipo` STRING,
  `Tipo` STRING,
  `Cod_Forn` STRING,
  `Fornitore` STRING,
  `Costo` STRING,
  `Iva` STRING,
  `Prezzo` STRING,
  `Ricarico_rif` STRING,
  `Prezzo_al_kg_o_lt` STRING,
  `Ricarico` STRING
)
USING CSV
LOCATION 'file://${FOGLIO_ARTICOLI_FROM_DRIVE_CSV_PATH}'
OPTIONS (
  'header'='true', 
  'delimiter' = ','
)
;

=== Create diffs showing view 
CREATE OR REPLACE TEMP VIEW foglio_articoli_diffs AS (
  WITH comparison AS (
    SELECT 
      COALESCE(fa.codice_articolo, dr.Codice) AS codice_articolo,
      
      -- Comparing Descrizione (Drive) vs descrizione_articolo (View)
      fa.descrizione_articolo AS view_descrizione,
      dr.Descrizione AS drive_descrizione,
      CASE WHEN fa.descrizione_articolo = dr.Descrizione THEN 'MATCH' ELSE 'MISMATCH' END as diff_descrizione,

      -- Flag
      fa.nd_column_flag || dr.Obs as flags,
      fa.nd_column_flag <> dr.Obs as flags_differs,
      
      -- Comparing Descrizione breve
      coalesce( fa.descrizione_breve_articolo, '0') AS view_descrizione_breve,
      CASE WHEN dr.Descrizione_breve = '#N/A' THEN '0' ELSE dr.Descrizione_breve END AS drive_descrizione_breve,
      CASE WHEN 
          coalesce( fa.descrizione_breve_articolo, '0') 
        = 
          (CASE WHEN dr.Descrizione_breve = '#N/A' THEN '0' ELSE dr.Descrizione_breve END) 
        THEN 'MATCH' 
        ELSE 'MISMATCH' 
      END as diff_descrizione_breve,
      
      -- Comparing Descrizione breve 2
      coalesce( fa.descrizione_breve_2_articolo, '0') AS view_descrizione_breve_2,
      CASE WHEN dr.Descrizione_breve_2 = '#N/A' THEN '0' ELSE dr.Descrizione_breve_2 END AS drive_descrizione_breve_2,
      CASE WHEN 
          coalesce( fa.descrizione_breve_2_articolo, '0') 
        = 
          (CASE WHEN dr.Descrizione_breve_2 = '#N/A' THEN '0' ELSE dr.Descrizione_breve_2 END) 
        THEN 'MATCH' 
        ELSE 'MISMATCH' 
      END as diff_descrizione_breve_2,
      
      -- Record Presence check
      CASE 
        WHEN fa.codice_articolo IS NULL THEN 'ONLY IN DRIVE'
        WHEN dr.Codice IS NULL THEN 'ONLY IN VIEW'
        ELSE 'IN BOTH'
      END as record_status

    FROM foglio_articoli fa
    FULL OUTER JOIN foglio_articoli_from_drive dr 
      ON fa.codice_articolo = dr.Codice
  )
  SELECT
    *
  FROM
    comparison
  WHERE 
    -- Show only differences
    diff_descrizione = 'MISMATCH' OR
    diff_descrizione_breve = 'MISMATCH' OR
    diff_descrizione_breve_2 = 'MISMATCH' OR
    record_status <> 'IN BOTH' OR
    flags_differs
  ORDER BY
    codice_articolo
)
;
