// 1. A Premier League (a világ legerőssebb bajnoksága) meccsek eredményei

SELECT 
    m.id AS meccs_id,
    c1.nev AS hazai_csapat,
    c2.nev AS vendeg_csapat,
    CAST(m.hazai_gol AS VARCHAR) + '-' + CAST(m.vendeg_gol AS VARCHAR) AS eredmeny
FROM meccsek m
JOIN csapat c1 ON m.hazai_csapat_id = c1.id
JOIN csapat c2 ON m.vendeg_csapat_id = c2.id
JOIN bajnoksag b ON c1.bajnoksag_id = b.id
WHERE b.nev = 'England Premier League';

//2. A csapatok száma bajnokságonként

SELECT 
    b.bajnoksag_nev,
    COUNT(*) AS csapatok_szama
FROM csapat c
JOIN bajnoksag b ON c.bajnoksag_id = b.bajnoksag_id
GROUP BY b.bajnoksag_nev;

//3. Átlagos gólok száma meccsenként bajnokság szerinti bontásban

SELECT b.nev AS bajnoksag_nev, AVG(m.hazai_gol + m.vendeg_gol) AS atlagos_gol
FROM meccsek m
JOIN csapat c ON m.hazai_csapat_id = c.id
JOIN bajnoksag b ON c.bajnoksag_id = b.id
GROUP BY b.nev;

//4. A spanyol Liga BBVA csapatai, gólkülönbség szerinti csökkenő sorrendben

SELECT 
    cs.nev AS csapat_nev,
    
    SUM(CASE WHEN m.hazai_csapat_id = cs.id THEN m.hazai_gol ELSE 0 END) +
    SUM(CASE WHEN m.vendeg_csapat_id = cs.id THEN m.vendeg_gol ELSE 0 END) AS ossz_lott,

    SUM(CASE WHEN m.hazai_csapat_id = cs.id THEN m.vendeg_gol ELSE 0 END) +
    SUM(CASE WHEN m.vendeg_csapat_id = cs.id THEN m.hazai_gol ELSE 0 END) AS ossz_kapott,

    (
      SUM(CASE WHEN m.hazai_csapat_id = cs.id THEN m.hazai_gol ELSE 0 END) +
      SUM(CASE WHEN m.vendeg_csapat_id = cs.id THEN m.vendeg_gol ELSE 0 END)
    ) -
    (
      SUM(CASE WHEN m.hazai_csapat_id = cs.id THEN m.vendeg_gol ELSE 0 END) +
      SUM(CASE WHEN m.vendeg_csapat_id = cs.id THEN m.hazai_gol ELSE 0 END)
    ) AS golkulonbseg

FROM meccsek m
JOIN csapat cs ON cs.id = m.hazai_csapat_id OR cs.id = m.vendeg_csapat_id
JOIN bajnoksag b ON cs.bajnoksag_id = b.id
WHERE b.nev = 'Spain Liga BBVA'
GROUP BY cs.id, cs.nev
ORDER BY golkulonbseg DESC;

//5. A játékosok száma és átlagéletkora csapatonként az olasz Seria A-ban, keretmélység szerinti csökkenő sorrendben

SELECT 
    cs.nev AS csapat_nev,
    COUNT(j.id) AS jatekosok_szama,
    AVG(Year(GetDate())-Year(j.szuletett)) As atlageletkor
FROM jatekos j
JOIN csapat cs ON j.csapat_id = cs.id
JOIN bajnoksag b ON cs.bajnoksag_id = b.id
WHERE b.nev = 'Italy Seria A'
GROUP BY cs.id, cs.nev
ORDER BY jatekosok_szama DESC;

//6. Bajnokságonként a legjobb gólkülönbséggel rendelkező csapat

SELECT 
    b.nev AS bajnoksag, 
    c.nev AS csapat, 
    golkulonbseg
FROM (
    SELECT 
        b.nev AS bajnoksag, 
        c.nev AS csapat, 
        SUM(CASE WHEN c.csapat_id = M.hazai_csapat_id THEN M.hazai_gol - M.vendeg_gol 
                 WHEN c.csapat_id = M.vendeg_csapat_id THEN M.vendeg_gol - M.hazai_gol 
                 END) AS golkulonbseg,
        RANK() OVER (PARTITION BY b.bajnoksag_id ORDER BY 
            SUM(CASE WHEN c.csapat_id = M.hazai_csapat_id THEN M.hazai_gol - M.vendeg_gol 
                     WHEN c.csapat_id = M.vendeg_csapat_id THEN M.vendeg_gol - M.hazai_gol 
                     END) DESC) AS rangsor
    FROM csapat c
    JOIN meccsek M ON c.csapat_id = M.hazai_csapat_id OR c.csapat_id = M.vendeg_csapat_id
    JOIN bajnoksag b ON c.bajnoksag_id = b.bajnoksag_id
    GROUP BY b.nev, c.nev, c.csapat_id
) AS lista
WHERE rangsor = 1;

//7. Bajnokságonként a legidősebb játékos neve (amennyiben a Max-ot Min-re cseréljük, megkapjuk a legfiatalabbat)

SELECT 
    L.nev AS bajnoksag,
    P.jatekos_nev AS legidosebb_jatekos,
    YEAR(GETDATE()) - YEAR(j.szuletesi_ev) AS eletkor
FROM jatekos j
JOIN csapat c ON j.csapat_id = c.csapat_id
JOIN bajnoksag b ON c.bajnoksag_id = b.bajnoksag_id
WHERE YEAR(GETDATE()) - YEAR(j.szuletesi_ev) = (
    SELECT MAX(YEAR(GETDATE()) - YEAR(j2.szuletesi_ev))
    FROM jatekos j2
    JOIN csapat c2 ON j2.csapat_id = c2.csapat_id
    WHERE c2.bajnoksag_id = b.bajnoksag_id
);