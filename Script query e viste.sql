
-- SCRIPT QUERY E VISTE

/* Query 1
   Trovare per ogni incidente, la cui indagine si è conclusa, ed in cui sono state condotte le analisi del fattore umano e quelle del fattore organizzaitvo,
   il numero di indagati colpevoli.
*/

SELECT A.eventId AS "EventId",
	(SELECT D.denominazione /* Selezioniamo il nome dell'incidente associato al suo 'EventID'. */
	 FROM sin.incidente D
     WHERE A.eventId = D.eventId) AS "Denominazione",
	 count(*) AS "Numero di colpevoli"
FROM sin.incidente A, sin.indagine B, sin.indagato C
WHERE A.eventId = B.incidente /* Verifichiamo che l'indagine associata allo specifico incidente sia conclusa, che vi siano indagati colpevoli e che siano state effettuate
							     le analisi sopra citate.
							  */
 		AND B.conclusa = 't'
		AND B.idProtocollo = C.indagine
		AND C.colpevole = 't'
		AND B.idProtocollo IN
	  		(SELECT D.indagine
			 FROM sin.analisifattoreumano D INNER JOIN sin.analisifattoreorganizzativo E
				ON (D.indagine = E.indagine))
GROUP BY A.eventId; /* La query termina con il raggruppamento degli incidenti e mostrando il numero di indagati colpevoli corrispondente. */

/* Query 2
   Trovare gli aeromobili i cui voli associati siano solo tratte dirette e le cui indagini, se presenti, abbiano tutte le analisi
   ad accezione di quella sul fattore organizzativo.
*/

SELECT A.aeromobile AS "Aeromobile"
FROM sin.assegnazione A
/* Verifichiamo che i voli associati ai singoli aeromobili non abbiano scali e che quindi non siano contenuti
   all'interno della tabella composta dai soli voli reali il cui id è quello da noi desiderato e il codice del volo non è presente nella tabella scali.
*/
WHERE NOT EXISTS (
			     SELECT B.volo
			     FROM sin.voloreale AS B
			     WHERE A.idVolo = B.idVoloReale
					   AND B.volo IN(
									 SELECT C.volo
									 FROM sin.scali C
						   			)
				 )
		/* Verifichiamo che esista un incidente associato allo specifico volo reale per il quale sia presente un indagine che abbia le analisi sopra citate.*/
		AND EXISTS (
				 SELECT E.incidente
				 FROM sin.voloreale E
				 WHERE A.idVolo = E.idVoloReale
					   AND E.incidente IN (
					   						SELECT F.incidente
						   					FROM sin.indagine F
						   					WHERE F.idProtocollo IN (
														SELECT G.indagine
														FROM sin.analisiFattoreUmano G, sin.analisiCondottaDelVolo H,
															 sin.analisiFattoreAmbientale I, sin.analisiFattoreTecnico J
														WHERE G.indagine = H.indagine AND
															  G.indagine = I.indagine AND G.indagine = J.indagine
														)
					   					  )
			);


/* Query 3
   Piloti coinvolti in più incidenti indagati almeno una volta
*/

/* Seleziono i piloti che hanno condotto più di un volo con la denominazione e il codice dell'incidente in cui sono stati coinvolti */
SELECT F.eventId AS "EventID", F.denominazione AS "Denominazione", A.nome AS "Nome", A.cognome AS "Cognome"
FROM sin.pilota A, sin.conduzione D, sin.voloreale E, sin.incidente F
WHERE D.idVoloReale = E.idVoloReale
	  AND E.incidente = F.eventId
	  AND A.idPilota = D.idPilota
	  AND (SELECT count(*)
		   FROM sin.conduzione B
		   WHERE A.idPilota = B.idPilota
		   ) > 1

INTERSECT

/* Seleziono gli indagati con la denominazione e il codice dell'incidente di cui sono stati accusati */
SELECT A.eventId, A.denominazione, C.nome, C.cognome
FROM sin.incidente A, sin.indagine B, sin.indagato C
WHERE A.eventId = B.incidente
	  AND B.idProtocollo = C.indagine;



/* Query 4
   Trovare i voli coinvolti negli incidenti condotti dai piloti che hanno un numero di ore di esperienza superiore alla media, e stampare i dettagli
   dell’indagine che li riguarda.
*/

SELECT A.denominazione AS "Denominazione", D.nome AS "Nome", D.cognome AS "Cognome", G.statoMentaleAvverso AS "Stato mentale avverso",
	   G.erroriDiPercezione "Errori di percezione", G.erroriDecisionali AS "Errori decisionali", G.erroriDovutiACarenzaDiAbilita AS "Errori dovuti a carenza di abilità",
	   G.violazioneDelleProcedure AS "Violazione delle procedure"
FROM sin.incidente A, sin.voloreale B, sin.conduzione C, sin.pilota D, sin.indagine F, sin.analisiFattoreUmano G
WHERE A.eventId = B.incidente
	  AND B.idVoloReale = C.idVoloReale
	  AND C.idPilota = D.idPilota
	  AND C.oreDiVoloAttuali > (SELECT AVG(E.oreDiVoloAttuali) FROM sin.conduzione E)
	  AND A.eventId = F.incidente
	  AND F.idProtocollo = G.indagine;


/* Query 5
   Stampare il numero di incidenti avvenuti di notte, suddivisi per fase e per cui ci sono stati dei morti.
*/

SELECT B.fase AS "Fase", count(*) AS "Numero di incidenti di notte"
FROM sin.voloreale A INNER JOIN sin.incidente B ON (A.incidente = B.eventId)
WHERE CAST(A.dataOraSinistro AS TIME) >= '00:00:00' AND CAST(A.dataOraSinistro AS TIME) <= '06:00:00'
	  AND B.eventId IN (
	  					SELECT C.incidente
		  				FROM sin.vittima C
		  				WHERE C.decedutiInVolo > 0
		  					  OR C.decedutiATerra > 0
	  				   )
GROUP BY fase;





/* VISTE E QUERY SU VISTA */

-- Vista 8.1 

	/* 
		Questa vista fornisce un quadro generale dei responsabili che si sono occupati o si stanno occupando delle analisi specifiche 
		riguardanti l'indagine di un incidente, ed è stata pensata per far fronte all'esigenza dell'ente che si occupa delle indagini 
		di poter accedere facilmente a queste informazioni. I campi ND rappresentano le tipologie specifiche di analisi che per un 
		dato incidente non sono state condotte da alcun responsabile. 
	*/
	
	CREATE VIEW sin.responsabiliIndagini AS
		SELECT IND.idProtocollo AS Indagine, 
			   IND.conclusa AS conclusa, 
			   INC.denominazione AS Incidente, 
			   COALESCE(AFO.responsabile, 'ND') AS AnalisiFattoreOrganizzativo, 
			   COALESCE(AFU.responsabile, 'ND') AS analisiFattoreUmano, 
			   COALESCE(ACV.responsabile, 'ND') AS analisiCondottaDelVolo, 
			   COALESCE(AFA.responsabile, 'ND') AS analisiFattoreAmbientale,
			   COALESCE(AFT.responsabile, 'ND') AS analisiFattoreTecnico
		FROM sin.indagine as IND 
			   JOIN sin.incidente AS INC 
					ON IND.incidente = INC.eventId
			   LEFT JOIN sin.analisiFattoreOrganizzativo AS AFO 
			   		ON IND.idProtocollo = AFO.indagine
			   LEFT JOIN sin.analisiFattoreUmano AS AFU 
			   		ON IND.idProtocollo = AFU.indagine
			   LEFT JOIN sin.analisiCondottaDelVolo AS ACV 
			   		ON IND.idProtocollo = ACV.indagine
			   LEFT JOIN sin.analisiFattoreAmbientale AS AFA 
			   		ON IND.idProtocollo = AFA.indagine
			   LEFT JOIN sin.analisiFattoreTecnico AS AFT 
			   		ON IND.idProtocollo = AFT.indagine;

	-- 8.1.1 Query con vista: contare il numero di responsabili che hanno concluso l'analisi del fattore
	-- organizzativo.
	
	SELECT SUM(conta) AS "Responsabili che hanno concluso AFO"
	FROM(SELECT COUNT(*) AS conta, R.AnalisiFattoreOrganizzativo, R.conclusa
		FROM sin.responsabiliIndagini AS R
		WHERE R.AnalisiFattoreOrganizzativo <> 'ND' AND R.conclusa = 'true'
		GROUP BY R.AnalisiFattoreOrganizzativo, R.conclusa) AS AFO;
		
	-- 8.1.2 Query con vista: stampare le denominazioni degli incidenti in cui ha lavorato il responsabile 'Carl Artemiev'.
	SELECT R.incidente AS "Denominazione Incidente"
	FROM sin.responsabiliIndagini AS R
	WHERE R.AnalisiFattoreOrganizzativo = 'Carl Artemiev' 
		OR R.analisiFattoreUmano = 'Carl Artemiev'
		OR R.analisiCondottaDelVolo = 'Carl Artemiev'
		OR R.analisiFattoreAmbientale = 'Carl Artemiev'
		OR R.analisiFattoreTecnico = 'Carl Artemiev';
		
-- Vista 8.2
	
	/* 
		Vista che permette di mostrare per ogni aeromobile generico, il numero di incidenti in cui è stato coinvolto,
		il numero complessivo di deceduti in volo e di feriti per ciascun aeromobile ed inoltre mette a disposizione
		informazioni sul costruttore e sullo Stato di produzione dello stesso. Questa vista è stata pensata per
		agevolare l'ente nel fare considerazioni sul livello di affidabilità o meno del costruttore e dei suoi aeromobili.
	*/
	
	CREATE VIEW sin.aeromobiliIncidentati AS
		SELECT C.nome AS nome_costruttore, 
			   C.stato AS stato_costruttore, 
			   AER.codice AS aeromobile, 
			   AER.numeroDiIncidenti AS numero_di_incidenti, 
			   SUM(V.decedutiInVolo) AS deceduti_in_volo, 
			   SUM(V.feriti) AS feriti
		FROM sin.costruttore AS C, 
			 sin.aeromobile AS AER, 
			 sin.vittima AS V, 
			 sin.incidente as INC, 
			 sin.voloReale AS VR, 
			 sin.assegnazione AS ASS
		WHERE C.nome = AER.nomeCostruttore 
			 AND V.incidente = INC.eventId 
			 AND VR.incidente = INC.eventId 
			 AND VR.idVoloReale = ASS.idVolo 
			 AND ASS.aeromobile = AER.codice
		GROUP BY C.nome, 
				 C.stato,
			     AER.codice, 
				 AER.numeroDiIncidenti;
	
	-- 8.2.1 Query con vista: indentificare gli aeromobili col maggior numero di incidenti subiti.
	
	SELECT A.aeromobile AS "Codice Aeromobile", 
	       A.numero_di_incidenti AS "Numero di Incidenti"
	FROM sin.aeromobiliIncidentati AS A
	WHERE A.numero_di_incidenti >= ALL (SELECT B.numero_di_incidenti
								  		FROM sin.aeromobiliIncidentati AS B);

	-- 8.2.2 Query con vista: identificare gli aeromobili il cui numero di
	-- deceduti in volo è superiore alla media.
	
	SELECT A.aeromobile AS "Codice Aeromobile", 	
		   A.deceduti_in_volo AS "Numero di deceduti in volo"
	FROM sin.aeromobiliIncidentati AS A
	WHERE A.deceduti_in_volo > (SELECT AVG(B.deceduti_in_volo)
							    FROM sin.aeromobiliIncidentati AS B);
	
	-- 8.2.3 Query con vista: identificare il costruttore col maggior numero di feriti coinvolti negli 
	-- incidenti degli aeromobili di sua produzione.
	
	SELECT A.nome_costruttore AS "Nome del Costruttore", 
		SUM(A.feriti) AS "Numero di feriti"
	FROM sin.aeromobiliIncidentati AS A
	WHERE A.feriti = (SELECT MAX(B.feriti)
					  FROM sin.aeromobiliIncidentati AS B)
    GROUP BY A.nome_costruttore;
	
-- Vista 8.3

	/*  
		Vista che permette di avere un quadro generale delle indagini concluse che sono presenti all'interno del database ed
		in particolare mostra la durata dell'indagine (differenza tra la data di inzio e fine), il numero dei colpevoli per 
		ogni indagine, la denominazione e il luogo dell'incidente a cui essa è associata e la data di pubblicazione del 
		report ad essa associato.
	*/

	CREATE VIEW sin.quadroIndagini AS
		SELECT IND.idProtocollo AS indagine, 
		       INC.denominazione, 
			   COALESCE(INC.localitaDiRiferimento,'ND') AS luogo_del_sinistro,
			   AGE(IND.dataFine, IND.dataInizio) AS durata, 
			   R.dataPubblicazione AS data_pubblicazione_report, 
			   COUNT(I.matricola) AS numero_colpevoli
		FROM sin.indagato AS I, 
			 sin.indagine AS IND, 
			 sin.incidente AS INC, 
			 sin.report AS R
		WHERE I.indagine = IND.idProtocollo 
			AND IND.incidente = INC.eventId 
			AND R.indagine = IND.idProtocollo 
			AND IND.conclusa = 'true' 
			AND I.colpevole='true'
		GROUP BY IND.idProtocollo, 
				 INC.denominazione, 
				 INC.localitaDiRiferimento,
				 AGE(IND.dataFine, IND.dataInizio), 
				 R.dataPubblicazione;
		
	-- 8.3.1 Query con vista: stampare la denominazione ed il luogo degli incidenti a cui sono associate le indagini col 
	-- maggior numero di colpevoli.
	
	SELECT Q.denominazione "Denominazione Incidente", 
		   COALESCE(Q.luogo_del_sinistro, 'ND') AS "Luogo del sinistro", 
		   Q.numero_colpevoli AS "Numero di Colpevoli"
	FROM sin.quadroIndagini AS Q
	WHERE Q.numero_colpevoli = (SELECT MAX(P.numero_colpevoli)
							    FROM sin.quadroIndagini AS P);
	
	-- 8.3.2 Query con vista: individuare l'indagine con la durata più breve, stampare la denominazione 
	-- dell'incidente associato e la data di pubblicazione del report.
	
	SELECT Q.indagine AS "Indagine", 
		   Q.denominazione AS "Denominazione Incidente", 
		   Q.data_pubblicazione_report AS "Data di pubblicazione del report"
	FROM sin.quadroIndagini AS Q
	WHERE Q.durata <= ALL (SELECT P.durata
						   FROM sin.quadroIndagini AS P);

-- Vista 8.4
	
	/*
		Questa vista permette di visualizzare per ogni volo reale il codice del volo, la compagnia aerea a cui
		esso appartiene, la durata del volo prima dell'accadimento dell'incidente, la località di riferimento, 
		la velocità di discesa e l'altitudine. La vista è stata pensata per  permettere di avere una visione 
		d'insieme di alcune informazioni relative al volo incidentato di una compagnia aerea.
	*/
	
	CREATE OR REPLACE VIEW sin.voliIncidentati AS
		SELECT V.codiceDelVolo, 
			 V.compagniaAerea, 
			 (VR.dataOraSinistro - VR.dataOraPartenza) AS durata_volo_pre_incidente,
			 COALESCE(INC.localitaDiRiferimento, 'ND') AS localita_riferimento,
			 ACV.velocitaDiDiscesa,
			 ACV.altitudine
		FROM sin.volo AS V 
			JOIN sin.voloReale AS VR ON VR.volo = V.codiceDelVolo 
			JOIN sin.incidente AS INC ON VR.incidente = INC.eventId 
			JOIN sin.indagine AS IND ON INC.eventId = IND.incidente
			LEFT JOIN sin.analisiCondottaDelVolo AS ACV ON ACV.indagine = IND.idProtocollo;
			
	-- 8.4.1 Query con vista: stampare codice e la compagnia aerea a cui appartiene il volo che è durato meno tempo (dal momento della partenza al momento
	-- in cui si è verificato l'incidente).
		
	SELECT VI.codiceDelVolo AS "Codice del volo", 
		VI.compagniaAerea AS "Compagnia Aerea",
		VI.durata_volo_pre_incidente AS "Durata del volo pre-incidente"
	FROM sin.voliIncidentati AS VI
	WHERE VI.durata_volo_pre_incidente = (SELECT MIN(A.durata_volo_pre_incidente)
										  FROM sin.voliIncidentati AS A);
