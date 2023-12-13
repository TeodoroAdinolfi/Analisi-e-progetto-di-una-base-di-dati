DROP SCHEMA IF EXISTS sin CASCADE;
CREATE SCHEMA sin;

/* CREAZIONE DEI DOMINI PERSONALIZZATI */

-- definizioni dei ruoli che può assumere un pilota
CREATE DOMAIN sin.Domain_Ruolo AS VARCHAR
	CHECK (LOWER(VALUE) = 'comandante' OR LOWER(VALUE)='primo ufficiale');
-- definizione di un dominio per il sesso biologico di una persona
CREATE DOMAIN sin.Domain_Sesso AS VARCHAR
	CHECK (LOWER(VALUE) = 'm' OR LOWER(VALUE)='f');
-- il dominio rappresenta i tre tipi di discesa che possono essere adottati da un'aeromobile
CREATE DOMAIN sin.Domain_Discesa AS VARCHAR
	CHECK (LOWER(VALUE) = 'glide' OR LOWER(VALUE)='powered' OR LOWER(VALUE)='cruise');


CREATE TABLE sin.pilota (
	idPilota INTEGER PRIMARY KEY,
	nome VARCHAR(30) NOT NULL,
	cognome VARCHAR(30) NOT NULL,
	dataDiNascita DATE NOT NULL,
	sesso sin.Domain_Sesso NOT NULL,
	nLicenza VARCHAR(30) NOT NULL,
	paeseDellaLicenza VARCHAR(40) NOT NULL,

	CONSTRAINT ak_pilota UNIQUE(nLicenza, paeseDellaLicenza)

);


CREATE TABLE sin.esperienzeSuAltriAeromobili (
	idEsp INTEGER PRIMARY KEY,
	descrizione VARCHAR(500) NOT NULL,
	idPilota INTEGER NOT NULL,

	CONSTRAINT ak_esperienzeSuAltriAeromobili UNIQUE(descrizione, idPilota),
	CONSTRAINT fk_esperienzeSuAltriAeromobili FOREIGN KEY(idPilota) REFERENCES sin.pilota(idPilota)
																ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE sin.costruttore (
	nome VARCHAR(30) PRIMARY KEY,
	sedePrincipale VARCHAR(30) NOT NULL,
	stato VARCHAR(50) NOT NULL
);


CREATE TABLE sin.aeromobile (
	codice VARCHAR(10) PRIMARY KEY,
	entrataInServizio DATE NOT NULL,
	capacitaSerbatoio INTEGER NOT NULL,
	numeroDiMotori INTEGER NOT NULL CHECK (numeroDiMotori > 0),
	velocitaMassima DECIMAL(6,2) NOT NULL,
	velocitaDiCrociera DECIMAL(6,2) NOT NULL CHECK (velocitaDiCrociera <= velocitaMassima),
	autonomia INTEGER NOT NULL,
	numeroMassimoDiPasseggeri INTEGER NOT NULL CHECK (numeroMassimoDiPasseggeri > 0),
	numeroDiIncidenti INTEGER NOT NULL,
	nomeCostruttore VARCHAR(30) NOT NULL,

	CONSTRAINT fk_aeromobile FOREIGN KEY (nomeCostruttore) REFERENCES sin.costruttore(nome)
																	ON UPDATE CASCADE ON DELETE RESTRICT
																	DEFERRABLE INITIALLY DEFERRED
);


CREATE TABLE sin.volo (
	codiceDelVolo VARCHAR(7) PRIMARY KEY,
	aeroportoDiPartenza VARCHAR(100) NOT NULL,
	aeroportoDiArrivo VARCHAR(100) NOT NULL,
	compagniaAerea VARCHAR(30) NOT NULL,
	oraDiPartenza TIME NOT NULL
);


CREATE TABLE sin.scali (
	aeroporto VARCHAR(100),
	volo VARCHAR(10),

	CONSTRAINT pk_scali PRIMARY KEY(aeroporto,volo),
	CONSTRAINT fk_scali FOREIGN KEY(volo) REFERENCES sin.volo(codiceDelVolo)
											ON UPDATE CASCADE ON DELETE CASCADE

);


CREATE TABLE sin.incidente (
	eventId INTEGER PRIMARY KEY,
	denominazione VARCHAR(100) NOT NULL,
	forma VARCHAR(500) NOT NULL,
	localitaDiRiferimento VARCHAR(100),
	carburanteAllaPartenza INTEGER NOT NULL,
	sistemaDiNavigazione VARCHAR(30) NOT NULL,
	tipoDiNavigazione VARCHAR(100) NOT NULL,
	distanzaDalRiferimento INTEGER,
	fase VARCHAR(30) NOT NULL
);


CREATE TABLE sin.assegnazione (
	idVolo INTEGER PRIMARY KEY,
	aeromobile VARCHAR(10),

	CONSTRAINT fk_assegnazioneAeromobile FOREIGN KEY (aeromobile) REFERENCES sin.Aeromobile(codice)
																			ON UPDATE CASCADE ON DELETE RESTRICT
																			DEFERRABLE INITIALLY DEFERRED
);


CREATE TABLE sin.voloReale (
	idVoloReale INTEGER PRIMARY KEY,
	dataOraPartenza TIMESTAMP NOT NULL,
	numeroDiRegistrazione VARCHAR(10) NOT NULL,
	passeggeri INTEGER NOT NULL,
	assistentiDiVolo INTEGER NOT NULL,
	volo VARCHAR(7) NOT NULL,
	dataOraSinistro TIMESTAMP NOT NULL,
	incidente INTEGER NOT NULL UNIQUE,

	CONSTRAINT ak_voloReale UNIQUE(dataOraPartenza, numeroDiRegistrazione),

	CONSTRAINT ak1_voloReale UNIQUE(dataOraPartenza, volo),

	CONSTRAINT fk_voloRealeIncidente FOREIGN KEY (incidente) REFERENCES sin.incidente(eventId)
														ON UPDATE CASCADE ON DELETE RESTRICT
														DEFERRABLE INITIALLY DEFERRED,

	CONSTRAINT fk_voloRealeVolo  FOREIGN KEY (volo) REFERENCES sin.volo(codiceDelVolo)
														ON UPDATE CASCADE ON DELETE RESTRICT
														DEFERRABLE INITIALLY DEFERRED,

	CONSTRAINT fk_voloRealeAssegnazione FOREIGN KEY (idVoloReale) REFERENCES sin.assegnazione(idVolo)
														ON UPDATE CASCADE ON DELETE RESTRICT
														DEFERRABLE INITIALLY DEFERRED

);


ALTER TABLE sin.assegnazione
ADD FOREIGN KEY (idVolo) REFERENCES sin.voloReale(idVoloReale)
ON UPDATE CASCADE ON DELETE CASCADE;


CREATE TABLE sin.conduzione (
	idPilota INTEGER,
	idVoloReale INTEGER,
	oreDiVoloAttuali INTEGER NOT NULL,
	anniDiServizioAttuali INTEGER NOT NULL,
	controlliObbligatori BOOLEAN DEFAULT 'f' NOT NULL,
	ruoloAttuale sin.Domain_Ruolo NOT NULL,

	CONSTRAINT pk_conduzione PRIMARY KEY(idPilota,idVoloReale),

	CONSTRAINT fk_conduzioneidPilota FOREIGN KEY (idPilota) REFERENCES sin.pilota(idPilota)
														ON UPDATE CASCADE ON DELETE RESTRICT
														DEFERRABLE INITIALLY DEFERRED,

	CONSTRAINT fk_conduzioneidVoloReale FOREIGN KEY (idVoloReale)  REFERENCES sin.voloReale(idVoloReale)
														ON UPDATE CASCADE ON DELETE RESTRICT
														DEFERRABLE INITIALLY DEFERRED
);


CREATE TABLE sin.vittima (
	incidente INTEGER PRIMARY KEY,
	decedutiATerra INTEGER NOT NULL,
	decedutiInVolo INTEGER NOT NULL,
	feriti INTEGER NOT NULL,
	sopravvissutiAlVolo INTEGER NOT NULL,

	CONSTRAINT fk_vittima FOREIGN KEY (incidente) REFERENCES sin.incidente(eventId)
															ON UPDATE CASCADE ON DELETE CASCADE
															DEFERRABLE INITIALLY DEFERRED
);


CREATE TABLE sin.indagine (
	idProtocollo INTEGER PRIMARY KEY,
	incidente INTEGER NOT NULL UNIQUE,
	dataInizio DATE NOT NULL,
	dataFine DATE,
	conclusa BOOLEAN DEFAULT FALSE NOT NULL,

	CONSTRAINT fk_indagine FOREIGN KEY (incidente) REFERENCES sin.incidente(eventId)
															ON UPDATE CASCADE ON DELETE CASCADE

);


CREATE TABLE sin.indagato (
	matricola CHAR(10) PRIMARY KEY,
	nome VARCHAR(30) NOT NULL,
	cognome VARCHAR(30) NOT NULL,
	dataDiNascita  DATE NOT NULL,
	colpevole BOOLEAN DEFAULT FALSE NOT NULL,
	indagine INTEGER NOT NULL,
	dataDiAccertamento DATE,

	CONSTRAINT fk_indagato FOREIGN KEY (indagine) REFERENCES sin.indagine(IdProtocollo)
														ON UPDATE CASCADE ON DELETE CASCADE

);


CREATE TABLE sin.report (
	identificativo INTEGER PRIMARY KEY,
	indagine INTEGER NOT NULL UNIQUE,
	dataPubblicazione DATE NOT NULL,

	CONSTRAINT fk_report FOREIGN KEY (indagine) REFERENCES sin.indagine(IdProtocollo)
														ON UPDATE CASCADE ON DELETE CASCADE

);


CREATE TABLE sin.analisiFattoreOrganizzativo (
	idProtocollo INTEGER PRIMARY KEY,
	responsabile VARCHAR(30) NOT NULL,
	indagine INTEGER NOT NULL UNIQUE,
	dataUltimaModifica DATE NOT NULL,

	CONSTRAINT fk_analisiFattoreOrganizzativo FOREIGN KEY (indagine) REFERENCES sin.indagine(IdProtocollo)
																			ON UPDATE CASCADE ON DELETE CASCADE

);


CREATE TABLE sin.criticitaIgnorate (

	idCritIgn INTEGER PRIMARY KEY,
	descrizione VARCHAR(5000) UNIQUE NOT NULL,
	analisi INTEGER NOT NULL,

	CONSTRAINT fk_criticitaIgnorate FOREIGN KEY (analisi) REFERENCES sin.analisiFattoreOrganizzativo(idProtocollo)
																			ON UPDATE CASCADE ON DELETE CASCADE
																			DEFERRABLE INITIALLY DEFERRED
);


CREATE TABLE sin.analisiFattoreUmano (
	idProtocollo INTEGER PRIMARY KEY,
	responsabile VARCHAR(30) NOT NULL,
	indagine INTEGER NOT NULL UNIQUE,
	dataUltimaModifica DATE NOT NULL,
	erroriDovutiACarenzaDiAbilita VARCHAR(500) NOT NULL,
	erroriDecisionali VARCHAR(500) NOT NULL,
	erroriDiPercezione VARCHAR(500) NOT NULL,
	violazioneDelleProcedure VARCHAR(500) NOT NULL,
	statoMentaleAvverso VARCHAR(500) NOT NULL,

	CONSTRAINT fk_analisiFattoreUmano FOREIGN KEY (indagine) REFERENCES sin.indagine(IdProtocollo)
																		ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE sin.analisiCondottaDelVolo (
	idProtocollo INTEGER PRIMARY KEY,
	responsabile VARCHAR(30) NOT NULL,
	indagine INTEGER NOT NULL UNIQUE,
	dataUltimaModifica DATE NOT NULL,
	velocitaDiDiscesa DECIMAL(6,2) NOT NULL,
	tipologiaDiDiscesa sin.Domain_Discesa NOT NULL,
	motoriInFunzione INTEGER NOT NULL CHECK (motoriInFunzione >= 0),
	altitudine INTEGER NOT NULL CHECK (altitudine >= 0),

	CONSTRAINT fk_analisiCondottaDelVolo FOREIGN KEY (indagine) REFERENCES sin.indagine(IdProtocollo)
																		ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE sin.analisiFattoreAmbientale (
	idProtocollo INTEGER PRIMARY KEY,
	responsabile VARCHAR(30) NOT NULL,
	indagine INTEGER NOT NULL UNIQUE,
	dataUltimaModifica DATE NOT NULL,
	condizioneMeteorologica VARCHAR(30) NOT NULL,
	visibilita VARCHAR(30) NOT NULL,
	temperatura INTEGER NOT NULL,
	umidita INTEGER NOT NULL,
	direzioneVento VARCHAR(30),
	velocitaVento INTEGER ,

	CONSTRAINT fk_analisiFattoreAmbientale FOREIGN KEY (indagine) REFERENCES sin.indagine(IdProtocollo)
																		ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE sin.analisiFattoreTecnico (
	idProtocollo INTEGER PRIMARY KEY,
	responsabile VARCHAR(30) NOT NULL,
	indagine INTEGER NOT NULL UNIQUE,
	dataUltimaModifica DATE NOT NULL,
	condizioniDellAeromobile VARCHAR(30) NOT NULL,
	sistemiDiSopravvivenza BOOLEAN NOT NULL,
	autopilota BOOLEAN NOT NULL,
	descrizionePartiPerse VARCHAR(3000),

	CONSTRAINT fk_analisiFattoreTecnico FOREIGN KEY (indagine) REFERENCES sin.indagine(IdProtocollo)
																		ON UPDATE CASCADE ON DELETE CASCADE
);

--SCRIPT DI CREAZIONE
-- L'inserimento dei dati avviene all'interno di una transazione per permettere il corretto funzionamento dei vincoli deferred.
BEGIN;
INSERT INTO sin.conduzione VALUES
	(0, 0, 6709, 3, 'true', 'comandante'),
	(1, 0, 31769, 15, 'true', 'primo ufficiale'),
	(22, 11, 17750, 10, 'true', 'comandante'),
	(23, 11, 8140, 5, 'true', 'primo ufficiale'),
	(28, 12, 11636, 14, 'true', 'comandante'),
	(29, 12, 7295, 12, 'true', 'primo ufficiale'),
	(26, 13, 4416, 5, 'true', 'comandante'),
	(27, 13, 608, 2, 'true', 'primo ufficiale'),
	(28, 14, 11636, 14, 'true', 'comandante'),
	(29, 14, 7295, 12, 'true', 'primo ufficiale'),
	(30, 15, 11235, 15, 'true', 'comandante'),
	(31, 15, 7869, 9, 'true', 'primo ufficiale'),
	(2, 1, 3340, 2, 'true', 'comandante'),
	(3, 1, 1253, 1, 'true', 'primo ufficiale'),
	(4, 2, 8955, 8, 'true', 'comandante'),
	(5, 2, 6543, 5, 'true', 'primo ufficiale'),
	(6, 3, 3450, 3, 'true', 'comandante'),
	(7, 3, 4280, 5, 'true', 'primo ufficiale'),
	(32, 16, 7443, 10, 'true', 'comandante'),
	(33, 16, 788, 2, 'true', 'primo ufficiale'),
	(34, 17, 10795, 14, 'true', 'comandante'),
	(35, 17, 11305, 15, 'true', 'primo ufficiale'),
	(62, 31, 17200, 23, 'true', 'comandante'),
	(63, 31, 14000, 21, 'true','primo ufficiale'),
	(64, 32, 12312, 10, 'true','comandante'),
	(65, 32, 11876, 9, 'true','primo ufficiale'),
	(42, 21, 16800, 22, 'true', 'comandante'),
 	(43, 21, 4800, 15, 'true', 'primo ufficiale'),
 	(44, 22, 2900, 14, 'true', 'comandante'),
 	(45, 22, 1800, 9, 'true', 'primo ufficiale'),
 	(46, 23, 15900, 20, 'true', 'comandante'),
 	(47, 23, 1400, 7, 'true', 'primo ufficiale');


INSERT INTO sin.pilota VALUES
	(0, 'Yang', 'Hongda', '1991/10/10', 'M', 'AB84729', 'Cina'),
	(1, 'Zhang', 'Zhengping', '1980/04/01', 'M', 'AB84738', 'Cina'),
	(22, 'Ted', 'Thompson', '1947/07/21', 'M', '3427644', 'Stati Uniti'),
	(23, 'William', 'Tansky', '1943/12/12', 'M', '6739342', 'Stati Uniti'),
	(26, 'Daniel', 'Thomas', '1963/10/10', 'M', 'TA1178', 'Sultanato dell''Oman'),
	(27, 'James', 'Charles', '1975/02/24', 'M', 'CA558', 'Sultanato dell''Oman'),
	(28, 'Edward', 'Maxwell', '1956/04/02', 'M', 'YK650RL', 'Nairobi'),
	(29, 'James', 'Hand', '1957/07/21', 'M', 'YK1197AL', 'Nairobi'),
	(30, 'Martin', 'McClellan', '1959/08/16', 'M', 'OI483HF', 'Singapore'),
	(31, 'John', 'Varner', '1964/02/01', 'M', 'OI938HF', 'Singapore'),
	(2, 'Dmitry Alexandrovich','Nikiforov', '1987/02/03', 'M', 'CDE14023', 'Russia'),
	(3, 'Alexander Vyacheslavovich','Anisimov', '1994/12/21', 'M', 'CDE14034', 'Russia'),
	(4, 'Vyacheslav Vladimirovich', 'Shpak', '1964/11/04', 'M', 'CFE24024', 'Russia'),
	(5, 'Vladimir Alexandrovich', 'Danchenko', '1971/10/02', 'M', 'CDS15523', 'Russia'),
	(6, 'Tadeusz', 'Kucharski', '1979/02/24', 'M', 'CSU24126', 'Bielorussia'),
	(7, 'Eliasz', 'Rutkowski', '1971/09/13', 'M', 'CFT15642', 'Bielorussia'),
	(32, 'Abdullah', 'Khadr', '1950/02/26', 'M', '561', 'Egitto'),
	(33, 'Amr', 'Shaafei', '1979/01/01', 'M', '3284', 'Egitto'),
	(34, 'Liam', 'Stewart', '1956/02/02', 'M', 'TJ65893', 'Canada'),
	(35, 'Bailey', 'Thorpe', '1956/12/29', 'M', 'TJ28482', 'Canada'),
	(62,'Russom','Petros','1966/05/31','M', 'GPB15', 'Nigeria'),
	(63,'Negisti','Welde','1967/04/12','F', 'STT86', 'Nigeria'),
	(64,'Ivan Ivanovich','Korogodin','1957/07/12','M', 'NSS78', 'URSS'),
	(65,'Vladimir Vladimirovich','Onishchenko','1967/02/14','M', 'NUD35', 'URSS'),
	(42, 'Robert', 'Piché', '1952/11/05', 'M', 'ATPL234', 'Canada'),
	(43, 'Dirk', 'De Jager', '1972/04/21', 'M', 'ATPL654', 'Germania'),
	(44, 'Miłosz', 'Ostrowski', '1971/03/03', 'M', 'LIT345', 'Lituania'),
	(45, 'Abdullahi', 'Odland', '1979/04/21', 'M', 'NOV256', 'Norvegia'),
	(46, 'Victor ', 'Blake', '1954/04/21', 'M', 'US3454', 'Stati Uniti'),
	(47, 'Melvin', 'London', '1981/07/17', 'M', 'US1067', 'Stati Uniti');


INSERT INTO sin.esperienzeSuAltriAeromobili VALUES
	(0, 'Douglas DC-9', 22),
	(1, 'DC-9, DC-6, DC-7', 23),
	(2, 'Lockheed L1011, Boeing 767', 26),
	(3, 'F27, F50, B737-200, B737-300', 28),
	(4, 'DC9', 29),
	(5, '747-400, A310-200', 30),
	(6, 'ha lavorato anche su AN-2', 2),
	(7, 'ha lavorato anche su Diamond DA40 e Diamond DA42', 3),
	(8, 'Ha pilotato anche l''AN-2', 4),
	(9, 'Ha pilotato anche l''AN-2', 5),
	(10, 'L29, Mig17, Mig21, Buffalo, C130', 32),
	(11, '737-300', 33),
	(12, 'Boeing 727, Boeing 737, Boeing 757, Convair 580, Fokker 100', 34),
	(13, 'Convair 580, Lockheed 1011', 35),
	(14, 'Il pilota ha sempre pilotato veivoli della famiglia Boing', 62),
	(15, 'Il pilota aveva 5956 ore di esperienza sul Tu-154 e le restanti su altri aeromobili', 64),
	(16, 'Il pilota aveva 2200 ore di esperienza sul TU-154 e le restanti su altri aeromobili', 65);


INSERT INTO sin.voloreale VALUES
	(0, '2022/03/21 13:15', 'B-1791', 123, 7, 'MU5735', '2022/03/21 14:25', 0),
	(11, '2000/01/31 14:30', 'N963AS', 83, 3, 'AS261', '2000/01/31 16:17', 11),
	(12, '2000/01/10 17:54', 'HB-AKK', 7, 1, 'CRX498', '2000/01/10 17:57', 12),
	(13, '2000/08/23 16:52', 'A4O-EK', 135, 6, 'GF072', '2000/08/23 19:30', 13),
	(14, '2000/01/30 21:08', '5Y-BEN', 169, 8, 'KQ431', '2000/01/30 21:09', 14),
	(15, '2000/10/31 22:57', '9V-SPK', 159, 19, 'SQ006', '2000/10/31 23:18', 15),
	(1, '2021/07/06 12:57', 'RA-26085', 22, 4, 'PTK251', '2021/07/06 15:05', 1),
	(2, '2012/09/12 10:15', 'RA-28715', 12, 0, 'PTK251', '2012/09/12 12:18', 2),
	(3, '2021/05/23 10:20', 'SP-RSM', 126, 4, 'FR4978', '2021/05/23 12:57', 3),
	(16, '2004/01/03 04:42', 'SU-ZCF', 142, 4, 'FA604', '2004/01/03 04:45', 16),
	(17, '2005/03/06 06:30', 'C-GPAT', 262, 7, 'TSC961', '2005/03/06 07:02', 17),
	(31,'2006/10/29 08:10','5N-BFK',100,3,'ADC53','2006/10/29 11:30',31),
	(32,'2006/08/22 12:05','RA-85185',160,8,'PLK612','2006/08/22 13:57',32),
	(21, '2001/08/24 00:52', 'C-GITS', 293, 13, 'TSC236', '2001/08/24 06:23', 21),
	(22, '2001/10/04 11:22', 'RA-85693', 66, 12, 'SBI1812', '2001/10/04 13:44', 22),
	(23, '2001/11/12 08:05', 'N14053', 251, 9, 'AA587', '2001/11/12 09:16', 23);


INSERT INTO sin.assegnazione VALUES
	(0, '737-800'),
	(11, 'MD-80'),
	(12, '340B'),
	(13, 'A319-100'),
	(14, 'A310-304'),
	(15, '747-412'),
	(1, 'AN-26'),
	(2, 'AN-28'),
	(3, '737NG'),
	(16, '737-3Q8'),
	(17, 'A310-304'),
	(31,'737-200'),
	(32,'Tu-154M'),
	(21, 'A330-243'),
   	(22, 'Tu-154R'),
   	(23, 'A300-605R');


INSERT INTO sin.aeromobile VALUES
	('737-800', '1998/04/23', 26022, 2, 1012, 976, 5435, 189, 0, 'Boeing'), -- capacità in litri, velocità in km/h
	('MD-80', '1980/10/18', 22129, 2, 987, 938, 5093, 172, 0, 'McDonnell Douglas'),
	('340B', '1983/01/25', 5058, 2, 550, 531, 1553, 37, 0, 'Saab'),
	('A319-100', '1995/08/25', 23859, 2, 1012, 963, 6200, 195, 0, 'Airbus'),
	('A310-304', '1982/04/03', 61070, 2, 1037, 987, 8050, 280, 0, 'Airbus'),
	('747-412', '1969/02/08', 216824, 4, 1136.02, 1061.92, 660, 13490, 0, 'Boeing'),
	('AN-26','1969/05/21', 20123, 2, 500, 440, 2550, 40, 0, 'Antonov'),
	('AN-28','1989/12/08', 10231, 2, 355, 283, 510, 18, 0, 'Antonov'),
	('737NG','1998/09/18', 26022, 2, 1012, 976, 5990, 189, 0, 'Boeing'),
	('737-3Q8', '1984/02/24', 23827, 2, 1012.54, 926.10, 4175, 149, 0, 'Boeing'),
	('737-200', '1967/08/08', 22596 , 2, 1012, 926, 5185, 136, 0, 'Boeing'),
	('Tu-154M','1968/10/04',58455,3,950,850,5200,180,0,'Tupolev'),
	('A330-243', '1994/01/17', 139090, 2, 1061.92, 1012.54, 11750, 440, 0, 'Airbus'),
	('Tu-154R', '1968/02/04', 58455, 3, 950, 850, 5200, 180, 0, 'Tupolev'),
	('A300-605R', '1972/10/28', 68160, 3, 1037.23, 1012.53, 7500, 361, 0, 'Airbus');


INSERT INTO sin.costruttore VALUES
	('Boeing', 'Chicago', 'Stati Uniti'),
	('McDonnell Douglas', 'Saint Louis', 'Stati Uniti'),
	('Saab', 'Stoccolma', 'Svezia'),
	('Airbus', 'Blagnac', 'Francia'),
	('Antonov', 'Kiev', 'Ucraina'),
	('Tupolev', 'Mosca', 'Russia');


INSERT INTO sin.volo VALUES
	('MU5735', 'Aeroporto Internazionale di Kunming-Changshui', 'Aeroporto di Canton-Baiyun', 'China Eastern Airlines', '13:15'),
	('AS261', 'Aeroporto Internazionale Lic. Gustavo Díaz Ordaz, Puerto Vallarta, Messico', 'Aeroporto Internazionale di Seattle-Tacoma, Seattle, Stati Uniti', 'Alaska Airlines', '14:30'),
	('CRX498', 'Aeroporto di Zurigo, Zurigo, Svizzera', 'Aeroporto di Dresda, Dresda, Germania', 'Crossair', '18:00'),
	('GF072', 'Aeroporto Internazionale del Cairo, Il Cairo, Egitto', 'Aeroporto Internazionale del Bahrein, Manama, Bahrein', 'Gulf Air', '16:00'),
	('KQ431', 'Aeroporto di Abidjan-Félix Houphouët Boigny, Abidjan, Costa d''Avorio', 'Aeroporto Internazionale Jomo Kenyatta, Nairobi, Kenya', 'Kenya Airways', '21:08'),
	('SQ006', 'Aeroporto di Singapore-Changi, Singapore', 'Aeroporto Internazionale di Los Angeles, Los Angeles, Stati Uniti', 'Singapore Airlines', '21:53'),
	('PTK251', 'Aeroporto di Petropavlovsk', 'Aeroporto di Palana', 'Kamchatka Aviation Enterprise', '11:00'),
	('FR4978', 'Aeroporto Internazionale di Atene', 'Aeroporto Internazionale di Vilnius', 'Rayanair', '10:20'),
	('FA604', 'Aeroporto internazionale di Sharm el-Sheikh, Egitto', 'Aeroporto di Parigi-Roissy, Parigi, Francia', 'Flash Airlines', '04:42'),
	('TSC961', 'Aeroporto Juan Gualberto Gómez, Varadero, Cuba', 'Aeroporto Internazionale di Québec-Jean Lesage, Québec, Québec', 'Air Transat', '06:30'),
	('ADC53','Aeroporto Internazionale Nnamdi Azikiwe','Aeroporto Internazionale Sadiq Abubakar III','ADC Airlines','8:05'),
	('PLK612','Aeroporto di Anapa-Vitjazevo','Aeroporto di San Pietroburgo-Pulkovo','Pulkovo Airlines ','12:00'),
	('TSC236', 'Aeroporto Internazionale di Toronto-Pearson', 'Aeroporto di Lisbona', 'Air Transat', '00:10'),
   	('SBI1812', 'Aeroporto di Tel Aviv Ben Gurion', 'Aeroporto di Novosibirsk-Tolmačëvo', 'Siberia Airlines', '11:45'),
   	('AA587', 'Aeroporto internazionale John F. Kennedy', 'Aeroporto internazionale Las Américas,', 'American Airlines', '08:11');


INSERT INTO sin.scali VALUES
	('Aeroporto Internazionale di San Francisco, California, Stati Uniti', 'AS261'),
	('Aeroporto Internazionale Murtala Muhammed, Lagos, Nigeria', 'KQ431'),
	('Aeroporto di Taipei-Taoyuan, Taoyuan, Taiwan', 'SQ006'),
	('Aeroporto Internazionale del Cairo, Il Cairo, Egitto', 'FA604'),
	('Aeroporto Internazionale Murtala Muhammed','ADC53');


INSERT INTO sin.vittima VALUES
	(0, 0, 132, 0, 0),
	(11, 0, 88, 0, 0),
	(12, 0, 10, 0, 0),
	(13, 0, 143, 0, 0),
	(14, 0, 159, 10, 10),
	(15, 0, 83, 71, 96),
	(1, 0, 28, 0, 0),
	(2, 0, 10, 4, 4),
	(3, 0, 0, 0, 132),
	(16, 0, 148, 0, 0),
	(17, 0, 0, 0, 271),
	(31,0,96,9,9),
	(32,0,170,0,0),
	(21, 0, 0, 18, 306),
	(22, 0, 78, 0, 0),
	(23, 0, 260, 0, 0);


INSERT INTO sin.incidente VALUES
	(0, 'Volo China Eastern Airlines 5735', 'nelle regioni montuose della Contea di Teng', NULL, 26022, 'GNSS', 'navigazione strumentale', NULL, 'descent'),
	(11, 'Volo Alaska Airlines 261', 'al largo dell''isola di Anacapa', 'Isola di Anacapa, California', 22129, 'GNSS', 'navigazione strumentale', 5, 'descent'),
	(12, 'Volo Crossair 498', 'vicino alle case di Niederhasli', 'Aeroporto Kloten di Zurigo', 4000, 'GNSS', 'navigazione strumentale', 5, 'climb'),
	(13, 'Volo Gulf Air 072', 'al largo del golfo Persico', 'Aeroporto Internazionale di Bahrein', 20189, 'FMS', 'navigazione stimata e osservata', 5, 'approach'),
	(14, 'Volo Kenya Airways 431', 'al largo della costa Costa d''Avorio', 'Aeroporto Internazionale Murtala Muhammed, Lagos, Nigeria', 50107, 'GNSS', 'navigazione strumentale', 2, 'cruise'),
	(15, 'Volo Singapore Airlines 006', 'Aeroporto di Taipei-Taoyuan', 'Aeroporto di Taipei-Taoyuan', 200183, 'INS', 'navigazione inerziale', 0, 'take off'),
	(1, 'Volo Petropavlovsk-Kamchatsky Air 251 (2021)', 'nei pressi dell''aeroporto di Palana', NULL, 20123, 'GNNS', 'navigazione strumentale', NULL, 'landing'),
	(2, 'Volo Petropavlovsk-Kamchatsky Air 251 (2012)', 'nei pressi dell''aeroporto di Palana', NULL, 10231, 'GNNS', 'navigazione strumentale', NULL, 'landing'),
	(3, 'Volo Ryanair 4978', 'prima di atterrare il Lituania', '90 miglia a ovest di Minsk', 26022,  'GNNS', 'navigazione strumentale', 145, 'landing'),
	(16, 'Volo Flash Airlines 604', 'vicino a Sharm el-Sheikh', 'Sharm el Sheikh', 20765, 'GMNS', 'navigazione strumentale', 15, 'climb'),
	(17, 'Volo Air Transat 961', 'Aeroporto Juan Gualberto Gómez', NULL, 40294, 'GMNS', 'navigazione strumentale', NULL, 'cruise'),
	(31,'Volo Aviation Development Company (ADC) Airlines 53','Vicino all''aeroporto Internazionale Nnamdi Azikiwe','Tungar Madaki',22596,'GNSS','navigazione strumentale', 2, 'cruise'),
	(32,'Volo Pulkovo Airlines 612','Nord di Donec''k','Donec''k',35000,'GNSS','navigazione a vista', 5, 'cruise'),
	(21, 'Volo Air Transat 236', '10500 metri sopra l''oceano atlantico', NULL, 68497, 'FMS', 'navigazione strumentale', NULL, 'descent'),
	(22, 'Volo Siberia Airlines 1812', 'durante il volo', NULL, 41497, 'GNSS', 'a vista', NULL, 'cruise'),
	(23, 'Volo American Airlines 587', 'Su una zona residenziale del Queens', 'New York', 56897, 'FMS', 'navigazione inerziale', NULL, 'descent');


INSERT INTO sin.indagine VALUES
	(0, 0, '2022/03/23', NULL, 'false'),
	(11, 11, '2000/02/03', '2002/12/26', 'true'),
	(12, 12, '2000/01/13', '2002/10/21', 'true'),
	(13, 13, '2000/08/27', '2002/07/13', 'true'),
	(14, 14, '2000/02/04', '2002/02/18', 'true'),
	(15, 15, '2000/11/05', '2002/05/06', 'true'),
	(1, 1, '2021/07/06', NULL, 'false'),
	(2, 2, '2012/09/13', '2013/01/13', 'true'),
	(3, 3, '2021/05/23', '2022/01/07', 'true'),
	(16, 16, '2004/01/07', '2006/04/15', 'true'),
	(17, 17, '2005/03/06', '2007/06/21', 'true'),
	(31,31,'2006/12/09','2008/04/03','true'),
	(32,32,'2006/09/02','2007/05/14','true'),
	(21, 21, '2001/09/10', '2004/09/12', 'true'),
    (22, 22, '2001/11/04', '2003/10/12', 'true'),
    (23, 23, '2001/12/13', '2003/01/07', 'true');


INSERT INTO sin.indagato VALUES
	('ABTFV51837', 'Oliver', 'Connor', '1945/07/21', 'true', 11, '2002/11/10'),
	('ABTFV56294', 'Edward', 'Maxwell', '1958/07/23', 'true', 12, '2002/09/23'),
	('ABTFV57643', 'James', 'Hand', '1965/03/15', 'false', 12, NULL),
	('ABTFV61564', 'Daniel', 'Thomas', '1963/10/10', 'true', 13, '2001/07/13'),
	('ABTFV66453', 'Edward', 'Maxwell', '1956/04/02', 'false', 14, NULL),
	('ABTFV67765', 'James', 'Hand', '1957/07/21', 'true', 14, '2002/01/04'),
	('ABTFV68245', 'Phillip', 'Carpenter', '1961/02/11', 'false', 14, NULL),
	('ABTFV71753', 'Martin', 'McClellan', '1959/08/16', 'true', 15, '2001/05/26'),
	('ABTFV72835', 'John', 'Varner', '1964/02/01', 'true', 15, '2001/04/27'),
	('ABTFV73465', 'Raymond', 'Gran', '1970/05/06', 'false', 15, NULL),
	('ABTFV14564', 'Dmitry Alexandrovich','Nikiforov', '1987/02/03', 'false', 1, NULL),
	('ABTFV26434', 'Alexander Vyacheslavovich','Anisimov', '1994/12/21', 'false', 1, NULL),
	('ABTFV62464', 'Vyacheslav Vladimirovich', 'Shpak', '1964/11/04', 'true', 2, '2012/10/18'),
	('ABTFV77545', 'Vladimir Alexandrovich', 'Danchenko', '1971/10/02', 'true', 2, '2012/11/27'),
	('ABTFV76243', 'Abdullah', 'Khadr', '1950/02/26', 'true', 16, '2006/02/14'),
	('ABTFV00001','Russom','Petros','1966/05/31','t',31, '2007/12/25'),
	('ABTFV00002','Negisti','Welde','1967/04/12','t',31, '2008/01/12'),
	('ABTFV00004','Ivan Ivanovich','Korogodin','1957/07/12','t',32, '2006/10/03'),
	('ABTFV00005','Vladimir Vladimirovich','Onishchenko','1967/02/14','t',32, '2006/10/17'),
	('ABTFV00006', 'Rocky', 'McDowell', '1957/09/09', 'true', 21, '2004/08/15'),
	('ABTFV00007', 'Chappell', 'Couet', '1984/06/21', 'false', 21, NULL),
	('ABTFV00008', 'Gerth', 'Johansen', '1941/09/04', 'true', 22, '2002/12/24'),
	('ABTFV00009', 'Sebastian', 'Holst', '1977/11/28', 'true', 22, '2002/10/08'),
	('ABTFV00010', 'Victor', 'Blake', '1954/04/21', 'false', 23, NULL);


INSERT INTO sin.report VALUES
	(91040, 11, '2002/12/30'),
	(17819, 12, '2002/10/21'),
	(38572, 13, '2002/07/16'),
	(13095, 14, '2002/02/18'),
	(91834, 15, '2002/05/06'),
	(48593, 2, '2013/01/31'),
	(83940, 3, '2022/01/07'),
	(93821, 16, '2006/04/15'),
	(48275, 17, '2007/06/21'),
	(87631, 31, '2008/04/15'),
	(87632,32,'2007/05/14'),
	(31899, 21, '2004/10/18'),
    (57897, 22, '2003/11/04'),
    (74396, 23, '2004/10/26');


INSERT INTO sin.criticitaIgnorate VALUES
	(21, 'manutenzione inadeguata', 55),
	(23, 'mancanza di formazione', 65),
	(25, 'inadeguatezza nei programmi di addestramento dell''A320 della compagnia aerea', 65),
	(26, 'il sistema di analisi dei dati di volo della compagnia aerea non funzionava in modo soddisfacente', 65),
	(29, 'chiusura della pista non correttamente segnalata', 75),
	(3, 'I piloti non hanno concotto un addestramento pre-volo e non hanno richiesto informazioni sull previsioni meteorologiche. Il navigatore del volo non ha controllato l''equipaggio.', 10),
	(5, 'I piloti sono stati infromati dalle autorità bielorusse di una potenziale minaccia per la sicurezza a bordo e istruiti a far atterrare l''aereo a Minsk', 15),
	(33, 'Il programma di ispezione raccomandato dal produttore per l''aereo non era adeguato per rilevare tutti i difetti del timone', 85),
	(63,'Il sinistro evidenzia una mancanza, di la compagnia aerea era a conoscenza, nelle SOP (standard operating procedures) ovvero la preparazione dei propri piloti circa eventuali operazioni di volo in condizioni metereologiche avverseavverse',160),
	(41, 'Installazione errata', 105),
    (43, 'Esercitazione militare in corso non segnalata', 110),
    (45, 'Turbolenza non gestita', 115);


INSERT INTO sin.analisiFattoreOrganizzativo VALUES
	(55, 'Charlie Kyle', 11, '2002/10/13'),
	(65, 'Christian Wagner', 13, '2002/05/21'),
	(75, 'Octavio Sarris', 15, '2001/10/04'),
	(10, 'Carl Repin', 2, '2013/01/31'),
	(15, 'Spencer Browne', 3, '2022/01/07'),
	(85, 'Reece Taylor', 17, '2007/03/11'),
	(160,'Arthur Andreeff',32,'2007/03/14'),
	(105, 'Walter Beneventi', 21, '2003/10/13'),
   	(110, 'Wyatt  Harquin', 22, '2002/07/01'),
   	(115, 'Steven  Hicks', 23, '2003/11/26');


INSERT INTO sin.analisiFattoreUmano VALUES
	(61, 'William Damian', 12, '2002/08/11', 'tecnica scadente', 'risposta sbagliata all''emergenza', 'disorientamento spaziale', 'regole di formazione violate', 'stato fisiologico alterato'),
	(66, 'Clarence McGinnis', 13, '2002/06/12', 'non è riuscito a dare priorità all''attenzione', 'procedura inadeguata', 'disorientamento spaziale', 'non ha aderito al brief', 'incapacità fisiologica'),
	(71, 'Eloy Aiello', 14, '2001/11/09', 'rottura della scansione visiva', 'emergenza mal diagnosticata', 'quota sbagliata', 'non è riuscito a utilizzare l''altimetro radar', 'stato psicologico non alterato'),
	(76, 'Kenneth White', 15, '2001/12/14', 'non è riuscito a dare priorità all''attenzione', 'manovra inappropriata', 'disorientamento spaziale', 'non si è preparato adeguatamente per il volo', 'stato psicologico non alterato'),
	(6, 'Carl Artemiev', 1, '2022/06/09', 'Si sono verificati errori di pilotaggio.', 'Risposta sbagliata all''emergenza.', 'Disorientamento spaziale.', 'Nessuna violazione.', 'Probabilmente non ci sono stati errori dovuti allo stato mentale avverso del pilota.'),
	(11, 'Klim Abdulov', 2, '2013/01/31', 'Nessuno', 'Brusco aumento della tangente', 'Nessuno', 'Nessuna', 'Entrambi i piloti erano in intossicazione alcolica.'),
	(81, 'Dino Pisani', 16, '2005/03/19', 'addestramento inadeguato', 'risposta sbagliata all''emergenza', 'disorientamento spaziale', 'regole di formazione violate', 'stato psicologico non alterato'),
	(156,'Jamal Knook',31,'2008/03/15','Il pilota non ha ricevuto un addestramento adeguato per gestire situazioni di windshear','Nonostante fosse a conoscenza delle condizioni metorologiche ha deciso di condurre comunque il volo','Nessuno','Per tutto il periodo dell''emergenza (dal primo avviso di wind shear all''impatto al suolo'') le risposte del copilota non erano conformi alle corrette procedure di recupero','Nessuno'),
	(161,'Nahum Bezrukov',32,'2007/04/14','Nessuno','L''equipaggio, portando l''aereo ad un''altitudine eccessiva per sfuggire alle proibitive condizioni meteo, inclinò troppo l''aereo verso l''alto causando uno stallo aerodinamico','Nesusno','Nessuna','Nessuno'),
	(116, 'William Defoe', 23, '2002/08/11', 'Piloti che cercano di evitare la turbolenza', 'risposta sbagliata all''emergenza, con manovre pericolose', 'disorientamento spaziale', 'regole di formazione violate', 'stato fisiologico alterato');


INSERT INTO sin.analisiCondottaDelVolo VALUES
	(2, 'Xin Qian Hsiao', 0, '2022/06/09', 157.73, 'powered', 2, 8900), -- altitudine in metri e velocità in nodi
	(57, 'Harry Callum', 11, '2002/08/20', 180, 'powered', 2, 5600),
	(62, 'Kauko Hanski', 12, '2002/07/10', 100, 'powered', 2, 3100),
	(67, 'Bernard Maffei', 13, '2002/05/19', 221, 'powered', 2, 306),
	(72, 'James Laigan', 14, '2002/01/17', 201, 'powered', 2, 500),
	(7, 'Maxim Alekseyeva', 1, '2022/06/09', 110.2,'powered', 2, 200),
	(12, 'Constantine Mironov', 2, '2013/01/31', 135, 'powered', 2, 60),
	(82, 'Grossman Lothran', 16, '2005/05/21', 416, 'powered', 2, 1060),
	(107, 'Harry Callum', 21, '2003/11/20', 370, 'glide', 0, 3560),
    (112, 'Antonio Argento', 22, '2002/09/09', 361, 'powered', 2, 2356),
    (117, 'Ermen Geryl', 23, '2003/02/14', 224, 'powered', 2, 4980);


INSERT INTO sin.analisiFattoreTecnico VALUES
	(59, 'Thomas Joe', 11, '2002/10/26', 'destroyed', 'true', 'false', 'fusoliera, componenti delle ali, motori'),
	(64, 'Amarante Charpie', 12, '2002/08/04', 'destroyed', 'true', 'false', NULL),
	(69, 'Walter Waller', 13, '2002/05/10', 'destroyed', 'true', 'false', NULL),
	(74, 'Jeremy Davis', 14, '2002/01/23', 'destroyed', 'true', 'false', NULL),
	(79, 'David Loop', 15, '2002/01/05', 'destroyed', 'true', 'false', NULL),
	(9, 'Constantine Mironov', 1, '2022/06/09', 'Detriti piccoli', 'true', 'false', 'Un frammento di fusoliera è stato trovato sul pendio della collina Pyatibratka e un altro frammento si trovava nel mare, a quattro chilometri dalla costa.'),
	(14, 'Maxim Alekseyeva', 2, '2013/01/31', 'destroyed', 'true', 'false', 'Solo la coda è sopravvissuta, tutto il resto è andato distrutto in una foresta.'),
	(84, 'Hildibrand Gamgee', 16, '2005/02/14', 'destroyed', 'true', 'false', NULL),
	(89, 'Nicholas Flynn', 17, '2007/03/11', 'substantial', 'true', 'true', NULL),
	(109, 'Thomas Striker', 21, '2002/10/26', 'Ruote e carrello distrutti', 'true', 'false', 'carrello, pneumatici'),
	(119, 'Giuseppe Leryt', 23, '2003/03/12', 'Distruzione aeromobile', 'true', 'false', 'detristi sparsi di tutte le parti');


INSERT INTO sin.analisiFattoreAmbientale VALUES
	(3, 'Lennart Hau', 0, '2022/06/09', 'vento forte', 'buona', 25, 100, 'SE', 30), -- velocità del vento in nodi, umidità in percentuale
	(63, 'Albina Woźniak', 12, '2002/09/08', 'pioggia', 'scarsa', 9, 83, NULL, NULL),
	(68, 'Truman Barnett', 13, '2002/04/12', 'sereno', 'ottima', 34, 12, 'N', 8),
	(73, 'John McMorris', 14, '2001/11/06', 'parzialmente nuvoloso', 'buona', 26, 55, 'SW', 4),
	(78, 'Geremia Lombardo', 15, '2001/09/12', 'vento forte', 'scarsa', 21, 53, 'W', 75),
	(8, 'Seraphim Kovalyov', 1, '2022/06/09', 'avverse', 'visibilità buona', 15, 76, 'N', 13),
	(13, 'Carl Artemiev', 2, '2013/01/31', 'pioggia pesante', 'oltre 10 km', 15, 98, 'NE', 18),
	(83, 'Paladin Goodchild', 16, '2005/01/29', 'sereno', 'buona', 17, 39, 'NW', 6),
	(88, 'Logan Read', 17, '2007/03/11', 'parzialmente nuvoloso', 'ottima', 12, 32, 'S', 8),
	(158,'Jamal Knook',31,'2008/03/15','Tepmorali','scarsa',12,86,'NNO',47),
	(163,'Arthur Andreeff',32,'2007/03/14','Temporali','scarsa',8,90,'N',40),
	(113, 'John Doe', 22, '2002/11/06', 'parzialmente nuvoloso', 'buona', 36, 45, 'SE', 3);


COMMIT;
