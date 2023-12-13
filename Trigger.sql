/* 9.1 TRIGGER DI INIZIALIZZAZIONE/POPOLAMENTO DATABASE  */

/* 9.1.1)   Controllo che il codice del volo abbia il formato corretto:
	- 2 lettere 4 numeri
	- 2 lettere e 3 numeri
	- 3 lettere 4 numeri
	- 4 numeri
	- 3 lettere e 3 numeri
	- 3 lettere e 2 numeri*/

DROP FUNCTION IF EXISTS checkCodiceDelVolo() CASCADE;

CREATE FUNCTION checkCodiceDelVolo() RETURNS TRIGGER AS $$
BEGIN

	IF ((NEW.codiceDelVolo !~ '^[A-Z]{2}[0-9]{4}') AND (NEW.codiceDelVolo !~ '^[A-Z]{3}[0-9]{4}')
		AND (NEW.codiceDelVolo !~ '^[0-9]{4}') AND (NEW.codiceDelVolo !~ '^[A-Z]{3}[0-9]{3}' )
	   	AND (NEW.codiceDelVolo !~ '^[A-Z]{2}[0-9]{3}') AND (NEW.codiceDelVolo !~ '^[A-Z]{3}[0-9]{2}')) THEN
		RAISE EXCEPTION 'Formato errato del codice del volo';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertOrUpdateCodiceVolo ON sin.volo CASCADE;

CREATE TRIGGER insertOrUpdateCodiceVolo
AFTER INSERT OR UPDATE ON sin.volo
FOR EACH ROW EXECUTE PROCEDURE checkCodiceDelVolo();

/* 9.1.2) Controllo che la fase assuma dei valori specifici (case insensitive) */

DROP FUNCTION IF EXISTS checkFaseIncidente() CASCADE;

CREATE FUNCTION checkFaseIncidente() RETURNS TRIGGER AS $$
BEGIN

	IF (LOWER(NEW.fase) != 'parking' AND LOWER(NEW.fase) != 'taxi'
		AND LOWER(NEW.fase) != 'take off' AND LOWER(NEW.fase) != 'climb'
		AND LOWER(NEW.fase) != 'cruise' AND LOWER(NEW.fase) != 'descent'
		AND LOWER(NEW.fase) != 'holding' AND LOWER(NEW.fase) != 'approach'
		AND LOWER(NEW.fase) != 'landing') THEN
	   RAISE EXCEPTION 'Fase non esistente';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertOrUpdateFase ON sin.incidente CASCADE;

CREATE TRIGGER insertOrUpdateFase
AFTER INSERT OR UPDATE ON sin.incidente
FOR EACH ROW EXECUTE PROCEDURE checkFaseIncidente();

/* 9.1.3) Controllo sull'inserimento del report solo ad indagine conclusa che la data di pubblicazione di
un report non sia antecedente alla data di conclusione di un indagine */

DROP FUNCTION IF EXISTS checkDataPubblicazioneReport() CASCADE;

CREATE FUNCTION checkDataPubblicazioneReport() RETURNS TRIGGER AS $$
BEGIN

	IF((SELECT conclusa
		FROM sin.indagine
		WHERE sin.indagine.IdProtocollo = NEW.indagine) = 'false') THEN
			RAISE EXCEPTION 'Attenzione, non puoi pubblicare un report su un indagine che non è stata conclusa';
	ELSEIF(NEW.dataPubblicazione <
			   (SELECT dataFine
				FROM sin.indagine
				WHERE sin.indagine.IdProtocollo = NEW.indagine)) THEN
					RAISE EXCEPTION 'Attenzione, il report non può essere pubblicato prima della data di conclusione dell''indagine';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertReport ON sin.report CASCADE;

CREATE TRIGGER insertReport
AFTER INSERT ON sin.report
FOR EACH ROW EXECUTE PROCEDURE checkDataPubblicazioneReport();

/* 9.1.4) Controllo che la data di conclusione di un indagine non sia antecedente alla data di inizio di un indagine, e in tal
caso vado a mettere true allo stato conclusa nella tabella indagine*/

DROP FUNCTION IF EXISTS checkDataFineIndagine() CASCADE;

CREATE FUNCTION checkDataFineIndagine() RETURNS TRIGGER AS $$
BEGIN

	IF(NEW.dataFine IS NOT NULL AND
	   NEW.dataFine < NEW.dataInizio) THEN
				RAISE EXCEPTION 'Attenzione, l''indagine non può essere conclusa prima della data di inzio della stessa';
	ELSEIF (NEW.dataFine IS NOT NULL AND
			NEW.dataFine > NEW.dataInizio) THEN
				NEW.conclusa = 'true';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertDataFine ON sin.indagine CASCADE;

CREATE TRIGGER insertDataFine
BEFORE INSERT OR UPDATE ON sin.indagine
FOR EACH ROW EXECUTE PROCEDURE checkDataFineIndagine();

/* 9.1.5)  Restrizione ineerente alla modifica della tabella report, il cui report non permette di modificare il suo identificativo ne
la sua data di pubblicazione */

DROP FUNCTION IF EXISTS checkActionReport() CASCADE;

CREATE FUNCTION checkActionReport() RETURNS TRIGGER AS $$
BEGIN

	RAISE EXCEPTION 'Errore, vietato modificare la tabella!';

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkReportNoUpdate ON sin.report CASCADE;

CREATE TRIGGER checkReportNoUpdate
BEFORE UPDATE ON sin.report
FOR EACH ROW EXECUTE PROCEDURE checkActionReport();

/* 9.1.6) Controllo che l'aeroporto di partenza in volo non coincida con l'aeroporto di arrivo */

DROP FUNCTION IF EXISTS checkAeroporto() CASCADE;

CREATE FUNCTION checkAeroporto() RETURNS TRIGGER AS $$
BEGIN

	IF(NEW.aeroportoDiPartenza = NEW.aeroportoDiArrivo) THEN
		RAISE EXCEPTION 'Attenzione, inserisci un volo valido';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkPartenzaArrivoAeroporto ON sin.volo CASCADE;

CREATE TRIGGER checkPartenzaArrivoAeroporto
AFTER INSERT OR UPDATE ON sin.volo
FOR EACH ROW EXECUTE PROCEDURE checkAeroporto();

/* 9.1.7) Aggiornamento data di ultima modifica ogni volta che inserisco o modifico un analisi condotta in relazione ad una specifica
indagine: RICORDA DI METTERE A DEFUALT LA data di ultima modifica a CURRENT_DATE */

DROP FUNCTION IF EXISTS updateDataModificaAnalisi() CASCADE;

CREATE FUNCTION updateDataModificaAnalisi() RETURNS TRIGGER AS $$
BEGIN

	NEW.dataUltimaModifica = CURRENT_DATE;

RETURN NEW;
END $$ LANGUAGE plpgsql;

/* 9.1.7.1 ANALISI FATTORE ORGANIZZATIVO */
DROP TRIGGER IF EXISTS updateModificaAnalisiFattoreOrganizzativo ON sin.analisiFattoreOrganizzativo CASCADE;

CREATE TRIGGER updateModificaAnalisiFattoreOrganizzativo
BEFORE UPDATE ON sin.analisiFattoreOrganizzativo
FOR EACH ROW EXECUTE PROCEDURE updateDataModificaAnalisi();

/* 9.1.7.2 ANALISI FATTORE UMANO */
DROP TRIGGER IF EXISTS updateModificaAnalisiFattoreUmano ON sin.analisiFattoreUmano CASCADE;

CREATE TRIGGER updateModificaAnalisiFattoreUmano
BEFORE UPDATE ON sin.analisiFattoreUmano
FOR EACH ROW EXECUTE PROCEDURE updateDataModificaAnalisi();

/* 9.1.7.3 ANALISI CONDOTTA DEL VOLO */
DROP TRIGGER IF EXISTS updateModificaAnalisiCondottaDelVolo ON sin.analisiCondottaDelVolo CASCADE;

CREATE TRIGGER updateModificaAnalisiCondottaDelVolo
BEFORE UPDATE ON sin.analisiCondottaDelVolo
FOR EACH ROW EXECUTE PROCEDURE updateDataModificaAnalisi();

/* 9.1.7.4 ANALISI FATTORE AMBIENTALE  */
DROP TRIGGER IF EXISTS updateModificaAnalisiFattoreAmbientale ON sin.analisiFattoreAmbientale CASCADE;

CREATE TRIGGER updateModificaAnalisiFattoreAmbientale
BEFORE UPDATE ON sin.analisiFattoreAmbientale
FOR EACH ROW EXECUTE PROCEDURE updateDataModificaAnalisi();

/* 9.1.7.5 ANALISI FATTORE TECNICO  */
DROP TRIGGER IF EXISTS updateModificaAnalisiFattoreTecnico ON sin.analisiFattoreTecnico CASCADE;

CREATE TRIGGER updateModificaAnalisiFattoreTecnico
BEFORE UPDATE ON sin.analisiFattoreTecnico
FOR EACH ROW EXECUTE PROCEDURE updateDataModificaAnalisi();


/* 9.1.8) Controllo che la data inizio di un indagine non sia antecedente alla data e ora del sinistro ad essa associato */

DROP FUNCTION IF EXISTS checkDataInizioIndagine() CASCADE;

CREATE FUNCTION checkDataInizioIndagine() RETURNS TRIGGER AS $$
BEGIN

	IF(
		(SELECT date(dataOraSinistro)
		FROM sin.VoloReale
		WHERE sin.voloReale.incidente = NEW.incidente) > NEW.dataInizio) THEN
			RAISE EXCEPTION 'Attenzione, non puoi inserire un indagine con data antecedente a quella del sinistro.';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkDataInzioIndagine ON sin.indagine CASCADE;

CREATE TRIGGER checkDataInzioIndagine
AFTER INSERT ON sin.indagine
FOR EACH ROW EXECUTE PROCEDURE checkDataInizioIndagine();

/* 9.1.9) Restrizione ineerente all'inserimento di un incidente nel caso in cui non vi sia un volo
reale che faccia riferimento a quest'ultimo (cardinalità 1,1 lato incidente) */

DROP FUNCTION IF EXISTS checkInserimentoIncidente() CASCADE;

CREATE FUNCTION checkInserimentoIncidente() RETURNS TRIGGER AS $$
BEGIN

	IF (NOT EXISTS(SELECT incidente
				   FROM sin.voloReale
				   WHERE sin.voloReale.incidente = NEW.eventID)) THEN
		RAISE EXCEPTION 'Non può esistere un incidente senza un volo reale che faccia riferimento a quest''ultimo';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkInserimentoIncidente ON sin.incidente CASCADE;

CREATE TRIGGER checkInserimentoIncidente
BEFORE INSERT OR UPDATE ON sin.incidente
FOR EACH ROW EXECUTE PROCEDURE checkInserimentoIncidente();

/* 9.1.10) Controllo che la data di accertamento di un colpevole non sia antecedente alla data di inizio di un indagine */

DROP FUNCTION IF EXISTS checkDataAccertamento() CASCADE;

CREATE FUNCTION checkDataAccertamento() RETURNS TRIGGER AS $$
BEGIN


	IF(NEW.colpevole = 't' AND NEW.dataDiAccertamento IS NOT NULL AND
	   NEW.dataDiAccertamento < (SELECT dataInizio
								 FROM sin.indagine
								 WHERE idProtocollo = NEW.indagine)) THEN
	   RAISE EXCEPTION 'Attenzione, la data di accertamento di un colpevole non può essere antecedente alla data di inizio delle indagini';
	ELSEIF(NEW.colpevole = 't' AND NEW.dataDiAccertamento IS NULL) THEN
	   RAISE EXCEPTION 'Attenzione, per un colpevole è necessario l''inserimento della data di accertazione';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertDataAccertamento ON sin.indagato CASCADE;

CREATE TRIGGER insertDataAccertamento
BEFORE INSERT OR UPDATE ON sin.indagato
FOR EACH ROW EXECUTE PROCEDURE checkDataAccertamento();

/* 9.1.11) Un volo deve far riferimento almeno ad un volo reale */

DROP FUNCTION IF EXISTS checkVolo() CASCADE;

CREATE FUNCTION checkVolo() RETURNS TRIGGER AS $$
BEGIN

	IF(EXISTS (SELECT codiceDelVolo
			   FROM sin.volo
			   WHERE codiceDelVolo  NOT IN (SELECT volo FROM sin.voloReale))) THEN
			   	RAISE EXCEPTION 'Un volo deve far riferimento almeno ad un volo reale';
	END	IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertVolo ON sin.volo CASCADE;

CREATE TRIGGER insertVolo
AFTER INSERT ON sin.volo
FOR EACH ROW EXECUTE PROCEDURE checkVolo();


/* 9.1.12) Un aeromobile deve essere assegnato almeno ad un volo reale */

DROP FUNCTION IF EXISTS checkAeromobile() CASCADE;

CREATE FUNCTION checkAeromobile() RETURNS TRIGGER AS $$
BEGIN

	IF(EXISTS (SELECT codice
			   FROM sin.aeromobile
			   WHERE codice NOT IN (SELECT aeromobile FROM sin.assegnazione))) THEN
			  	RAISE EXCEPTION 'Un aeromobile deve essere assegnato almeno ad un volo reale';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertAeromobile ON sin.aeromobile CASCADE;

CREATE TRIGGER insertAeromobile
AFTER INSERT ON sin.aeromobile
FOR EACH ROW EXECUTE PROCEDURE checkAeromobile();

/* 9.1.13) Un pilota deve essere assegnato almeno ad un volo reale */

DROP FUNCTION IF EXISTS checkPilotaAssegnato() CASCADE;

CREATE FUNCTION checkPilotaAssegnato() RETURNS TRIGGER AS $$
BEGIN

	IF(EXISTS (SELECT idPilota
			   FROM sin.pilota
			   WHERE idPilota NOT IN (SELECT idPilota FROM sin.conduzione))) THEN
			  	RAISE EXCEPTION 'Un pilota deve essere assegnato almeno ad un volo reale';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertPilota ON sin.pilota CASCADE;

CREATE TRIGGER insertPilota
AFTER INSERT ON sin.pilota
FOR EACH ROW EXECUTE PROCEDURE checkPilotaAssegnato();


/* 9.1.14) Non può esistere un incidente senza che sia presente l'entità vittima ad esso associata */

DROP FUNCTION IF EXISTS checkIncidente() CASCADE;

CREATE FUNCTION checkIncidente() RETURNS TRIGGER AS $$
BEGIN

	IF(EXISTS (SELECT eventId
			   FROM sin.incidente
			   WHERE eventId NOT IN (SELECT incidente FROM sin.vittima ))) THEN
			  	RAISE EXCEPTION 'Non può esistere un incidente senza che sia presente l''entità vittima ad esso associata';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertIncidente ON sin.incidente CASCADE;

CREATE TRIGGER insertIncidente
AFTER INSERT  ON sin.incidente
FOR EACH ROW EXECUTE PROCEDURE checkIncidente();

/* 9.1.15) Non può esistere un analisi del fattore organizzativo che non abbia criticità ignorate ad esso associato */

DROP FUNCTION IF EXISTS checkAnalisiFattoreOrganizzativo() CASCADE;

CREATE FUNCTION checkAnalisiFattoreOrganizzativo() RETURNS TRIGGER AS $$
BEGIN

	IF(EXISTS (SELECT idProtocollo
			  FROM sin.analisiFattoreOrganizzativo
			  WHERE idProtocollo NOT IN (SELECT analisi FROM sin.criticitaIgnorate))) THEN
			  	RAISE EXCEPTION 'Non può esistere un''analisi del fattore organizzativo che non abbia criticità ignorate ad essa associate';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertAnalisiFattoreOrganizzativo ON sin.analisiFattoreOrganizzativo CASCADE;

CREATE TRIGGER insertAnalisiFattoreOrganizzativo
AFTER INSERT ON sin.analisiFattoreOrganizzativo
FOR EACH ROW EXECUTE PROCEDURE checkAnalisiFattoreOrganizzativo();

/* 9.1.16) Non può esistere un costruttore che non ha aeromobili ad esso associato*/

DROP FUNCTION IF EXISTS checkCostruttore() CASCADE;

CREATE FUNCTION checkCostruttore() RETURNS TRIGGER AS $$
BEGIN

	IF(EXISTS (SELECT nome
			  FROM sin.costruttore
			  WHERE nome NOT IN (SELECT nomeCostruttore FROM sin.aeromobile))) THEN
			  	RAISE EXCEPTION 'Non può esistere un costruttore che non abbia un aeromobile associato';
	END IF;

RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insertCostruttore ON sin.costruttore CASCADE;

CREATE TRIGGER insertCostruttore
AFTER INSERT ON sin.costruttore
FOR EACH ROW EXECUTE PROCEDURE checkCostruttore();





/* 9.2 TRIGGER PER VINCOLI AZIENDALI */

	/* 9.2.1 Trigger1: Prima di inserire un volo reale o di apportare una modifica in conduzione è necessario che:
	 • nella tabella Conduzione vi siano esattamente due tuple che fanno riferimento a quel volo,
	 • i due piloti svolgano ruoli diversi (uno deve essere un comandante e uno un primo ufficiale). */

	CREATE OR REPLACE FUNCTION checkDuePiloti()
		RETURNS TRIGGER AS $$

	DECLARE
		var_tuple_conduzione INTEGER;
		i INTEGER;
		item RECORD;
		ruolo VARCHAR(15)[];

	BEGIN
		-- Controllo che per il volo reale siano presenti esattamente due tuple in conduzione
		SELECT COUNT(*)
		INTO var_tuple_conduzione
		FROM sin.conduzione
		WHERE idVoloReale = NEW.idVoloReale;

		IF var_tuple_conduzione != 2 THEN
			RAISE EXCEPTION 'Devi assegnare esattamente due piloti alla conduzione di un volo reale.';
		END IF;

		-- Controllo che i due piloti svolgano suoli diversi
		i := 0;
		FOR item IN SELECT * FROM sin.conduzione WHERE idVoloReale = NEW.idVoloReale
		LOOP
			ruolo[i] := item.ruoloAttuale;
			i := i + 1;
		END LOOP;

		IF ruolo[0] = ruolo[1] THEN
			RAISE EXCEPTION 'I due piloti non possono avere lo stesso ruolo: uno deve essere un comandante ed uno un primo ufficiale.';
		END IF;

	RETURN NULL;
	END $$ LANGUAGE plpgsql;

	CREATE OR REPLACE TRIGGER checkDuePiloti
	AFTER INSERT
	ON sin.voloReale
	FOR EACH ROW
	EXECUTE PROCEDURE checkDuePiloti();
	
	CREATE CONSTRAINT TRIGGER updateDuePiloti
	AFTER UPDATE OR DELETE
	ON sin.conduzione
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE checkDuePiloti();

	-- 9.2.2 Trigger2: Il numero di motori in funzione non deve essere maggiore del numero di motori dell'aeromobile.

	CREATE OR REPLACE FUNCTION checkMotoriInFunzione()
		RETURNS TRIGGER AS $$

	DECLARE
		var_num_motori_aeromobile INTEGER;

	BEGIN

		var_num_motori_aeromobile := 
		
		(SELECT A.numeroDiMotori
		FROM sin.aeromobile AS A
		WHERE codice = (SELECT ASS.aeromobile
						FROM sin.assegnazione as ASS
						WHERE idVolo = (SELECT VR.idVoloReale
										FROM sin.voloReale as VR
										WHERE incidente = (SELECT IND.incidente
														   FROM sin.indagine as IND
														   WHERE IND.idProtocollo = NEW.indagine))));

		IF NEW.motoriInFunzione > var_num_motori_aeromobile THEN
			RAISE EXCEPTION 'Il numero di motori in funzione per questo aeromobile non può superare i %.', var_num_motori_aeromobile;
		END IF;

		RETURN NULL;
	END $$ LANGUAGE plpgsql;

	CREATE OR REPLACE TRIGGER checkMotoriInFunzione
	AFTER INSERT OR UPDATE ON sin.analisiCondottaDelVolo
	FOR EACH ROW
	EXECUTE PROCEDURE checkMotoriInFunzione();

	-- 9.2.3 Trigger3: Il numero di passeggeri del volo deve essere minore o uguale del numero massimo di passeggeri per
	-- quell'aeromobile.

	CREATE OR REPLACE FUNCTION checkPasseggeri()
		RETURNS TRIGGER AS $$

	DECLARE
		var_numero_max_passeggeri INTEGER;
		var_numero_passeggeri INTEGER;
		equip INTEGER;
	BEGIN

		SELECT A.numeroMassimoDiPasseggeri, VR.passeggeri, VR.assistentiDiVolo
		INTO var_numero_max_passeggeri, var_numero_passeggeri, equip
		FROM sin.aeromobile as A, sin.assegnazione AS ASS, sin.voloReale AS VR
		WHERE A.codice = ASS.aeromobile AND ASS.idVolo = VR.idVoloReale and VR.idVoloReale = NEW.idVoloReale ;

		IF var_numero_passeggeri + equip + 2 > var_numero_max_passeggeri THEN
			RAISE EXCEPTION 'Non puoi inserire un volo reale con più di % passeggeri per questo aeromobile.', var_numero_max_passeggeri;
		END IF;

		RETURN NULL;
	END $$ LANGUAGE plpgsql;

	CREATE CONSTRAINT TRIGGER checkPasseggeri
	AFTER INSERT OR UPDATE ON sin.voloReale
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE checkPasseggeri();

	-- 9.2.4 Trigger4: Il numero dei deceduti in volo non deve essere maggiore di tutte le persone presenti a bordo
	-- e il numero di sopravvissuti al volo non deve essere superiore al numero di persone a bordo.

	CREATE OR REPLACE FUNCTION checkVittime()
		RETURNS TRIGGER AS $$

		DECLARE
			var_persone_a_bordo INTEGER; -- il numero di persone a bordo si calcola come
										 -- piloti + passeggeri + assistenti di volo
		BEGIN

			var_persone_a_bordo := 2 + (SELECT passeggeri
									    FROM sin.voloReale
									    WHERE incidente = NEW.incidente) + (SELECT assistentiDiVolo
									   									    FROM sin.voloReale
									   									    WHERE incidente = NEW.incidente);

			-- I feriti non vengono contati perchè tra essi potrebbero esserci anche persone ferite a terra.
			IF NEW.sopravvissutiAlVolo + NEW.decedutiInVolo > var_persone_a_bordo THEN
				RAISE EXCEPTION 'La somma di sopravvissuti e deceduti al volo non può superare i % occupanti dell''aeromobile', var_persone_a_bordo;
	    	END IF;

		RETURN NULL;
	END $$ LANGUAGE plpgsql;

	CREATE OR REPLACE TRIGGER checkVittime
	AFTER INSERT OR UPDATE ON sin.vittima
	FOR EACH ROW
	EXECUTE PROCEDURE checkVittime();

	-- 9.2.5 Trigger5: La quantità di carburante alla partenza non deve essere maggiore della capacità del serbatoio.

	CREATE OR REPLACE FUNCTION checkCarburante()
	RETURNS TRIGGER AS $$

	DECLARE
		var_capac INTEGER;

	BEGIN

		var_capac := (SELECT capacitaSerbatoio
					  FROM sin.aeromobile
					  WHERE codice = (SELECT aeromobile
									  FROM sin.assegnazione
									  WHERE idVolo = (SELECT idVoloReale
													 FROM sin.voloReale
													 WHERE incidente = NEW.eventId)));

		IF NEW.carburanteAllaPartenza > var_capac THEN
			RAISE EXCEPTION 'Il carburante alla partenza non può superare i % l.', var_capac;
		END IF;

	RETURN NEW;
	END $$ LANGUAGE plpgsql;

	CREATE OR REPLACE TRIGGER checkCarburante
	BEFORE INSERT OR UPDATE ON sin.incidente
	FOR EACH ROW
	EXECUTE PROCEDURE checkCarburante();

	-- 9.2.6 Trigger6: Se l'aereo è in una delle fasi che si svolgono a terra, non si deve poter inserire l'analisi
	-- che fa riferimento alla condotta del volo.

	CREATE OR REPLACE FUNCTION checkFasi()
	RETURNS TRIGGER AS $$

	DECLARE
		var_fase VARCHAR(30);

	BEGIN

		SELECT fase
		INTO var_fase
		FROM sin.incidente AS INC
			JOIN sin.indagine AS IND ON INC.eventId = IND.incidente
			JOIN sin.analisiCondottaDelVolo AS AN ON IND.idProtocollo = AN.indagine
		WHERE IND.idProtocollo = NEW.indagine;

		IF var_fase = 'parking' OR var_fase = 'taxi' OR var_fase = 'take off'
		THEN
			RAISE EXCEPTION 'Non puoi inserire l''analisi della condotta del volo su un incidente avvenuto a terra.';
		END IF;

		RETURN NULL;
	END $$ LANGUAGE plpgsql;

	CREATE OR REPLACE TRIGGER checkFasi
	AFTER INSERT ON sin.analisiCondottaDelVolo
	FOR EACH ROW
	EXECUTE PROCEDURE checkFasi();

	-- 9.2.7 Trigger7: Ogni volta che si inserisce un incidente, è necessario aggiornare il numero di incidenti per quell'aeromobile che sono
	-- stati registrati nel database.

	CREATE OR REPLACE FUNCTION updateNumeroIncidente()
	RETURNS TRIGGER AS $$

		BEGIN

			UPDATE sin.aeromobile
			SET numeroDiIncidenti = (SELECT COUNT(*)
									 FROM sin.assegnazione AS ASS
									 WHERE ASS.aeromobile = NEW.aeromobile)
			WHERE codice = NEW.aeromobile;

		RETURN NULL;
	END $$ LANGUAGE plpgsql;

	CREATE CONSTRAINT TRIGGER updateNumeroIncidente
	AFTER INSERT ON sin.assegnazione
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE updateNumeroIncidente();





/* Di seguito vengono riportati ulteriori trigger che consentono la gestione delle cancellazioni,
per garantire che le cardinalità siano sempre rispettate anche quando l'ultima istanza di un'entità
con cardinalità (1,N) viene eliminata. */

-- Elimina il Costruttore quando viene elimintata l'ultima istanza di un suo Aeromobile
DROP FUNCTION IF EXISTS deleteCostruttore() CASCADE;

CREATE FUNCTION deleteCostruttore() RETURNS TRIGGER AS $$
BEGIN

	IF(NOT EXISTS (SELECT nomeCostruttore
			  FROM sin.aeromobile
			  WHERE nomeCostruttore = OLD.nomeCostruttore)) THEN
			  	DELETE FROM sin.Costruttore WHERE nome = OLD.nomeCostruttore;
	END IF;

RETURN NULL;
END $$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS deleteAeromobile ON sin.aeromobile CASCADE;

CREATE TRIGGER deleteAeromobile
AFTER DELETE ON sin.aeromobile
FOR EACH ROW EXECUTE PROCEDURE deleteCostruttore();


-- Elimina l'aeromobile quando viene eliminata l'ultima sua assegnazione

DROP FUNCTION IF EXISTS deleteAssegnazione() CASCADE;

CREATE FUNCTION deleteAssegnazione() RETURNS TRIGGER AS $$
BEGIN

	IF(NOT EXISTS (SELECT aeromobile
			  FROM sin.assegnazione
			  WHERE aeromobile = OLD.aeromobile)) THEN
			  	DELETE FROM sin.aeromobile WHERE codice = OLD.aeromobile;
	END IF;

RETURN NULL;
END $$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS deleteAeromobile ON sin.assegnazione CASCADE;

CREATE TRIGGER deleteAssegnazione
AFTER DELETE ON sin.assegnazione
FOR EACH ROW EXECUTE PROCEDURE deleteAssegnazione();


-- Elimina il volo quando viene eliminato l'ultimo volo reale ad esso associato. 

DROP FUNCTION IF EXISTS deleteVoloReale() CASCADE;

CREATE FUNCTION deleteVoloReale() RETURNS TRIGGER AS $$
BEGIN

	DELETE FROM sin.incidente WHERE eventId = OLD.incidente;

	IF(NOT EXISTS (SELECT volo
			  FROM sin.voloReale
			  WHERE volo = OLD.volo)) THEN
			  	DELETE FROM sin.volo WHERE codiceDelVolo = OLD.volo;
	END IF;

RETURN NULL;
END $$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS deleteVoloReale ON sin.voloreale CASCADE;

CREATE TRIGGER deleteVoloReale
AFTER DELETE ON sin.voloReale
FOR EACH ROW EXECUTE PROCEDURE deleteVoloReale();


-- Elimina un pilota quando viene eliminata l'ultima sua conduzione.

DROP FUNCTION IF EXISTS deleteConduzione() CASCADE;

CREATE FUNCTION deleteConduzione() RETURNS TRIGGER AS $$
BEGIN
	
	IF(NOT EXISTS (SELECT idPilota
			  FROM sin.conduzione
			  WHERE idPilota = OLD.idPilota)) THEN
			  	DELETE FROM sin.pilota WHERE idPilota = OLD.idPilota;
	END IF;

RETURN NULL;
END $$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS deleteConduzione ON sin.conduzione CASCADE;

CREATE TRIGGER deleteConduzione
AFTER DELETE ON sin.conduzione
FOR EACH ROW EXECUTE PROCEDURE deleteConduzione();
