#"SELECT pud.cislozak, pud.datum, MIN(pud.cislo) + \"/\" + MIN(Cstr(pud.orderfld)) AS id, MIN(pud.firma) + \" - \" + MIN(pud.stext) AS description, MIN(Iif(LEFT(umd, 1) = '6', -1, 0)) AS minus1, MIN(pud.umd) AS ucets, MIN(pud.ud) AS protiu, SUM(pud.kc) AS price FROM pud LEFT JOIN pos ON pos.ucet = pud.umd WHERE pos.reldruhu = 2 AND cislozak = \"#{project_id}\" AND LEFT(umd, 1) #{revenues ? '=' : '!='} '6' GROUP  BY cislozak, datum, umd UNION ALL SELECT pud.cislozak, pud.datum, MIN(pud.cislo) + \"/\" + MIN(Cstr(pud.orderfld)) AS id, MIN(pud.firma) + \" - \" + MIN(pud.stext) AS description, MIN(Iif(LEFT(ud, 1) = '6', -1, 0)) AS minus1, MIN(pud.ud) AS ucets, MIN(pud.umd) AS protiu, SUM(pud.kc) AS price FROM pud LEFT JOIN pos ON pos.ucet = pud.ud WHERE pos.reldruhu = 2 AND cislozak = \"#{project_id}\" AND LEFT(ud, 1) #{revenues ? '=' : '!='} '6' GROUP  BY cislozak, datum, ud;"
class EasySyncPohodaTools
  def self.query(project_id, revenues = false)
    "SELECT pud.cislozak, 
       pud.datum, 
       MIN(pud.cislo) + '/' + MIN(Cstr(pud.orderfld)) AS id, 
       MIN(pud.firma) + ' - ' + MIN(pud.stext)        AS description, 
       MIN(Iif(LEFT(umd, 1) = '6', -1, 0))            AS minus1, 
       MIN(pud.umd)                                   AS ucets, 
       MIN(pud.ud)                                    AS protiu, 
       SUM(pud.kc)                                    AS price 
FROM   pud 
       LEFT JOIN pos 
         ON pos.ucet = pud.umd 
WHERE  pos.reldruhu = 2
       AND cislozak = '#{project_id}'
       AND #{revenues ? '' : 'NOT '}LEFT(umd, 1) = '6'
GROUP  BY cislozak,
          datum, 
          umd 
UNION ALL 
SELECT pud.cislozak, 
       pud.datum, 
       MIN(pud.cislo) + '/' + MIN(Cstr(pud.orderfld)) AS id, 
       MIN(pud.firma) + ' - ' + MIN(pud.stext)        AS description, 
       MIN(Iif(LEFT(ud, 1) = '6', -1, 0))             AS minus1, 
       MIN(pud.ud)                                    AS ucets, 
       MIN(pud.umd)                                   AS protiu, 
       SUM(pud.kc)                                    AS price 
FROM   pud 
       LEFT JOIN pos 
         ON pos.ucet = pud.ud 
WHERE  pos.reldruhu = 2
       AND cislozak = '#{project_id}'
       AND #{revenues ? '' : 'NOT '}LEFT(ud, 1) = '6'
GROUP  BY cislozak, 
          datum, 
          ud;"
  end
  
  
end
#
#AND LEFT(umd, 1) #{revenues ? '=' : '!='} '6'
