# Docker med Spring boot, Docker Hub & AWS ECR 

## Læringsmål

Etter denne øvingen skal du kunne:

- Lage et Docker container image av en Spring Boot-applikasjon med en multi-stage Dockerfile
- Publisere container images til Docker Hub og AWS ECR
- Sette opp en GitHub Actions-workflow som automatisk bygger og pusher et image ved hver push til `main`

Repoet inneholder en enkel Spring Boot-applikasjon som svarer «Hello» på context root (`/`).

## AWS-tjenester brukt i labben

- **AWS ECR (Elastic Container Registry)** — AWS sitt registry for container images. Vi laster opp images hit fra både terminal og GitHub Actions.
- **AWS IAM** — brukes til å lage access keys som gir programmatisk tilgang til AWS fra terminalen og fra GitHub Actions.
- **AWS CLI** — kommandolinjeverktøyet vi bruker for å autentisere Docker mot ECR.

Alle AWS-kommandoer i labben bruker region `eu-west-1`.

## Lag en fork og et Codespace

En **fork** er din egen kopi av et GitHub-repo. Når du forker dette repoet, får du en versjon under din egen GitHub-konto som du kan endre, committe og pushe til uten å påvirke originalen. Endringene dine lever i din fork.

I denne labben trenger du en fork fordi du skal legge til en `Dockerfile` og en GitHub Actions-workflow, og pushen din skal trigge en bygg i *ditt* repo — ikke i originalen.

1. Trykk på **Fork** øverst til høyre på GitHub-siden for dette repoet.
2. Åpne din fork og start et Codespace (**Code** → **Codespaces** → **Create codespace on main**).

## Installer AWS CLI i ditt codespace 

```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

`-o` skriver curl-output til fila `awscliv2.zip` i stedet for å printe til terminalen.

## Del 1 - Kom i gang med Docker

Docker er installert i ditt codespace. Verifiser og test

```sh
docker run hello-world
```

Forventet resultat  

```Unable to find image hello-world:latest locally
 Pulling repository hello-world
 91c95931e552: Download complete
 a8219747be10: Download complete
 Status: 
 Downloaded newer image for hello-world:latest
 Hello from Docker.
 This message shows that your installation appears to be working correctly.

 To generate this message, Docker took the following steps:
  1. The Docker Engine CLI client contacted the Docker Engine daemon.
  2. The Docker Engine daemon pulled the "hello-world" image from the Docker Hub.
     (Assuming it was not already locally available.)
  3. The Docker Engine daemon created a new container from that image which runs the
     executable that produces the output you are currently reading.
  4. The Docker Engine daemon streamed that output to the Docker Engine CLI client, which sent it
     to your terminal.

 To try something more ambitious, you can run an Ubuntu container with:
  $ docker run -it ubuntu bash

 For more examples and ideas, visit:
  https://docs.docker.com/userguide/

```

Kjør kommandoen 

```sh
docker images
```
Du vil se at Docker har lastet ned et *hello-world* container image. 
Vi skal nå slette dette, men vi må først fjerne en stoppet container som er basert på dette imaget

Kjør først kommandoen ```docker ps``` for å se hvilke containere som kjører. Du vil få en tom liste

```sh
docker ps
```

Legger du på -a argumentet, vil du også se stoppede containere  

```sh
docker ps -a 
```

Du kan få output som for eksempel 

```sh
CONTAINER ID   IMAGE         COMMAND    CREATED         STATUS                     PORTS     NAMES
5a89931c5af6   hello-world   "/hello"   2 minutes ago   Exited (0) 2 minutes ago             fervent_bell
```

> **Merk: `docker rm` og `docker image rm` er to forskjellige kommandoer.**
>
> Et **image** er malen — et bygget artefakt (som `hello-world`) du kan starte containere fra. Den ligger i lokal cache etter en `docker pull` eller `docker build`.
>
> En **container** er en kjørende (eller stoppet) instans av et image. Hver gang du kjører `docker run`, lages en ny container.
>
> - `docker rm <container id>` sletter en container.
> - `docker image rm <image id>` sletter selve imaget.
>
> Du må slette containerne som bruker et image *før* du kan slette imaget. Det er derfor vi rydder i denne rekkefølgen: først container, så image.

Slett den stoppede containeren med 

```sh
docker rm <container id> - i eksemplet over 5a89931c5af6
```

`docker rm` fjerner bare stoppede containere. For å tvinge sletting av en container som kjører, bruk `-f`:

```
docker rm -f <container id> 
```

Kjør ```docker images``` igjen. Docker-kommandoen `docker image rm` brukes til å slette et container image.
Du kan teste dette med;

```sh
docker image rm <IMAGE ID>
```

## Del 2 - Lage docker image basert på Spring Boot-applikasjon

Først; Sjekk at du kan kjøre Spring Boot applikasjonen med Maven 
```
mvn spring-boot:run
```

* Sjekk at applikasjonen kjører. 
* Åpne en ny terminal i ditt codespace og kjør  
```
curl localhost:8080                                                                                                            
```
Den skal bare svare "Hello" 

Nå skal vi lage en Dockerfile for Spring Boot-applikasjonen. Vi skal bruke en "multi stage" Docker fil, som 
først lager en container som har alle verktøy til å bygge applikasjonen, maven osv.

Spring boot applikasjonen blir kompilert og bygget i denne containeren. Deretter bruker den resultatet fra byggeprosessen, JAR filen til å lage en runtime container for applikasjonen. 

Ta gjerne en pause og les mer om multi stage builds her: https://docs.docker.com/develop/develop-images/multistage-build/

Kopier dette innholdet inn i en ny fil som skal hete  ```Dockerfile``` i rotkatalogen i ditt workspace

```dockerfile

# Build the Maven project using Java 17
FROM maven:3.8-eclipse-temurin-17 as builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn package

# Use a base image with Java 17
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar /app/application.jar
ENTRYPOINT ["java", "-jar", "/app/application.jar"]
```

Prøv å bygge en Docker container

```sh
docker build . --tag <du bestemmer tag eller navn>
```

Prøv å starte en container basert på dette container image.  
```sh
docker run <tag eller navn som brukt over>
```

Når du starter en container, så lytter ikke applikasjonen på port 8080. Hvorfor ikke? Hint: port mapping 

### Oppgave

Kan du starte to versjoner av samme container, hvor en lytter på port 8080 og den andre på 8081?


## Registrer deg på Docker Hub

https://hub.docker.com/signup

### Lag et security token på Docker Hub

Du lager et token ved å trykke på ditt profilbilde (øverst til høyre) - og deretter "Account Settings", Personal Access tokens, og Generate Token. 

* Gi tokenet et navn og read/write/delete permissions.

## Logg inn - Bygg en container og push til Docker Hub 

Login på Docker Hub fra terminalen din. `-u` angir brukernavnet; Docker spør deretter om passord/token.
```
docker login -u <ditt brukernavn på dockerhub>
```

Når du kjørte `docker build` valgte du en `tag` denne trenger du nå...
```
docker tag <tag> <ditt brukernavn på dockerhub>/<tag>
docker push <ditt brukernavn på dockerhub>/<tag>
```

Eksempel:
```
docker login
docker tag fantasticapp glennbech/fantasticapp
docker push glennbech/fantasticapp
```

Gå til dockerhub.com og se på container image du nettopp lastet opp.

## Del imaget med andre

Del gjerne navnet på Docker Hub-imaget ditt med andre, så de kan forsøke å kjøre det med `docker run`. Foreleser sitt image heter for eksempel `glennbech/shaky`.

## Del 3 - Amazon Container Registry ECR

### Konfigurere AWS Access keys 

* Lag aksessnøkler https://github.com/glennbechdevops/aws-iam-accesskeys
* Kjør `aws configure` og oppgi Access Key ID, secret access Key, Region (eu-west-1) og json som filformat
  

### Lag et AWS ECR repository for din container

* Pass på at du er i AWS region eu-west-1
* Du kan lage et ECR repository fra kommandolinjen med `aws ecr ...` eller fra AWS Console. Du velger, men du må finne ut hvordan du gjør det selv. 

### Autentiser docker mot AWS ECR

Du kan gjøre dette ved å kjøre kommandoen (copy/paste denne)
```
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 244530008913.dkr.ecr.eu-west-1.amazonaws.com
```

Denne ser kanskje litt kryptisk ut, dette er hva som skjer steg for steg 

### aws ecr get-login-password --region eu-west-1

Denne delen av kommandoen bruker AWS CLI (aws) til å hente et midlertidig innloggingspassord for ECR (Elastic Container Registry).
get-login-password er en AWS-kommando som returnerer et passord som er nødvendig for å autentisere Docker mot ECR.
--region eu-west-1 spesifiserer hvilken region du vil hente passordet for. I dette tilfellet er regionen eu-west-1 (Vest-Europa, Irland).

### docker login --password-stdin ...

* Symbolet | er en pipe som brukes til å sende output fra den første kommandoen (passordet) som input til den neste kommandoen.
*  docker login --username AWS --password-stdin 244530008913.dkr.ecr.eu-west-1.amazonaws.com er kommandoen for å logge inn på Docker, hvor --username AWS angir at brukernavnet er AWS.
--password-stdin gjør det mulig for Docker å lese passordet fra standard input (stdin), som i dette tilfellet kommer fra den første kommandoen via pipen.
* 244530008913.dkr.ecr.eu-west-1.amazonaws.com er URL-en til ECR-registeret du prøver å logge inn på.
* Dette spesifiserer nøyaktig hvilket ECR-register Docker skal autentisere mot.
    
### Push et container image til ditt ECR repository

Eksempel:
```sh
docker tag <ditt tagnavn> 244530008913.dkr.ecr.eu-west-1.amazonaws.com/<ditt ECR repo navn>
docker push 244530008913.dkr.ecr.eu-west-1.amazonaws.com/<ditt ECR repo navn>
```

Gå til tjenesten ECR i AWS og se at du har fått et container image i ditt registry. NB! Hvis du ikke finner ditt repo — sjekk at du er i riktig region.

## Del 4 - Få GitHub Actions til å bygge & pushe et nytt image ved hver commit på main 


Du må legge til Repository secrets. Gå til Settings/Secrets and variables/Actions. Og legg inn AWS_ACCESS_KEY_ID og AWS_SECRET_ACCESS_KEY.

For å lage en github actions workflow lager du en yml fil, for eksempel docker.yml - under `.github/workflows` katalogen i ditt codespace. Du må lage .github/workflows katalogen.
Her er et eksempel på en workflow tatt fra foreleser sitt miljø. Du må nå gjøre endringer for å tilpasse den til ditt eget repo. 

DU SKAL IKKE LEGGE INN DINE ACCESS KEYS/SECRET ACCESS KEY I FILEN.

```yaml
name: Publish Docker image

on:
  push:
    branches:
      - main

jobs:
  push_to_registry:
    name: Push Docker image to ECR
    runs-on: ubuntu-latest
    steps:
      - name: Check out the repo
        uses: actions/checkout@v4

      - name: Build and push Docker image
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 244530008913.dkr.ecr.eu-west-1.amazonaws.com
          rev=$(git rev-parse --short HEAD)
          docker build . -t hello
          docker tag hello 244530008913.dkr.ecr.eu-west-1.amazonaws.com/glenn:$rev
          docker push 244530008913.dkr.ecr.eu-west-1.amazonaws.com/glenn:$rev
```

Kort om kommandoene i `run`-blokken:
- `git rev-parse --short HEAD` gir en kort commit-hash (7 tegn) som vi bruker som image-tag, slik at hvert bygg får en unik tag.
- `docker build . -t hello` bygger et image fra `Dockerfile` i nåværende katalog. `-t` setter navn/tag på imaget.
- `docker tag` og `docker push` merker imaget med ECR-URL-en og laster det opp.

Commit og push docker.yml filen. Husk også Dockerfile om du ikke allerede har den i ditt repository. Gå til Action tabben i ditt GitHub repository. Se at GitHub lager et nytt container image og laster opp image til ECR. 

## Del 5 - Statussjekker før merge til `main`

Så langt kan hvem som helst merge hva som helst til `main`. Nå skal du kreve at Docker-workflowen fra Del 4 må kjøre grønn før en pull request kan merges.

En **statussjekk** er et krav GitHub håndhever før merge: en navngitt CI-jobb må ha kjørt ferdig og lykkes for at **Merge**-knappen skal bli aktiv. Er sjekken rød eller mangler, blokkeres merge.

### 1. La workflowen kjøre på pull requests

Workflowen fra Del 4 trigger bare på `push` til `main`. For at sjekken skal kjøre på en PR må du legge til `pull_request` som trigger:

```yaml
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
```

Commit og push endringen til `main`, slik at GitHub registrerer at jobben finnes.

### 2. Finn navnet på jobben

Åpne workflow-filen og se etter blokka under `jobs:`. Navnet du trenger er *nøkkelen* under `jobs:`, ikke `name:`-feltet. I eksempelet fra Del 4 heter jobben `push_to_registry`:

```yaml
jobs:
  push_to_registry:      # <-- dette navnet trenger du i steg 3
    name: Push Docker image to ECR
```

### 3. Legg til branch protection på `main`

1. Gå til **Settings** → **Branches** i repoet ditt.
2. Under **Branch protection rules**, klikk **Add rule**.
3. Sett **Branch name pattern** til `main`.
4. Huk av **Require status checks to pass before merging**.
5. I søkefeltet under skriver du navnet på jobben (f.eks. `push_to_registry`) og velger den når den dukker opp.
6. Lagre reglen.

> **Om søkefeltet:** GitHub lister ikke jobber som bare finnes i workflow-filen — jobben må ha kjørt minst én gang i dette repoet for å være valgbar. Er trefflista tom når du søker, har workflowen ikke kjørt ennå. Gå tilbake til steg 1 og pushen som skulle trigge den.

### 4. Test at det fungerer

Lag en PR som skal feile:

1. Lag en ny branch: `git checkout -b test-broken-build`. `-b` oppretter branchen og bytter til den i én kommando.
2. Åpne `Dockerfile` og bytt `FROM eclipse-temurin:17-jre-alpine` til `FROM eclipse-temurin:17-jre-finnes-ikke`.
3. Commit, push branchen, og opprett en PR mot `main`.
4. Se at statussjekken kjører, feiler, og at **Merge pull request**-knappen er blokkert.
5. Rett Dockerfile tilbake til `alpine`, push på nytt, og se at sjekken blir grønn og PR-en kan merges.

## Bonus challenge

* Kan du laste opp image til både AWS ECR, men også Docker Hub fra GitHub Actions workflowen?
* Kan du kjøre Spring boot applikasjonen din på tjenesten AWS Apprunner ? https://docs.aws.amazon.com/apprunner/latest/dg/what-is-apprunner.html
