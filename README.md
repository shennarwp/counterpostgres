# pgcounter

Kleines Programm zur Demonstration des Redundanz- und Haltbarkeitsaspekts von PostgreSQL.
Es gibt zwei Datenbankinstanzen, nämlich Master-Slave, die beide im Docker-Container deployed werden.
Die Counter-Anwendung versucht, eine Verbindung zum Master herzustellen und schreibt alle 2 Sekunden eine Integer.

Der verwendete PostgreSQL-Replikationsmechanismus ist die Streaming Replication


# Voraussetzung

- [Docker](https://www.docker.com/) ist installiert


# Ausführen

- klone das Repo `git clone https://github.com/shennarwp/pgcounter.git pgcounter/`

- dieses Repo im Intellij öffnen

- erstelle ein Docker-Netzwerk für unsere Datenbankinstanzen: `docker network create counter`

- navigiere zu `postgres/master` und führe folgende Befehle aus:

	- Zum Bauen das Image und erstmaligen Initialisierung der Masterdatenbank:

		`docker-compose -f init_compose.yml build && docker-compose -f init_compose.yml up`

	- **stoppe** und starte nochmal die Instanz neu:

		`ctrl + c`

		`docker-compose build && docker-compose up`

- navigiere zu postgres/slave

	- Zum Bauen das Image und erstmaligen Initialisierung der Slavedatenbank

		`docker-compose build && docker-compose up`

- compile und führe die Klasse `Counter.java` aus

- Schaue die Datenbankinhalte an, (z.B. mit [DBVisualizer](https://www.dbvis.com/))
	mit folgenden Konfigurationen:

	|              | Master      | Slave       |
	|--------------|-------------|-------------|
	| Host         | `localhost` | `localhost` |
	| Port         | `5440`      | `5441`      |
	| User         | `postgres`  | `postgres`  |
	| Password     | `postgres`  | `postgres`  |
	| Databasename | `counter`   | `counter`   |


# Testen des automatischen Failover-Mechanismus

- stoppe eine Instanz mit `ctrl + c`

	- Wird die Slave-Instanz gestoppt, schreibt die Counter-Anwendung weiter in den Master

	- Wenn die Master-Instanz gestoppt wird, erkennt die Slave-Instanz automatisch,
		dass der Master inaktiv ist, und übernimmt die Rolle als neuer Master.
		Die Counter-Anwendung wartet auf die Umschaltungsprozess und schreibt dann in den neuen Master.

- starte die Instanz mit `docker-compose up` im jeweiligen Ordner neu

>Wenn die Master-Instanz gestoppt wird, warte ca. 10s bis dem Umschaltungsprozess abgeschlossen ist
	und dann starte die Instanz neu

- Die neugestarte Instanz übernimmt dann die Rolle als Slave und folgt dem neuen Master

- Es gibt keinen Datenverlust, da die Counter-Anwendung nicht in die Datenbank schreibt,
	wenn keine Master-Instanz vorhanden ist, sondern wartet sie bis dem Umschaltungsprozess abgeschlossen ist.


# Cleanup

lösche alle Container, Images, und Volumen

`docker container rm db_counter_master && docker image rm db_counter_master && docker volume rm master_home`

`docker container rm db_counter_slave && docker image rm db_counter_slave && docker volume rm slave_home`


# TODO

-


# Referenzen

- Die PostgreSQL-Dockerkonfigurationen sind von
[diesem Artikel](https://medium.com/@2hamed/replicating-postgres-inside-docker-the-how-to-3244dc2305be)
und von [diesem Repo](https://github.com/2hamed/docker-pg-replication) basiert und modifiziert.
- PostgreSQL Wiki: [Streaming Replication](https://wiki.postgresql.org/wiki/Streaming_Replication)
- PostgreSQL Streaming Replication [Documentation](https://www.postgresql.org/docs/current/warm-standby.html)
